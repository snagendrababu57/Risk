import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:milk/pages/book_attendence.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:io';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CustomerListPageState createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final DatabaseReference _customerRef = FirebaseDatabase.instance.ref(
    'customers',
  );
  final DatabaseReference _attendanceRef = FirebaseDatabase.instance.ref(
    'booklets',
  );

  List<Map<String, dynamic>> _customers = [];
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchAllCustomers();
  }

  void _fetchAllCustomers({String query = ""}) async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _customerRef.get();
      if (!snapshot.exists) {
        setState(() {
          _customers = [];
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.value as Map;
      List<Map<String, dynamic>> loadedCustomers = [];

      data.forEach((key, customerData) {
        final customerName = customerData['name'] ?? 'No Name';
        if (query.isEmpty ||
            customerName.toLowerCase().contains(query.toLowerCase())) {
          loadedCustomers.add({
            "id": key,
            "name": customerName,
            "mobile": customerData['phone'] ?? 'No Mobile',
          });
        }
      });

      loadedCustomers.sort((a, b) => a["name"].compareTo(b["name"]));

      setState(() {
        _customers = loadedCustomers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching customers: $e")));
    }
  }

  void _editAttendance(String customerId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AttendancePage1(customerId: customerId, customerName: name),
      ),
    );
  }

  void _viewAttendance(String customerId, String name) async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _attendanceRef.child(customerId).get();
      if (!snapshot.exists) {
        _showAttendanceDialog(name, []);
      } else {
        final attendanceData =
            (snapshot.value as Map).entries.map((entry) {
              return {
                "date": entry.key.toString(),
                "status": entry.value.toString(),
              };
            }).toList();

        // Sort attendance data by date
        attendanceData.sort((a, b) {
          DateTime dateA = DateFormat("dd-MM-yyyy").parse(a["date"]!);
          DateTime dateB = DateFormat("dd-MM-yyyy").parse(b["date"]!);
          return dateA.compareTo(dateB);
        });

        _showAttendanceDialog(name, attendanceData);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching attendance: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAttendanceDialog(
    String name,
    List<Map<String, String>> attendance,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Attendance for $name"),
            content: Container(
              width: double.maxFinite, // Make the dialog width responsive
              child: SingleChildScrollView(
                child: Container(
                  color: Colors.transparent, // Set to transparent
                  padding: const EdgeInsets.all(16.0),
                  child: RepaintBoundary(
                    key: _globalKey,
                    child: Container(
                      color:
                          Colors
                              .white, // Set the desired background color for the image
                      padding: const EdgeInsets.all(16.0),
                      child:
                          attendance.isEmpty
                              ? const Text("No attendance data available.")
                              : Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    attendance.map((entry) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            entry["date"]!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black, // Text color
                                            ),
                                          ),
                                          Text(
                                            entry["status"]!,
                                            style: const TextStyle(
                                              color: Colors.black, // Text color
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
              TextButton(
                onPressed: () async {
                  await _sendAttendanceDataAsImage(name);
                  Navigator.pop(context);
                },
                child: const Text("Send as Image"),
              ),
            ],
          ),
    );
  }

  Future<void> _sendAttendanceDataAsImage(String customerName) async {
    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Ensure rendering

      RenderRepaintBoundary? boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception(
          "Render boundary is null. Make sure the widget is wrapped in RepaintBoundary.",
        );
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception("Failed to convert image to byte data.");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final String imagePath = '${directory.path}/attendance.png';
      final File imgFile = File(imagePath);
      await imgFile.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(imagePath),
      ], text: "Attendance data for $customerName");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attendance data sent for $customerName")),
      );
    } catch (e) {
      print("Error in _sendAttendanceDataAsImage: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error generating image: $e")));
    }
  }

  void _editCustomerName(String customerId, String currentName) {
    _nameController.text = currentName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Customer Name"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "New Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  _updateCustomerName(customerId, newName);
                  Navigator.pop(context);
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _updateCustomerName(String customerId, String newName) async {
    try {
      await _customerRef.child(customerId).update({'name': newName});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer name updated successfully!")),
      );
      _fetchAllCustomers(); // Refresh the list after updating
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating customer name: $e")),
      );
    }
  }

  void _deleteCustomer(String customerId) async {
    try {
      await _customerRef.child(customerId).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer deleted successfully!")),
      );
      _fetchAllCustomers(); // Refresh the list after deletion
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting customer: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers List'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Search by Name',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      _fetchAllCustomers(query: name);
                    },
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _customers.isEmpty
                      ? const Center(child: Text('No customers found'))
                      : ListView.builder(
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                customer['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Mobile: ${customer['mobile']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.view_list,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'View Attendance',
                                    onPressed:
                                        () => _viewAttendance(
                                          customer['id'],
                                          customer['name'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Edit Customer Name',
                                    onPressed:
                                        () => _editCustomerName(
                                          customer['id'],
                                          customer['name'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.deepOrange,
                                    ),
                                    tooltip: 'Add Attendance',
                                    onPressed:
                                        () => _editAttendance(
                                          customer['id'],
                                          customer['name'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Delete Customer',
                                    onPressed:
                                        () => _deleteCustomer(customer['id']),
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
