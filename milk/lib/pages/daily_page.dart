import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DailyLitersPage extends StatefulWidget {
  const DailyLitersPage({super.key});

  @override
  _DailyLitersPageState createState() => _DailyLitersPageState();
}

class _DailyLitersPageState extends State<DailyLitersPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final List<DateTime> _dates = [];
  final Map<DateTime, TextEditingController> _morningControllers = {};
  final Map<DateTime, TextEditingController> _eveningControllers = {};
  final Map<DateTime, TextEditingController> _returnControllers = {};
  final Map<DateTime, String> _savedTimestamps = {};
  final Map<DateTime, double> _dailyTotals = {};
  double _monthlyTotal = 0.0;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  ); // Initialize to the first day of the current month

  @override
  void initState() {
    super.initState();
    _generateDates();
    _fetchExistingData();
  }

  void _generateDates() {
    final int daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    _dates.clear(); // Clear previous dates
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, i);
      _dates.add(date);
      _morningControllers[date] = TextEditingController();
      _eveningControllers[date] = TextEditingController();
      _returnControllers[date] = TextEditingController();
      _dailyTotals[date] = 0.0;
    }
  }

  void _fetchExistingData() {
    String monthKey = DateFormat('yyyy-MM').format(_selectedMonth);
    _database
        .child('liters')
        .orderByKey()
        .startAt(monthKey)
        .endAt('$monthKey\uf8ff')
        .onValue
        .listen((event) {
          if (event.snapshot.exists && event.snapshot.value is Map) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            double total = 0.0;

            setState(() {
              for (DateTime date in _dates) {
                String dateKey = DateFormat('yyyy-MM-dd').format(date);
                if (data.containsKey(dateKey)) {
                  final entry = data[dateKey] as Map<dynamic, dynamic>;
                  final double morning = (entry['morning'] ?? 0.0).toDouble();
                  final double evening = (entry['evening'] ?? 0.0).toDouble();
                  final double returned = (entry['returned'] ?? 0.0).toDouble();
                  final String timestamp = entry['timestamp'] ?? '';
                  final double dailyTotal = morning + evening - returned;

                  _morningControllers[date]?.text = morning.toString();
                  _eveningControllers[date]?.text = evening.toString();
                  _returnControllers[date]?.text = returned.toString();
                  _savedTimestamps[date] = timestamp;
                  _dailyTotals[date] = dailyTotal;
                  total += dailyTotal;
                }
              }
              _monthlyTotal = total;
            });
          }
        });
  }

  void _submitData(DateTime date) async {
    final double morning =
        double.tryParse(_morningControllers[date]?.text ?? '0.0') ?? 0.0;
    final double evening =
        double.tryParse(_eveningControllers[date]?.text ?? '0.0') ?? 0.0;
    final double returned =
        double.tryParse(_returnControllers[date]?.text ?? '0.0') ?? 0.0;
    final double total = morning + evening - returned;
    final String timestamp = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    await _database
        .child('liters')
        .child(DateFormat('yyyy-MM-dd').format(date))
        .set({
          'morning': morning,
          'evening': evening,
          'returned': returned,
          'total': total,
          'timestamp': timestamp,
        })
        .then((_) {
          setState(() {
            _savedTimestamps[date] = timestamp;
            _dailyTotals[date] = total;
            _calculateMonthlyTotal();
          });
          _showSnackBar('Saved for ${DateFormat('yyyy-MM-dd').format(date)}');
        })
        .catchError((error) {
          _showSnackBar('Error: $error');
        });
  }

  void _calculateMonthlyTotal() {
    double total = _dailyTotals.values.fold(
      0.0,
      (sum, element) => sum + element,
    );
    setState(() {
      _monthlyTotal = total;
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

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _selectedMonth = newMonth;
      _generateDates();
      _fetchExistingData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive sizes
    final totalFontSize = screenWidth * 0.05; // 5% of screen width
    final totalPadding = screenWidth * 0.02; // 2% of screen width

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Liters Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for month selection
            DropdownButton<DateTime>(
              value: _selectedMonth,
              items: List.generate(12, (index) {
                final month = DateTime(
                  DateTime.now().year,
                  index + 1,
                  1,
                ); // Ensure the day is set to 1
                return DropdownMenuItem(
                  value: month,
                  child: Text(DateFormat('MMMM yyyy').format(month)),
                );
              }),
              onChanged: (newValue) {
                if (newValue != null) {
                  _onMonthChanged(newValue);
                }
              },
            ),
            // Card displaying the total for the selected month
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(totalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total for ${DateFormat('MMMM yyyy').format(_selectedMonth)}:',
                      style: TextStyle(
                        fontSize: totalFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_monthlyTotal.toStringAsFixed(2)} liters',
                      style: TextStyle(
                        fontSize: totalFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // List of daily entries
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
                                '${_dailyTotals[date]?.toStringAsFixed(2) ?? "0.00"} liters',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          _buildTextField(
                            'Morning Liters',
                            _morningControllers[date]!,
                          ),
                          _buildTextField(
                            'Evening Liters',
                            _eveningControllers[date]!,
                          ),
                          _buildTextField(
                            'Return Liters',
                            _returnControllers[date]!,
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
