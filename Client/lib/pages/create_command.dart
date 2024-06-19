import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';

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
        Uri.parse('http://127.0.0.1:8001/api/commands/add/'),
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
        title: Text('Create New Command'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Command Description'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (picked != null && picked != _scheduledAt) {
                  setState(() {
                    _scheduledAt = picked;
                  });
                }
              },
              child: Text(_scheduledAt == null
                  ? 'Select Date'
                  : 'Selected Date: ${_scheduledAt!.toLocal()}'),
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
              onPressed: _createCommand,
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
