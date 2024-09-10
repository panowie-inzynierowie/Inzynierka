import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateSpacePage extends StatefulWidget {
  const CreateSpacePage({super.key});

  @override
  _CreateSpacePageState createState() => _CreateSpacePageState();
}

class _CreateSpacePageState extends State<CreateSpacePage> {
  final TextEditingController _spaceNameController = TextEditingController();
  final TextEditingController _spaceDescriptionController =
  TextEditingController();
  String? _errorMessage;

  void _createSpace() async {
    setState(() {
      _errorMessage = null; // Reset error message
    });

    try {
      final token = Provider.of<AppState>(context, listen: false).token;

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/spaces/add/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token', // Use the token from AppState
        },
        body: jsonEncode(<String, String>{
          'name': _spaceNameController.text,
          'description': _spaceDescriptionController.text,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true); // Return true when space is created
      } else {
        setState(() {
          _errorMessage = 'Failed to create space: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create space: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Space Name Input
            TextField(
              controller: _spaceNameController,
              decoration: InputDecoration(
                labelText: 'Space Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Space Description Input
            TextField(
              controller: _spaceDescriptionController,
              decoration: InputDecoration(
                labelText: 'Space Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Error Message Display
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],

            const Spacer(), // Pushes the button to the bottom

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createSpace,
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
                child: const Text('Create Space'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
