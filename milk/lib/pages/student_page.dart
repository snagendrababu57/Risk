import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:milk/pages/student_profile.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedBottomNavIndex = 0;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Map<String, dynamic>? feeDetails; // To store fetched fee details
  String admissionNumber = '';

  final List<Map<String, dynamic>> menuItems = [
    {'label': 'Dashboard', 'icon': Icons.home},
    {'label': 'Profile', 'icon': Icons.account_circle},
    {'label': 'Timetable', 'icon': Icons.event},
    {'label': 'Homework', 'icon': Icons.assignment},
  ];

  final List<Map<String, dynamic>> feeSubMenuItems = [
    {'label': 'Paid Fee', 'icon': Icons.attach_money},
    {'label': 'Remaining Fee', 'icon': Icons.money_off},
    {'label': 'Total Fee', 'icon': Icons.account_balance_wallet},
  ];

  @override
  void initState() {
    super.initState();
    _fetchFeeDetails();
  }

  Future<void> _fetchFeeDetails() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Extract admission number from the email
        String email = currentUser.email!;
        admissionNumber = email.split('@').first;

        // Fetch fee details from Firebase
        DatabaseReference feeRef = _database
            .child('fees')
            .child(admissionNumber);
        DataSnapshot snapshot = await feeRef.get();

        if (snapshot.exists) {
          setState(() {
            feeDetails = Map<String, dynamic>.from(snapshot.value as Map);
          });
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No fee details found')));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching fee details: $e')));
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });
  }

  Future<void> _navigateToProfile() async {
    try {
      if (admissionNumber.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    StudentProfilePage(admissionNumber: admissionNumber),
          ),
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
      appBar: AppBar(title: const Text("Student Dashboard")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Student Dashboard",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ...menuItems.map((item) {
              return ListTile(
                leading: Icon(item['icon']),
                title: Text(item['label']),
                onTap: item['label'] == 'Profile' ? _navigateToProfile : null,
              );
            }),
            ExpansionTile(
              title: const Text("Fee Management"),
              leading: const Icon(Icons.money),
              children:
                  feeSubMenuItems.map((item) {
                    return ListTile(
                      leading: Icon(item['icon']),
                      title: Text(item['label']),
                      onTap: () {},
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Academics",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        menuItems[index]['icon'],
                        size: 40,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      Text(menuItems[index]['label']),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "Fee Management",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (feeDetails != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Admission Number: $admissionNumber"),
                      Text("Fee Amount: ${feeDetails!['feeAmount']}"),
                      Text("Due Date: ${feeDetails!['dueDate']}"),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Payment Process Coming Soon!"),
                            ),
                          );
                        },
                        child: const Text("Pay Now"),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text("Loading fee details..."),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: "Logout",
          ),
        ],
      ),
    );
  }
}
