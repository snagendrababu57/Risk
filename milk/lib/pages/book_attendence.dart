import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AttendancePage1 extends StatefulWidget {
  final String customerId;
  final String customerName;

  const AttendancePage1({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage1> {
  final List<String> _statusOptions = List.generate(
    21,
    (index) => (index * 0.5).toString(),
  );

  late final List<String> _days;
  final Map<String, String> _attendanceData = {};
  final DatabaseReference _database = FirebaseDatabase.instance.ref("booklets");

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    _days = List.generate(daysInMonth, (index) => (index + 1).toString());
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    print("Fetching data for customer: ${widget.customerId}");
    DatabaseEvent event = await _database.child(widget.customerId).once();

    Map<String, String> tempAttendanceData = {}; // Temporary storage

    if (event.snapshot.value != null) {
      print("Raw Data from Firebase: ${event.snapshot.value}");

      if (event.snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> data = Map.from(event.snapshot.value as Map);

        data.forEach((key, value) {
          print("Loading attendance: $key -> $value");

          String formattedValue =
              double.parse(value.toString()).toString(); // Normalize values
          if (formattedValue.endsWith(".0")) {
            formattedValue = formattedValue.replaceAll(".0", "");
          }

          tempAttendanceData[key] = formattedValue;
        });
      }
    }

    // Ensure all days in the current month are accounted for
    if (mounted) {
      setState(() {
        for (String day in _days) {
          String fullDate =
              DateFormat('yyyy-MM-').format(DateTime.now()) +
              day.padLeft(2, '0');

          // If the date exists in Firebase data, use it; otherwise, default to "0"
          _attendanceData[fullDate] = tempAttendanceData[fullDate] ?? "0";
        }
      });
    }

    print("Final Attendance Data: $_attendanceData");
  }

  Future<void> _submitAttendance(String day) async {
    String fullDate =
        DateFormat('yyyy-MM-').format(DateTime.now()) + day.padLeft(2, '0');

    // Create a new entry under "booklets" for each attendance record
    await _database
        .child(widget.customerId)
        .child(fullDate)
        .set(_attendanceData[fullDate]);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Attendance saved for ${widget.customerName} on $fullDate",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance for ${widget.customerName}')),
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
                  String fullDate =
                      DateFormat('yyyy-MM-').format(DateTime.now()) +
                      day.padLeft(2, '0');

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            fullDate,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value:
                                _attendanceData[fullDate] ??
                                "0", // Use the fetched data
                            isExpanded: true,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _attendanceData[fullDate] =
                                      newValue; // Update the attendance data
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
                                    value: displayText,
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
    );
  }
}
