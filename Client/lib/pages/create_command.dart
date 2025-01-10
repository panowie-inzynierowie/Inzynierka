import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateCommandPage extends StatefulWidget {
  final int deviceId;

  const CreateCommandPage({required this.deviceId, Key? key}) : super(key: key);

  @override
  _CreateCommandPageState createState() => _CreateCommandPageState();
}

class _CreateCommandPageState extends State<CreateCommandPage> {
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _scheduledAt;
  String? _errorMessage;

  void _createCommand() async {
    setState(() {
      _errorMessage = null;
    });

    final token = Provider.of<AppState>(context, listen: false).token;

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env["API_URL"]}/api/commands/add/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(<String, dynamic>{
          'description': _descriptionController.text,
          'scheduled_at': _scheduledAt?.toIso8601String(),
          'device_ids': [widget.deviceId],
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Failed to create command: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create command: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Command'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Command Description Input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Command Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Date Picker Button
            ElevatedButton.icon(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && picked != _scheduledAt) {
                  setState(() {
                    _scheduledAt = picked;
                  });
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _scheduledAt == null
                    ? 'Select Date'
                    : 'Selected Date: ${_scheduledAt!.toLocal()}',
              ),
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.blueAccent,
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

            const Spacer(),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createCommand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text('Create Command'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
