import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'create_command.dart';
import 'command_details.dart';
import '../classes/device.dart';
import '../classes/command.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeviceDetailsPage extends StatefulWidget {
  final Device device;

  const DeviceDetailsPage({required this.device, Key? key}) : super(key: key);

  @override
  DeviceDetailsPageState createState() => DeviceDetailsPageState();
}

class DeviceDetailsPageState extends State<DeviceDetailsPage> {
  late Future<List<Command>> _commandsFuture;

  @override
  void initState() {
    super.initState();
    _commandsFuture = fetchCommands();
  }

  Future<List<Command>> fetchCommands() async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/commands/get/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      log('Pobrane dane:');
      log('Response data: $data'); // Print the data to verify
      return data.map((item) => Command.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load commands');
    }
  }

  void refreshCommands() {
    setState(() {
      _commandsFuture = fetchCommands();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: Colors.blueAccent,  // Customize AppBar color
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Status: Active',  // You can customize this based on your data
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green, // Status color
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.device.description ?? 'No description available',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Command>>(
              future: _commandsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load data'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No commands found'));
                }

                final commands = snapshot.data!
                    .where((command) => command.deviceIds.contains(widget.device.id))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: commands.length,
                  itemBuilder: (context, index) {
                    final command = commands[index];
                    return Card(
                      elevation: 4,  // Add shadow to the card
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.settings,
                          color: Colors.blueAccent,
                          size: 40,
                        ),
                        title: Text(
                          command.description,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Scheduled at: ${command.scheduledAt}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommandDetailsPage(command: command),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,  // Customize FAB color
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateCommandPage(deviceId: widget.device.id),
            ),
          );
          if (result == true) {
            refreshCommands();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
