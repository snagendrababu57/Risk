import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DailyAmountPage extends StatefulWidget {
  const DailyAmountPage({super.key});

  @override
  _DailyAmountPageState createState() => _DailyAmountPageState();
}

class _DailyAmountPageState extends State<DailyAmountPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final List<DateTime> _dates = [];
  final Map<DateTime, TextEditingController> _morningControllers = {};
  final Map<DateTime, TextEditingController> _eveningControllers = {};
  double _monthlyTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _generateDates();
    _fetchExistingData();
  }

  void _generateDates() {
    final DateTime now = DateTime.now();
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(now.year, now.month, i);
      _dates.add(date);
      _morningControllers[date] = TextEditingController();
      _eveningControllers[date] = TextEditingController();
    }
  }

  void _fetchExistingData() {
    _database.child('daily_amounts').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        double total = 0.0; // Reset total for new calculation

        setState(() {
          for (DateTime date in _dates) {
            String dateKey = DateFormat('yyyy-MM-dd').format(date);
            if (data.containsKey(dateKey)) {
              final entry = data[dateKey] as Map<dynamic, dynamic>;
              final double morning = (entry['morning'] ?? 0.0).toDouble();
              final double evening = (entry['evening'] ?? 0.0).toDouble();

              // Set the text fields
              _morningControllers[date]?.text = morning.toString();
              _eveningControllers[date]?.text = evening.toString();

              // Update the total
              total += (morning + evening);
            }
          }
          _monthlyTotal = total; // Update the monthly total
        });
      }
    });
  }

  void _submitData(DateTime date) async {
    final double morning =
        double.tryParse(_morningControllers[date]?.text ?? '0.0') ?? 0.0;
    final double evening =
        double.tryParse(_eveningControllers[date]?.text ?? '0.0') ?? 0.0;

    final String timestamp = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    await _database
        .child('daily_amounts')
        .child(DateFormat('yyyy-MM-dd').format(date))
        .set({'morning': morning, 'evening': evening, 'timestamp': timestamp})
        .then((_) {
          setState(() {
            // Update the monthly total correctly
            // Since we are fetching existing data, we should not add to the total here
            // Instead, we can just fetch the data again to get the updated total
            _monthlyTotal = 0.0; // Reset total before fetching again
            _fetchExistingData(); // Fetch existing data to recalculate total
          });
          _showSnackBar('Saved for ${DateFormat('yyyy-MM-dd').format(date)}');
        })
        .catchError((error) {
          _showSnackBar('Error: $error');
        });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalFontSize = screenWidth * 0.05; // 5% of screen width
    final totalPadding = screenWidth * 0.02; // 2% of screen width

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Amount Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(totalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total :',
                      style: TextStyle(
                        fontSize: totalFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_monthlyTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: totalFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd').format(date),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(_morningControllers[date]?.text ?? "0.00")} + ${(_eveningControllers[date]?.text ?? "0.00")}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          _buildTextField(
                            'Morning Amount',
                            _morningControllers[date]!,
                          ),
                          _buildTextField(
                            'Evening Amount',
                            _eveningControllers[date]!,
                          ),
                          ElevatedButton(
                            onPressed: () => _submitData(date),
                            child: const Text('Save Data'),
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
