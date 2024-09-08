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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _deviceNameController,
              decoration: InputDecoration(labelText: 'Device Name'),
            ),
            TextField(
              controller: _deviceDescriptionController,
              decoration: InputDecoration(labelText: 'Device Description'),
            ),
            Container(
              height: 250,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: aps.length,
                itemBuilder: (context, index) {
                  final ap = aps[index];
                  return ListTile(
                    title: Text(ap.ssid),
                    subtitle: Text('Tap to select'),
                  );
                },
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createDevice,
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
