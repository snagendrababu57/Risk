import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Controllers for form fields
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentPhoneController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();

  Future<void> submitStudentData() async {
    if (studentNameController.text.isEmpty ||
        studentPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the student fields!')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User  not authenticated!')));
      return;
    }

    try {
      final studentData = {
        'name': studentNameController.text,
        'phone': studentPhoneController.text,
        'addedBy': user.uid,
      };

      await _database
          .child('students')
          .child(studentNameController.text)
          .set(studentData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully!')),
      );

      studentNameController.clear();
      studentPhoneController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add student: $e')));
    }
  }

  Future<void> submitCustomerData() async {
    if (customerNameController.text.isEmpty ||
        customerPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the customer fields!')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User  not authenticated!')));
      return;
    }

    try {
      final customerData = {
        'name': customerNameController.text,
        'phone': customerPhoneController.text,
        'addedBy': user.uid,
      };

      await _database
          .child('customers')
          .child(customerNameController.text)
          .set(customerData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully!')),
      );

      customerNameController.clear();
      customerPhoneController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add customer: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Add Monthly and Book'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Section
              const Text('Add Monthly', style: TextStyle(fontSize: 20)),
              TextField(
                controller: studentNameController,
                decoration: const InputDecoration(labelText: ' Name'),
              ),
              TextField(
                controller: studentPhoneController,
                decoration: const InputDecoration(labelText: ' Phone Number'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitStudentData,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Submit'),
              ),

              const SizedBox(height: 40),

              // Customer Section
              const Text('Add Book', style: TextStyle(fontSize: 20)),
              TextField(
                controller: customerNameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              TextField(
                controller: customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Customer Phone Number',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitCustomerData,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Submit Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
