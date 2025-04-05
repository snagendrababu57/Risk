import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Changed to name

  String _selectedRole = 'student'; // Default to student
  final List<String> _roles = ['admin', 'student'];

  Future<void> register() async {
    try {
      String input = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String role = _selectedRole;

      if (role == 'student') {
        String name =
            _nameController.text
                .trim(); // Using name instead of admission number

        // Check if name exists in the students database
        DatabaseReference studentsRef = FirebaseDatabase.instance.ref(
          'students/$name',
        );
        DataSnapshot snapshot = await studentsRef.get();

        if (!snapshot.exists) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Name $name not found!')));
          return;
        }

        String email = '$name@school.com';

        // Check if email already exists in Firebase Authentication
        List<String> methods = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student with this name is already registered!'),
            ),
          );
          return;
        }

        // Register student
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Save student data to the users node
        DatabaseReference usersRef = FirebaseDatabase.instance.ref(
          'users/${userCredential.user!.uid}',
        );
        await usersRef.set({
          'role': 'student',
          'name': name, // Save the name
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student with name $name registered successfully!'),
          ),
        );
        Navigator.pop(context);
      } else if (role == 'admin' || role == 'teacher') {
        // Register admin/teacher using email
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: input, password: password);

        // Save admin/teacher data to the users node
        DatabaseReference usersRef = FirebaseDatabase.instance.ref(
          'users/${userCredential.user!.uid}',
        );
        await usersRef.set({'role': role, 'email': input});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$role registered successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid role!')));
      }
    } catch (e) {
      String error = 'An error occurred.';
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          error = 'Email is already in use!';
        } else if (e.code == 'weak-password') {
          error = 'The password provided is too weak.';
        } else if (e.code == 'invalid-email') {
          error = 'The email address is invalid.';
        }
      } else {
        error = 'Error: $e';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedRole,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
              items:
                  _roles.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            if (_selectedRole == 'student') ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ), // Changed label to Name
              ),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: const Text('Register')),
          ],
        ),
      ),
    );
  }
}
