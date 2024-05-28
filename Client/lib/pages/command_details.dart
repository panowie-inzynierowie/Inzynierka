import 'package:flutter/material.dart';

class CommandDetailPage extends StatefulWidget {
  final String commandName;

  const CommandDetailPage({super.key, required this.commandName});

  @override
  CommandDetailPageState createState() => CommandDetailPageState();
}

class CommandDetailPageState extends State<CommandDetailPage> {
  bool _isSwitched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.commandName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Szczegóły dla ${widget.commandName}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: _isSwitched,
                  onChanged: (bool value) {
                    setState(() {
                      _isSwitched = value;
                    });
                  },
                ),
                const SizedBox(width: 10),
                Text(_isSwitched ? 'Wyłącz' : 'Włącz'),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Tu można dodać logikę do usunięcia komendy
              },
              child: const Text('Usuń'),
            ),
          ],
        ),
      ),
    );
  }
}
