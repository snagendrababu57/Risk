import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:milk/pages/attendence_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:io';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final DatabaseReference _studentRef = FirebaseDatabase.instance.ref(
    'students',
  );
  final DatabaseReference _attendanceRef = FirebaseDatabase.instance.ref(
    'attendance',
  );

  List<Map<String, dynamic>> _students = [];
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey _globalKey = GlobalKey();

  // New variables for month selection
  String? _selectedMonth;
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    // Set the default selected month to the current month
    _selectedMonth = DateFormat('MMMM').format(DateTime.now());
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

  void _viewAttendance(String studentId, String name) async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _attendanceRef.child(studentId).get();
      if (!snapshot.exists) {
        _showAttendanceDialog(name, []);
      } else {
        final attendanceData =
            (snapshot.value as Map).entries.map((entry) {
              return {
                "date": entry.key.toString(),
                "status": entry.value.toString(),
              };
            }).toList();

        // Filter attendance data by selected month
        if (_selectedMonth != null) {
          attendanceData.retainWhere((entry) {
            DateTime date = DateFormat("yyyy-MM-dd").parse(entry["date"]!);
            return DateFormat('MMMM').format(date) == _selectedMonth;
          });
        }

        attendanceData.sort((a, b) {
          DateTime dateA = DateFormat("yyyy-MM-dd").parse(a["date"]!);
          DateTime dateB = DateFormat("yyyy-MM-dd").parse(b["date"]!);
          return dateA.compareTo(dateB);
        });

        _showAttendanceDialog(name, attendanceData);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching attendance: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAttendanceDialog(
    String name,
    List<Map<String, String>> attendance,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Attendance"),
            content: Container(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child:
                        attendance.isEmpty
                            ? const Text("No attendance data available.")
                            : Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  attendance.map((entry) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry["date"]!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          entry["status"]!,
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
              TextButton(
                onPressed: () async {
                  await _sendAttendanceDataAsImage(name);
                  Navigator.pop(context);
                },
                child: const Text("Send as Image"),
              ),
            ],
          ),
    );
  }

  Future<void> _sendAttendanceDataAsImage(String studentName) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (_globalKey.currentContext == null) {
        throw Exception("Global key context is null.");
      }

      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception("Failed to convert image to byte data.");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final String imagePath = '${directory.path}/attendance.png';
      final File imgFile = File(imagePath);
      await imgFile.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(imagePath),
      ], text: "Attendance data for $studentName");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attendance data sent for $studentName")),
      );
    } catch (e) {
      print("Error in _sendAttendanceDataAsImage: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error generating image: $e")));
    }
  }

  void _editStudentName(String studentId, String currentName) {
    _nameController.text = currentName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Student Name"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "New Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  _updateStudentName(studentId, newName);
                  Navigator.pop(context);
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _editAttendance(String studentId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AttendancePage(studentId: studentId, studentName: name),
      ),
    );
  }

  void _updateStudentName(String studentId, String newName) async {
    try {
      await _studentRef.child(studentId).update({'name': newName});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student name updated successfully!")),
      );
      _fetchAllStudents(); // Refresh the list after updating
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating student name: $e")),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students List'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
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
                        filled: true,
                        fillColor: Colors.white,
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
                ],
              ),
            ),
            // Dropdown for month selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Text("Select Month:"),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedMonth,
                    hint: const Text("Month"),
                    items:
                        _months.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    },
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                                      Icons.view_list,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'View Attendance',
                                    onPressed:
                                        () => _viewAttendance(
                                          student['id'],
                                          student['name'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Edit Attendance',
                                    onPressed:
                                        () => _editAttendance(
                                          student['id'],
                                          student['name'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Edit Student Name',
                                    onPressed:
                                        () => _editStudentName(
                                          student['id'],
                                          student['name'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Delete Student',
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
      ),
    );
  }
}
