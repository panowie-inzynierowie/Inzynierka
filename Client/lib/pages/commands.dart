import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'command_details.dart';
import '../classes/command.dart';

class CommandsPage extends StatefulWidget {
  const CommandsPage({Key? key}) : super(key: key);

  @override
  _CommandsPageState createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> {
  late Future<List<Command>> _commandsFuture;

  @override
  void initState() {
    super.initState();
    _commandsFuture = fetchCommands();
  }

  Future<List<Command>> fetchCommands() async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('${dotenv.env["API_URL"]}/api/commands/get/'),
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
            return const Center(child: Text('Brak dostępnych komend'));
          }

          final commands = snapshot.data!;
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
    );
  }
}
