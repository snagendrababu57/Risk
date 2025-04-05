import 'package:flutter/material.dart';
import 'package:milk/pages/add_students.dart';
import 'package:milk/pages/addfee_page.dart';
import 'package:milk/pages/book_icon.dart';
import 'package:milk/pages/daily_amount.dart';
import 'package:milk/pages/daily_page.dart';
import 'package:milk/pages/delete_data.dart';
import 'package:milk/pages/fetch_student.dart';
import 'package:milk/pages/gps.dart';
import 'package:milk/pages/monthly.dart';
import 'package:milk/pages/student_list_page.dart';
import 'package:milk/screens/login_age.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward(); // Start the animation immediately

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/admin.jpg'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Arvind',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'admin@example.com',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.blue),
              title: const Text('Home'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Attendance'),
              onTap: () {
                _promptForStudentName(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail, color: Colors.purple),
              title: const Text('Messages'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.money, color: Colors.red),
              title: const Text('Fee Management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddFeePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.orange),
              title: const Text('Student List'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentListPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.login, color: Colors.blue),
              title: const Text('Student Login'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const LoginPage(firebaseConnected: true),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut(); // Sign out from Firebase
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (context) => const LoginPage(firebaseConnected: true),
                  ),
                ); // Navigate back to LoginPage
              },
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Container(
            color: Colors.grey[200], // Background color for the body
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildFeatureCard(
                            Icons.check_circle,
                            'Monthly Attendance',
                            Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const UsersAttendancePage(),
                                ),
                              );
                            },
                          ),
                          buildFeatureCard(
                            Icons.money,
                            'Payment',
                            Colors.red,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddFeePage(),
                                ),
                              );
                            },
                          ),
                          buildFeatureCard(
                            Icons.people,
                            'Customer List',
                            Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudentListPage(),
                                ),
                              );
                            },
                          ),
                          buildFeatureCard(
                            Icons.school,
                            'Data Sheet',
                            Colors.teal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const FetchAttendancePage(),
                                ),
                              );
                            },
                          ),
                          buildFeatureCard(
                            Icons.gps_fixed,
                            'Customers Entrys',
                            Colors.amber,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const StudentListPage1(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount =
                          constraints.maxWidth < 600
                              ? 2
                              : 4; // Adjust based on screen width
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.5,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        children: [
                          buildActionCard(
                            Icons.check_circle,
                            'Monthly Attendance',
                            Colors.green,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const UsersAttendancePage(),
                                ),
                              );
                            },
                          ),
                          buildActionCard(
                            Icons.mail,
                            'Milk Man',
                            Colors.purple,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DailyLitersPage(),
                                ),
                              );
                            },
                          ),
                          buildActionCard(
                            Icons.mail,
                            'Book',
                            const Color.fromARGB(255, 146, 176, 39),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const CustomerListPage(),
                                ),
                              );
                            },
                          ),
                          buildActionCard(
                            Icons.currency_rupee,
                            'Daily Amount',
                            const Color.fromARGB(255, 39, 85, 176),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DailyAmountPage(),
                                ),
                              );
                            },
                          ),
                          buildActionCard(
                            Icons.money,
                            'Payments',
                            Colors.red,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddFeePage(),
                                ),
                              );
                            },
                          ),
                          buildActionCard(
                            Icons.people,
                            'View Customers',
                            Colors.orange,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudentListPage(),
                                ),
                              );
                            },
                          ),
                          buildActionCard(
                            Icons.people,
                            'Delete Data',
                            Colors.orange,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DeletePage(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _promptForStudentName(BuildContext context) {
    // Function logic to prompt for student name and handle attendance...
  }

  Widget buildFeatureCard(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap, {
    double fontSize = 12, // Default font size
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                ), // Custom font size
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
