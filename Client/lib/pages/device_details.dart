import 'package:flutter/material.dart';
import 'package:inzynierka_client/classes/device.dart';

class DeviceDetailPage extends StatefulWidget {
  final String spaceName;
  final Device device;

  const DeviceDetailPage(
      {super.key, required this.spaceName, required this.device});

  @override
  DeviceDetailPageState createState() => DeviceDetailPageState();
}

class DeviceDetailPageState extends State<DeviceDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _descriptionController =
        TextEditingController(text: widget.device.description);
  }

  void _editDevice() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edytuj urządzenie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nazwa'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Opis'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  widget.device.name = _nameController.text;
                  widget.device.description = _descriptionController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Zatwierdź'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDevice() {
    // Tu można dodać logikę do usunięcia urządzenia z przestrzeni
    Navigator.of(context).pop(); // Just pop for now, implement logic as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Opis: ${widget.device.description}'),
            ElevatedButton(
              onPressed: _editDevice,
              child: const Text('Edytuj'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(widget.device.copyWith(
                  name: _nameController.text,
                  description: _descriptionController.text,
                ));
              },
              child: const Text('Usuń z przestrzeni'),
            ),
          ],
        ),
      ),
    );
  }
}
