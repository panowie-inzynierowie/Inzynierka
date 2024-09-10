import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wifi_scan/wifi_scan.dart';

class CreateDevicePage extends StatefulWidget {
  final int? spaceId;

  const CreateDevicePage({required this.spaceId, Key? key}) : super(key: key);

  @override
  _CreateDevicePageState createState() => _CreateDevicePageState();
}

class _CreateDevicePageState extends State<CreateDevicePage> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _deviceDescriptionController =
  TextEditingController();
  String? _errorMessage;

  List<WiFiAccessPoint> aps = [];

  @override
  void initState() {
    super.initState();
    _getScannedResults(context);
  }

  Future<void> _getScannedResults(BuildContext content) async {
    if (await _canGetScannedResults(context)) {
      final results = await WiFiScan.instance.getScannedResults();
      setState(() {
        aps = results;
      });
    }
  }

  Future<bool> _canGetScannedResults(BuildContext context) async {
    final can = await WiFiScan.instance.canGetScannedResults();
    if (can != CanGetScannedResults.yes) {
      if (context.mounted) {
        if (can == CanGetScannedResults.noLocationServiceDisabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Please allow and enable Location service then try again.')),
          );
        }
      }
      aps = <WiFiAccessPoint>[];
      return false;
    }
    return true;
  }

  void _createDevice() async {
    setState(() {
      _errorMessage = null; // Reset error message
    });

    try {
      final token = Provider.of<AppState>(context, listen: false).token;

      final payload = jsonEncode(<String, dynamic>{
        'name': _deviceNameController.text,
        'description': _deviceDescriptionController.text,
        'space_id': widget.spaceId,
      });

      print('Request payload: $payload'); // Log the payload

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/devices/add/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
        body: payload,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Log the response body

      if (response.statusCode == 201) {
        Navigator.pop(context, true); // Return true when device is created
      } else {
        setState(() {
          _errorMessage =
          'Failed to create device: ${response.reasonPhrase}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create device: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Device'),
        backgroundColor: Colors.blueAccent, // Custom AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Name Input
            TextField(
              controller: _deviceNameController,
              decoration: InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Device Description Input
            TextField(
              controller: _deviceDescriptionController,
              decoration: InputDecoration(
                labelText: 'Device Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Wi-Fi Networks List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100], // Light background for the list
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListView.builder(
                  itemCount: aps.length,
                  itemBuilder: (context, index) {
                    final ap = aps[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text(ap.ssid),
                        subtitle: const Text('Tap to select'),
                        onTap: () {
                          // Handle tap to select Wi-Fi
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],

            const SizedBox(height: 20),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Create Device'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
