import 'package:flutter/material.dart';
import 'package:inzynierka_client/pages/command_details.dart';

class CommandsPage extends StatelessWidget {
  const CommandsPage({super.key});

  Future<List<String>> fetchCommands() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Komenda 1', 'Komenda 2', 'Komenda 3'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komendy'),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchCommands(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
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
                title: Text(command),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommandDetailPage(commandName: command),
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
