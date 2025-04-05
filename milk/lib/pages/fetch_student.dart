import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FetchAttendancePage extends StatefulWidget {
  const FetchAttendancePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FetchAttendancePageState createState() => _FetchAttendancePageState();
}

class _FetchAttendancePageState extends State<FetchAttendancePage> {
  late final DatabaseReference _database;
  final List<Map<String, String>> _attendanceList = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instance.ref().child('attendance');
    _fetchAllAttendance();
  }

  void _fetchAllAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _attendanceList.clear();
    });

    try {
      final snapshot = await _database.get();

      if (snapshot.value == null || snapshot.value is! Map<dynamic, dynamic>) {
        setState(() {
          _errorMessage = 'No attendance records found.';
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      Map<String, double> consolidatedData = {};

      data.forEach((name, records) {
        if (records is Map<dynamic, dynamic>) {
          double totalLiters = 0;
          records.forEach((date, liters) {
            totalLiters += _parseLiters(liters.toString());
          });
          consolidatedData[name.toString()] = totalLiters;
        }
      });

      int serialNumber = 1;
      consolidatedData.forEach((name, totalLiters) {
        _attendanceList.add({
          'S.No': serialNumber.toString(),
          'Name': name,
          'Total Liters': totalLiters.toStringAsFixed(2),
        });
        serialNumber++;
      });

      // Sort the attendance list alphabetically by name
      _attendanceList.sort((a, b) => a['Name']!.compareTo(b['Name']!));

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error fetching attendance: $error';
        _isLoading = false;
      });
    }
  }

  double _parseLiters(String value) {
    try {
      double total = 0.0;
      List<String> parts = value.split(RegExp(r'[\s\+\-]'));
      for (String part in parts) {
        if (part.contains('/')) {
          var fraction = part.split('/');
          total += double.parse(fraction[0]) / double.parse(fraction[1]);
        } else {
          total += double.parse(part);
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _saveAsExcel() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to select a directory')),
        );
        return;
      }

      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheet = excel['Attendance Records'];

      // Convert headers to TextCellValue
      sheet.appendRow([
        excel_lib.TextCellValue('S.No'),
        excel_lib.TextCellValue('Name'),
        excel_lib.TextCellValue('Total Liters'),
      ]);

      for (var record in _attendanceList) {
        sheet.appendRow([
          excel_lib.TextCellValue(record['S.No'] ?? ''),
          excel_lib.TextCellValue(record['Name'] ?? ''),
          excel_lib.TextCellValue(record['Total Liters'] ?? ''),
        ]);
      }

      List<int>? excelBytes = excel.encode();
      final filePath = '$result/attendance_records.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excelBytes!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel saved to: $filePath')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating Excel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Records')),
      body: Container(
        color: const Color.fromARGB(255, 198, 54, 54), // Set background color
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('S.No')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Total Liters')),
                            ],
                            rows:
                                _attendanceList
                                    .map(
                                      (record) => DataRow(
                                        cells: [
                                          DataCell(Text(record['S.No']!)),
                                          DataCell(Text(record['Name']!)),
                                          DataCell(
                                            Text(record['Total Liters']!),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveAsExcel,
                      child: const Text('Save as Excel'),
                    ),
                  ],
                ),
      ),
    );
  }
}
