import 'package:flutter/material.dart';
import '../classes/command.dart';

class CommandDetailsPage extends StatelessWidget {
  final Command command;

  const CommandDetailsPage({required this.command, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Details'),
        backgroundColor: Colors.blueAccent, // Customizing AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4, // Adding shadow for the card
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description Section
                Row(
                  children: [
                    const Icon(Icons.description, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  command.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),

                // Scheduled At Section
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    const Text(
                      'Scheduled At:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  command.scheduledAt != null
                      ? command.scheduledAt!.toLocal().toString()
                      : 'No scheduled time',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),

                // Devices Section
                Row(
                  children: [
                    const Icon(Icons.devices, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    const Text(
                      'Devices:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: command.deviceIds
                      .map((id) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'Device ID: $id',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
