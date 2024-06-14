import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'command_details.dart';
import 'package:inzynierka_client/state/state.dart';

class CommandsPage extends StatefulWidget {
  const CommandsPage({super.key});

  @override
  CommandsPageState createState() => CommandsPageState();
}

class CommandsPageState extends State<CommandsPage> {
  late Future<List<Command>> _commandsFuture;
  List<Command> _commands = [];

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
      List<Command> commands =
          data.map((item) => Command.fromJson(item)).toList();
      _commands = commands;
      return _commands;
    } else {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load commands');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Command>>(
        future: _commandsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return const Center(child: Text('Błąd wczytywania danych'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak dostępnych poleceń'));
          }

          final commands = snapshot.data!;
          return ListView.builder(
            itemCount: commands.length,
            itemBuilder: (context, index) {
              final command = commands[index];
              return ListTile(
                title: Text(command.name),
                subtitle: Text(command.description),
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
    );
  }
}

class Command {
  final String name;
  final String description;

  Command({required this.name, required this.description});

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      name: json['name'],
      description: json['description'],
    );
  }
}
