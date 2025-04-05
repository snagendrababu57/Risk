import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DeletePage extends StatefulWidget {
  const DeletePage({super.key});

  @override
  _DeletePageState createState() => _DeletePageState();
}

class _DeletePageState extends State<DeletePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref(
    "attendance",
  );
  final TextEditingController _studentIdController = TextEditingController();

  // List of months
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

  // Selected month index
  int _selectedMonthIndex = 2; // Default to March (index 2)

  @override
  void initState() {
    super.initState();
  }

  Future<void> _deleteDataForAllStudents() async {
    // Fetch all student names
    DatabaseEvent event = await _database.once();
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> studentsData = Map.from(
        event.snapshot.value as Map,
      );

      // Iterate through each student
      for (var studentId in studentsData.keys) {
        // Construct the keys for the selected month
        for (int day = 1; day <= 31; day++) {
          String fullDate =
              '2025-${_selectedMonthIndex + 1}-${day.toString().padLeft(2, '0')}';
          try {
            print(
              "Attempting to delete attendance for $fullDate for student $studentId",
            );
            await _database.child(studentId).child(fullDate).remove();
            print("Deleted attendance for $fullDate for student $studentId");
          } catch (e) {
            print(
              "Error deleting attendance for $fullDate for student $studentId: $e",
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error: $e")));
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "All attendance data for the selected month has been deleted for all students.",
          ),
        ),
      );
    } else {
      print("No student data found.");
    }
  }

  Future<void> _deleteDataForSingleStudent(String studentId) async {
    // Construct the keys for the selected month
    for (int day = 1; day <= 31; day++) {
      String fullDate =
          '2025-${_selectedMonthIndex + 1}-${day.toString().padLeft(2, '0')}';
      try {
        print(
          "Attempting to delete attendance for $fullDate for student $studentId",
        );
        await _database.child(studentId).child(fullDate).remove();
        print("Deleted attendance for $fullDate for student $studentId");
      } catch (e) {
        print(
          "Error deleting attendance for $fullDate for student $studentId: $e",
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Attendance data for the selected month has been deleted for student $studentId.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed:
                _deleteDataForAllStudents, // Call the delete method for all students
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Attendance Management System"),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _months[_selectedMonthIndex],
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMonthIndex = _months.indexOf(newValue);
                  });
                }
              },
              items:
                  _months.map<DropdownMenuItem<String>>((String month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller:
                  _studentIdController, // Use the controller for the unique ID
              decoration: const InputDecoration(
                labelText:
                    "Enter Student Name", // Change label to reflect the unique ID
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus(); // Hide the keyboard
                String studentId = _studentIdController.text.trim();
                if (studentId.isNotEmpty) {
                  _deleteDataForSingleStudent(studentId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid Student Name."),
                    ),
                  );
                }
              },
              child: const Text("Delete Data for Single Student"),
            ),
          ],
        ),
      ),
    );
  }
}
