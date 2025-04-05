import 'dart:ui' as ui;
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';

class AddFeePage extends StatefulWidget {
  const AddFeePage({super.key});

  @override
  _AddFeePageState createState() => _AddFeePageState();
}

class _AddFeePageState extends State<AddFeePage> {
  final TextEditingController litersController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  double selectedRate = 85.0;
  bool isLoading = false;
  List<String> names = [];
  String? selectedName;
  String? selectedMonth;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _fetchNames();
  }

  void _fetchNames() async {
    try {
      final snapshot = await _database.child('attendance').get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          // Fetch names and sort them alphabetically
          names = data.keys.map((key) => key.toString()).toList();
          names.sort((a, b) => a.compareTo(b)); // Sort names alphabetically
        });
      } else {
        setState(() {
          names = [];
        });
      }
    } catch (error) {
      _showSnackBar('Error fetching names: $error');
    }
  }

  void _fetchLiters() async {
    if (selectedName == null || selectedName!.isEmpty || selectedMonth == null)
      return;

    setState(() => isLoading = true);

    try {
      final snapshot =
          await _database.child('attendance').child(selectedName!).get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;

        double totalLiters = 0.0;
        data.forEach((date, liters) {
          DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
          if (DateFormat('MMMM').format(parsedDate) == selectedMonth) {
            totalLiters += double.tryParse(liters.toString()) ?? 0.0;
          }
        });

        setState(() {
          litersController.text = totalLiters.toStringAsFixed(2);
          _calculateAmount();
        });
      } else {
        _showSnackBar('No records found for $selectedName');
        _clearFields();
      }
    } catch (error) {
      _showSnackBar('Error: $error');
    }

    setState(() => isLoading = false);
  }

  void _calculateAmount() {
    final double liters = double.tryParse(litersController.text) ?? 0.0;
    final double amount = liters * selectedRate;
    setState(() => amountController.text = amount.toStringAsFixed(2));
  }

  void _submitData() async {
    final String liters = litersController.text.trim();
    final String amount = amountController.text.trim();

    if (selectedName != null && liters.isNotEmpty && amount.isNotEmpty) {
      _database
          .child('bill')
          .child(selectedName!)
          .set({'liters': liters, 'amount': amount})
          .then((_) async {
            _showSnackBar('Details added for $selectedName');
            await _shareBillDetails(selectedName!, liters, amount);
            _clearFields();
          })
          .catchError((error) {
            _showSnackBar('Error: $error');
          });
    } else {
      _showSnackBar('Fill all fields');
    }
  }

  Future<void> _shareBillDetails(
    String name,
    String liters,
    String amount,
  ) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromPoints(
        const Offset(0, 0),
        const Offset(500, 900), // Adjusted height to fit all content
      ),
    );

    // Draw light background
    final paint = Paint()..color = Colors.lightBlue[50]!;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 500, 900), paint);

    // Draw black border with padding
    final borderPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5;
    canvas.drawRect(const Rect.fromLTWH(12, 13, 480, 878), borderPaint);

    // Define text style for "MILK BILL"
    final milkBillStyle = ui.TextStyle(
      color: Colors.red,
      fontSize: 60,
      fontWeight: ui.FontWeight.bold,
      fontFamily: 'Courier',
    );

    // Create text paragraph builder
    final milkBillParagraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(milkBillStyle)
          ..addText("MILK BILL");

    // Build and layout the paragraph with a finite width
    final milkBillParagraph = milkBillParagraphBuilder.build();
    milkBillParagraph.layout(const ui.ParagraphConstraints(width: 400));

    // Draw blue background exactly behind the text
    final textBackgroundPaint = Paint()..color = Colors.blue;
    canvas.drawRect(
      Rect.fromLTWH(50, 20, milkBillParagraph.width, milkBillParagraph.height),
      textBackgroundPaint,
    );
    canvas.drawParagraph(milkBillParagraph, const Offset(50, 20));

    // Define text styles for other details with different colors
    final nameTextStyle = ui.TextStyle(
      color: Colors.blue,
      fontSize: 40,
      fontWeight: ui.FontWeight.bold,
    );
    final litersTextStyle = ui.TextStyle(
      color: Colors.green,
      fontSize: 40,
      fontWeight: ui.FontWeight.bold,
    );
    final amountTextStyle = ui.TextStyle(
      color: Colors.orange,
      fontSize: 40,
      fontWeight: ui.FontWeight.bold,
    );

    // Draw name
    final nameParagraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(nameTextStyle)
          ..addText("NAME: $name");
    final nameParagraph = nameParagraphBuilder.build();
    nameParagraph.layout(const ui.ParagraphConstraints(width: 500));
    canvas.drawParagraph(nameParagraph, const Offset(0, 100));

    // Draw liters
    final litersParagraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(litersTextStyle)
          ..addText("LITERS: $liters");
    final litersParagraph = litersParagraphBuilder.build();
    litersParagraph.layout(const ui.ParagraphConstraints(width: 500));
    canvas.drawParagraph(litersParagraph, const Offset(0, 190));

    // Draw amount
    final amountParagraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(amountTextStyle)
          ..addText("AMOUNT: ₹ $amount");
    final amountParagraph = amountParagraphBuilder.build();
    amountParagraph.layout(const ui.ParagraphConstraints(width: 500));
    canvas.drawParagraph(amountParagraph, const Offset(0, 290));

    // Draw Phone Pay number
    final phonePayStyle = ui.TextStyle(
      color: Colors.black,
      fontSize: 30,
      fontWeight: ui.FontWeight.bold,
    );

    final phonePayParagraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(phonePayStyle)
          ..addText("PhonePe (or) G - Pay: 8121505282");
    final phonePayParagraph = phonePayParagraphBuilder.build();
    phonePayParagraph.layout(const ui.ParagraphConstraints(width: 500));
    canvas.drawParagraph(phonePayParagraph, const Offset(0, 390));

    // Draw QR code
    final qrCode = QrPainter(
      data: "upi://pay?pa=8121505282@ybl&pn=$name&am=$amount&cu=INR",
      version: QrVersions.auto,
      gapless: true,
    );

    final qrCodeImage = await qrCode.toImage(200);
    canvas.drawImage(qrCodeImage, const Offset(150, 490), Paint());

    // Draw message below QR code
    final qrMessageStyle = ui.TextStyle(
      color: Colors.black,
      fontSize: 30,
      fontWeight: ui.FontWeight.bold,
    );

    final qrMessageParagraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(qrMessageStyle)
          ..addText("Please scan and pay");
    final qrMessageParagraph = qrMessageParagraphBuilder.build();
    qrMessageParagraph.layout(const ui.ParagraphConstraints(width: 500));
    canvas.drawParagraph(qrMessageParagraph, const Offset(0, 700));

    // Draw message below QR code
    final afterPayMessageBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(qrMessageStyle)
          ..addText("After payment, please send a screenshot");
    final afterPayMessageParagraph = afterPayMessageBuilder.build();
    afterPayMessageParagraph.layout(const ui.ParagraphConstraints(width: 500));
    canvas.drawParagraph(afterPayMessageParagraph, const Offset(0, 770));

    // Finalize the image
    final ui.Image image = await recorder.endRecording().toImage(500, 900);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) return;

    final Uint8List imageBytes = byteData.buffer.asUint8List();

    // Save the image
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/bill_details.png');
    await file.writeAsBytes(imageBytes);

    // Share the image
    Share.shareXFiles([XFile(file.path)], text: "Payment Details");
  }

  void _clearFields() {
    setState(() {
      selectedName = null;
      selectedMonth = null; // Clear selected month
      litersController.clear();
      amountController.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startListening() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize();
        if (available) {
          setState(() {
            _isListening = true;
          });
          _speech.listen(
            onResult: (result) {
              String recognizedWords = result.recognizedWords;
              setState(() {
                selectedName = recognizedWords;
                _fetchLiters(); // Automatically fetch liters based on recognized name
              });
            },
          );
        } else {
          _showSnackBar('Speech recognition initialization failed');
        }
      } catch (e) {
        _showSnackBar('Error initializing speech recognition: $e');
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Bill Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedName,
              items:
                  names.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedName = value;
                  _fetchLiters();
                });
              },
              decoration: const InputDecoration(labelText: 'Select Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: litersController,
              decoration: const InputDecoration(labelText: 'Liters'),
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            // Dropdown for month selection
            DropdownButtonFormField<String>(
              value: selectedMonth,
              items:
                  months.map((month) {
                    return DropdownMenuItem(value: month, child: Text(month));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value;
                  _fetchLiters(); // Fetch liters when month changes
                });
              },
              decoration: const InputDecoration(labelText: 'Select Month'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              value: selectedRate,
              items:
                  [60.0, 65.0, 70.0, 75.0, 80.0, 85.0, 90.0, 95.0, 100.0]
                      .map(
                        (rate) => DropdownMenuItem(
                          value: rate,
                          child: Text('₹$rate per liter'),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedRate = value;
                    _calculateAmount();
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Rate per Liter'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Total Amount'),
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
            const SizedBox(height: 32),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: _submitData,
                  child: const Text('Add Details & Share'),
                ),
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: _isListening ? _stopListening : _startListening,
              tooltip: _isListening ? 'Stop Listening' : 'Start Listening',
            ),
          ],
        ),
      ),
    );
  }
}
