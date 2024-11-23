import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import '../classes/device.dart';

class ManageDevicePage extends StatefulWidget {
  final Device device;

  const ManageDevicePage({required this.device, Key? key}) : super(key: key);

  @override
  _ManageDevicePageState createState() => _ManageDevicePageState();
}

class _ManageDevicePageState extends State<ManageDevicePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.device.name;
  }

  Future<void> _updateDeviceName() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.put(
      Uri.parse('${dotenv.env['API_URL']}/api/devices/${widget.device.id}/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({'name': _nameController.text}),
    );

    setState(() {
      _isSaving = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device name updated successfully')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = 'Failed to update device name';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Device')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _updateDeviceName,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
