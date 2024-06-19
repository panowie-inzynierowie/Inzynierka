import 'package:flutter/material.dart';
import '../classes/command.dart';

class CommandDetailsPage extends StatelessWidget {
  final Command command;

  const CommandDetailsPage({required this.command, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Command Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(command.description),
            SizedBox(height: 10),
            Text(
              'Scheduled At:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(command.scheduledAt != null
                ? command.scheduledAt!.toLocal().toString()
                : 'No scheduled time'),
            SizedBox(height: 10),
            Text(
              'Devices:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...command.deviceIds.map((id) => Text('Device ID: $id')).toList(),
          ],
        ),
      ),
    );
  }
}
