import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'create_command.dart'; // Assuming you have a CreateCommandPage
import 'command_details.dart'; // Assuming you have a CommandDetailsPage
import '../classes/device.dart';
import '../classes/command.dart';

class DeviceDetailsPage extends StatefulWidget {
  final Device device;

  const DeviceDetailsPage({required this.device, Key? key}) : super(key: key);

  @override
  _DeviceDetailsPageState createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  late Future<List<Command>> _commandsFuture;

  @override
  void initState() {
    super.initState();
    _commandsFuture = fetchCommands();
  }

  Future<List<Command>> fetchCommands() async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8001/api/commands/get/'),
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
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
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
      ),
      body: FutureBuilder<List<Command>>(
        future: _commandsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return const Center(child: Text('Błąd wczytywania danych'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak dostępnych komend'));
          }

          final commands = snapshot.data!
              .where((command) => command.deviceIds.contains(widget.device.id))
              .toList();
          return ListView.builder(
            itemCount: commands.length,
            itemBuilder: (context, index) {
              final command = commands[index];
              return ListTile(
                title: Text(command.description),
                subtitle: Text('Scheduled at: ${command.scheduledAt}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommandDetailsPage(command: command),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateCommandPage(deviceId: widget.device.id),
            ),
          );
          if (result == true) {
            refreshCommands();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
