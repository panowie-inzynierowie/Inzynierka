import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateSpacePage extends StatefulWidget {
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
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
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
      appBar: AppBar(
        title: Text('Create New Space'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _spaceNameController,
              decoration: InputDecoration(labelText: 'Space Name'),
            ),
            TextField(
              controller: _spaceDescriptionController,
              decoration: InputDecoration(labelText: 'Space Description'),
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
              onPressed: _createSpace,
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
