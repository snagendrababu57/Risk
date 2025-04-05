import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class StudentListPage1 extends StatefulWidget {
  const StudentListPage1({super.key});

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage1> {
  final DatabaseReference _studentRef = FirebaseDatabase.instance.ref(
    'students',
  );
  final DatabaseReference _attendanceRef = FirebaseDatabase.instance.ref(
    'attendance',
  );

  List<Map<String, dynamic>> _students = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();

  // Updated status options to include "(A)" at the top
  final List<String> _statusOptions =
      ["(A)"] + List.generate(18, (index) => (index / 2).toString());
  String _selectedStatus = "(A)"; // Set a valid default value

  bool _isLoading = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _fetchAllStudents();
  }

  void _fetchAllStudents({String query = ""}) async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _studentRef.get();
      if (!snapshot.exists) {
        setState(() {
          _students = [];
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.value as Map;
      List<Map<String, dynamic>> loadedStudents = [];

      data.forEach((key, studentData) {
        final studentName = studentData['name'] ?? 'No Name';
        if (query.isEmpty ||
            studentName.toLowerCase().contains(query.toLowerCase())) {
          loadedStudents.add({
            "id": key,
            "name": studentName,
            "mobile": studentData['phone'] ?? 'No Mobile',
          });
        }
      });

      loadedStudents.sort((a, b) => a["name"].compareTo(b["name"]));

      setState(() {
        _students = loadedStudents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching students: $e")));
    }
  }

  void _submitAttendance(
    String studentId,
    String studentName,
    String day,
    String status,
  ) async {
    // Check if yesterday's attendance has been saved
    String yesterdayDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.parse(day).subtract(Duration(days: 1)));
    DatabaseEvent yesterdayAttendanceEvent =
        await _attendanceRef.child(studentId).child(yesterdayDate).once();

    if (yesterdayAttendanceEvent.snapshot.value == null) {
      // Show a dialog if yesterday's attendance is not saved
      _showYesterdayAttendanceDialog(yesterdayDate);
      return; // Exit the function without saving
    }

    try {
      await _attendanceRef.child(studentId).update({day: status});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating attendance: $e")));
    }
  }

  void _showYesterdayAttendanceDialog(String yesterdayDate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Attendance Not Saved'),
          content: Text(
            "Please save attendance for yesterday ($yesterdayDate) before saving today's attendance.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _editAttendance(String studentId, String name) {
    String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dayController.text = selectedDate;

    String localSelectedStatus =
        _statusOptions.contains(_selectedStatus)
            ? _selectedStatus
            : _statusOptions.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit Attendance for $name"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _dayController,
                    decoration: const InputDecoration(
                      labelText: "Select Date (yyyy-MM-dd)",
                      hintText: "Today's Date",
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: localSelectedStatus,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          localSelectedStatus = newValue;
                        });
                      }
                    },
                    items:
                        _statusOptions.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final day = _dayController.text.trim();
                    if (day.isNotEmpty && localSelectedStatus.isNotEmpty) {
                      _submitAttendance(
                        studentId,
                        name,
                        day,
                        localSelectedStatus,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteStudent(String studentId) async {
    try {
      await _studentRef.child(studentId).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student deleted successfully!")),
      );
      _fetchAllStudents(); // Refresh the list after deletion
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting student: $e")));
    }
  }

  void _startListening() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize();
        if (available) {
          setState(() {
            _isListening = true;
          });
          _speech.listen(
            onResult: (result) {
              setState(() {
                _nameController.text = result.recognizedWords;
                // Automatically fetch students based on recognized words
                _fetchAllStudents(query: result.recognizedWords);
              });
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Speech recognition initialization failed"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing speech recognition: $e")),
        );
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Search by Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    _fetchAllStudents(query: name);
                  },
                  child: const Text('Search'),
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: _isListening ? _stopListening : _startListening,
                  tooltip: _isListening ? 'Stop Listening' : 'Start Listening',
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _students.isEmpty
                    ? const Center(child: Text('No students found'))
                    : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          elevation: 4,
                          child: ListTile(
                            title: Text(
                              student['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Mobile: ${student['mobile']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed:
                                      () => _editAttendance(
                                        student['id'],
                                        student['name'],
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _deleteStudent(student['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
