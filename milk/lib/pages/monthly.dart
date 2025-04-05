import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class UsersAttendancePage extends StatefulWidget {
  const UsersAttendancePage({super.key});

  @override
  _UsersAttendancePageState createState() => _UsersAttendancePageState();
}

class _UsersAttendancePageState extends State<UsersAttendancePage>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool isLoading = false;
  List<Map<String, dynamic>> usersData = [];
  List<String> userNames = []; // To store unique user names
  Map<String, Map<String, String>> dateWiseAttendance =
      {}; // Date-wise data for all users
  late AnimationController _controller;
  late Animation<double> _animation;

  // Month and Year selection
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward(); // Start the animation immediately

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _fetchUsersData(selectedMonth, selectedYear);
  }

  void _fetchUsersData(int month, int year) async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await _database.child('attendance').get();

      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> fetchedData = [];
        Set<String> namesSet = {}; // To collect unique names
        Map<String, Map<String, String>> tempDateWiseAttendance = {};

        // Generate all dates for the selected month
        List<DateTime> allDatesInMonth = [];
        DateTime firstDayOfMonth = DateTime(year, month, 1);
        DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
        for (
          DateTime date = firstDayOfMonth;
          date.isBefore(lastDayOfMonth.add(Duration(days: 1)));
          date = date.add(Duration(days: 1))
        ) {
          allDatesInMonth.add(date);
        }

        data.forEach((name, records) {
          if (records is Map<dynamic, dynamic>) {
            namesSet.add(name); // Add the name to the set of unique names

            // Process each date for the user
            records.forEach((date, liters) {
              // Parse the date and check if it belongs to the selected month and year
              DateTime parsedDate = DateTime.parse(date);
              if (parsedDate.year == year && parsedDate.month == month) {
                double parsedLiters = _convertFractionToDouble(
                  liters.toString(),
                );
                String formattedDate = DateFormat(
                  'dd-MM-yyyy',
                ).format(parsedDate);

                // Initialize the date entry if not present
                if (!tempDateWiseAttendance.containsKey(formattedDate)) {
                  tempDateWiseAttendance[formattedDate] = {};
                }

                // Add the liters for this user on this date
                tempDateWiseAttendance[formattedDate]![name] = parsedLiters
                    .toStringAsFixed(2);
              }
            });
          }
        });

        // Convert the set of names to a sorted list
        userNames = namesSet.toList()..sort();

        // Prepare the usersData for display
        int sno = 1;
        for (var date in allDatesInMonth) {
          String formattedDate = DateFormat('dd-MM-yyyy').format(date);
          // Initialize user liters for this date
          Map<String, String> userLiters = {};
          for (var name in userNames) {
            userLiters[name] =
                tempDateWiseAttendance[formattedDate]?[name] ?? '0.00';
          }
          fetchedData.add({
            'sno': sno++,
            'date': formattedDate,
            'userLiters': userLiters,
          });
        }

        setState(() {
          usersData = fetchedData;
          dateWiseAttendance = tempDateWiseAttendance;
        });
      }
    } catch (error) {
      _showSnackBar('Error fetching data: $error');
    }

    setState(() {
      isLoading = false;
    });
  }

  double _convertFractionToDouble(String input) {
    try {
      if (input.contains('/')) {
        final parts = input.split('/');
        if (parts.length == 2) {
          double numerator = double.tryParse(parts[0]) ?? 0.0;
          double denominator = double.tryParse(parts[1]) ?? 1.0;
          return numerator / denominator;
        }
      }
      return double.tryParse(input) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _exportToExcel() async {
    var excel = excel_lib.Excel.createExcel();
    excel_lib.Sheet sheetObject = excel['Attendance'];

    // Adding Headers
    List<excel_lib.TextCellValue> headerRow = [excel_lib.TextCellValue('Date')];
    for (var name in userNames) {
      headerRow.add(excel_lib.TextCellValue(name));
    }
    sheetObject.appendRow(headerRow);

    // Adding Data
    // Sort dates to ensure chronological order
    List<String> sortedDates =
        dateWiseAttendance.keys.toList()..sort(
          (a, b) => DateFormat(
            'dd-MM-yyyy',
          ).parse(a).compareTo(DateFormat('dd-MM-yyyy').parse(b)),
        );

    for (var date in sortedDates) {
      List<excel_lib.TextCellValue> row = [excel_lib.TextCellValue(date)];

      // Add liters for each user on this date
      for (var name in userNames) {
        String liters = dateWiseAttendance[date]![name] ?? '0.00';
        row.add(excel_lib.TextCellValue(liters));
      }

      sheetObject.appendRow(row);
    }

    // Save the Excel file
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      _showSnackBar("File selection canceled.");
      return;
    }

    String filePath = "$selectedDirectory/UsersAttendance.xlsx";
    File file = File(filePath);

    var fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      _showSnackBar("Excel file saved: $filePath");
    } else {
      _showSnackBar("Failed to generate Excel file.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animation,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal, // Enable horizontal scrolling
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Selection Dropdown
                          Row(
                            children: [
                              const Text('Select Month: '),
                              DropdownButton<int>(
                                value: selectedMonth,
                                items: List.generate(12, (index) {
                                  return DropdownMenuItem<int>(
                                    value: index + 1,
                                    child: Text(
                                      DateFormat(
                                        'MMMM',
                                      ).format(DateTime(0, index + 1)),
                                    ),
                                  );
                                }),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedMonth = value;
                                      _fetchUsersData(
                                        selectedMonth,
                                        selectedYear,
                                      );
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 20),
                              const Text('Select Year: '),
                              DropdownButton<int>(
                                value: selectedYear,
                                items: List.generate(5, (index) {
                                  int year = DateTime.now().year - index;
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedYear = value;
                                      _fetchUsersData(
                                        selectedMonth,
                                        selectedYear,
                                      );
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Table Header
                          Container(
                            color: Colors.blueAccent.withOpacity(0.1),
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...userNames.map((name) {
                                  return SizedBox(
                                    width: 100,
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const Divider(height: 2),

                          // Data Table
                          usersData.isEmpty
                              ? const Center(child: Text("No Data Available"))
                              : Column(
                                children:
                                    usersData.map((entry) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 100,
                                              child: Text(entry['date']),
                                            ),
                                            ...userNames.map((name) {
                                              String liters =
                                                  entry['userLiters'][name] ??
                                                  '0.00';
                                              return SizedBox(
                                                width: 100,
                                                child: Text(liters),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),

                          // Total Row
                          const Divider(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...userNames.map((name) {
                                  double totalLiters = usersData.fold(0.0, (
                                    sum,
                                    entry,
                                  ) {
                                    String liters =
                                        entry['userLiters'][name] ?? '0.00';
                                    return sum + double.parse(liters);
                                  });
                                  return SizedBox(
                                    width: 100,
                                    child: Text(totalLiters.toStringAsFixed(2)),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
