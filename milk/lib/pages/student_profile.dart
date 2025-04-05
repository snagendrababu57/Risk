import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentProfilePage extends StatefulWidget {
  final String admissionNumber;

  const StudentProfilePage({super.key, required this.admissionNumber});

  @override
  // ignore: library_private_types_in_public_api
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Map<String, dynamic>? studentData;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      DatabaseReference dbRef = FirebaseDatabase.instance.ref(
        'students/${widget.admissionNumber}',
      );
      DataSnapshot snapshot = await dbRef.get();

      if (snapshot.exists) {
        setState(() {
          studentData = Map<String, dynamic>.from(
            snapshot.value as Map<dynamic, dynamic>,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student data not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child:
            studentData == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 16),
                      const Text(
                        'Attendance Pie Chart:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _getAttendanceChartData(),
                            centerSpaceRadius: 50,
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      shadowColor: Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image with border and shadow
            if (studentData?['profileImage'] != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.network(
                      studentData!['profileImage'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Name
            Text(
              'Name: ${studentData!['name']}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 12),
            // Class & Section
            Text(
              'Class: ${studentData!['class']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Section: ${studentData!['section']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 12),
            // Admission Number & Email
            Text(
              'Admission Number: ${studentData!['admissionNumber']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${studentData!['email']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Attendance
            Text(
              'Attendance: ${studentData!['attendance']}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 12),
            // Parent's Name
            Text(
              'Father\'s Name: ${studentData!['fatherName']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Mother\'s Name: ${studentData!['motherName']}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getAttendanceChartData() {
    double attendance =
        double.tryParse(studentData?['attendance']?.toString() ?? '0') ?? 0.0;
    double absent = 100 - attendance;

    return [
      PieChartSectionData(
        value: attendance,
        color: Colors.greenAccent[400],
        title: '${attendance.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 60,
      ),
      PieChartSectionData(
        value: absent,
        color: Colors.redAccent[400],
        title: '${absent.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 60,
      ),
    ];
  }
}
