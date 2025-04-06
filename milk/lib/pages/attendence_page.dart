import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const AttendancePage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final List<String> _statusOptions =
      ["(A)"] + List.generate(21, (index) => (index * 0.5).toString());
  late List<String> _days;
  final Map<String, String> _attendanceData = {};
  final DatabaseReference _database = FirebaseDatabase.instance.ref(
    "attendance",
  );
  final List<String> _months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];
  int _selectedMonth = DateTime.now().month - 1; // 0-based index for months
  bool _hasUnsavedChanges = false; // Track unsaved changes

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    DateTime now = DateTime.now();
    int daysInMonth =
        DateTime(
          now.year,
          _selectedMonth + 2,
          0,
        ).day; // +2 because month is 0-based
    _days = List.generate(daysInMonth, (index) => (index + 1).toString());

    if (kDebugMode) {
      print("Fetching data for student: ${widget.studentId}");
    }
    DatabaseEvent event = await _database.child(widget.studentId).once();

    if (event.snapshot.value != null) {
      if (kDebugMode) {
        print("Raw Data from Firebase: ${event.snapshot.value}");
      }

      if (event.snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> data = Map.from(event.snapshot.value as Map);

        setState(() {
          _attendanceData.clear();
          data.forEach((key, value) {
            if (kDebugMode) {
              print("Loading attendance: $key -> $value");
            }
            _attendanceData[key.toString()] =
                value.toString(); // Store the raw value
          });
        });
      }
    } else {
      if (kDebugMode) {
        print("No data found for student: ${widget.studentId}");
      }
    }

    // Ensure default values
    if (mounted) {
      setState(() {
        for (String day in _days) {
          String fullDate =
              DateFormat(
                'yyyy-MM-',
              ).format(DateTime(now.year, _selectedMonth + 1)) +
              day.padLeft(2, '0');
          _attendanceData.putIfAbsent(fullDate, () => "0");
        }
      });
    }

    if (kDebugMode) {
      print("Final Attendance Data: $_attendanceData");
    }
  }

  Future<void> _submitAttendance(String day) async {
    DateTime now = DateTime.now();
    String fullDate =
        DateFormat('yyyy-MM-').format(DateTime(now.year, _selectedMonth + 1)) +
        day.padLeft(2, '0');

    // Check if the attendance value is "0" or not selected
    String? attendanceValue = _attendanceData[fullDate];
    if (attendanceValue == null || attendanceValue == "0") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a valid attendance value for ${widget.studentName} on $fullDate.",
          ),
        ),
      );
      return; // Exit the function without saving
    }

    // Check if yesterday's attendance has been saved
    String yesterdayDate =
        DateFormat('yyyy-MM-').format(DateTime(now.year, _selectedMonth + 1)) +
        (now.day - 1).toString().padLeft(2, '0');
    if (_attendanceData[yesterdayDate] == "0") {
      _showYesterdayAttendanceDialog(yesterdayDate);
      return; // Exit the function without saving
    }

    // Save the attendance data
    await _database
        .child(widget.studentId)
        .update({fullDate: attendanceValue})
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Attendance saved for ${widget.studentName} on $fullDate",
              ),
            ),
          );
          setState(() {
            _hasUnsavedChanges = false; // Reset unsaved changes
          });
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save attendance: $error")),
          );
        });
  }

  void _showYesterdayAttendanceDialog(String yesterdayDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Attendance Not Saved'),
          content: Text(
            "Please save attendance for yesterday ($yesterdayDate) before saving today's attendance.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _onMonthChanged(String? newMonth) {
    if (newMonth != null) {
      setState(() {
        _selectedMonth = _months.indexOf(newMonth);
        _loadAttendanceData(); // Reload data for the selected month
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      return (await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Unsaved Changes'),
                  content: const Text(
                    'You have unsaved changes. Do you want to discard them?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).pop(false), // Stay on the page
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed:
                          () =>
                              Navigator.of(context).pop(true), // Leave the page
                      child: const Text('Discard'),
                    ),
                  ],
                ),
          )) ??
          false; // Default to false if dialog is dismissed
    }
    return true; // Allow navigation if no unsaved changes
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attendance'),
          actions: [
            DropdownButton<String>(
              value: _months[_selectedMonth],
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: _onMonthChanged,
              items:
                  _months.map<DropdownMenuItem<String>>((String month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    String day = _days[index];
                    String selectedFullDate =
                        DateFormat('yyyy-MM-').format(
                          DateTime(DateTime.now().year, _selectedMonth + 1),
                        ) +
                        day.padLeft(2, '0');

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              selectedFullDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value:
                                  _attendanceData[selectedFullDate] ??
                                  "0", // Default to "0" if not found
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _attendanceData[selectedFullDate] =
                                        newValue;
                                    _hasUnsavedChanges =
                                        true; // Mark as unsaved
                                  });
                                }
                              },
                              items:
                                  _statusOptions.map<DropdownMenuItem<String>>((
                                    String status,
                                  ) {
                                    String displayText =
                                        status.endsWith(".0")
                                            ? status.replaceAll(".0", "")
                                            : status;
                                    return DropdownMenuItem<String>(
                                      value:
                                          displayText, // Ensure this matches the expected format
                                      child: Text(displayText),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _submitAttendance(day),
                              child: const Text('Save'),
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
      ),
    );
  }
}
