import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Command {
  final int id;
  final String description;
  final DateTime? scheduledAt;
  final int device;
  final Map<String, dynamic> data;
  final bool selfExecute;
  final bool executed;
  final String deviceName;

  Command({
    required this.id,
    required this.description,
    this.scheduledAt,
    required this.device,
    required this.data,
    required this.selfExecute,
    required this.executed,
    required this.deviceName,
  });

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      id: json['id'],
      description: json['description'] ?? '',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      device: json['device'],
      data: json['data'],
      selfExecute: json['self_execute'],
      executed: json['executed'],
      deviceName: json['device__name'],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Command> plannedCommands = [];
  List<Command> executedCommands = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCommands();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommands() async {
    setState(() => isLoading = true);
    final appState = context.read<AppState>();

    try {
      final plannedResponse = await http.get(
        Uri.parse(
            '${dotenv.env["API_URL"]}/api/commands/?executed=false&all=true'),
        headers: {'Authorization': 'Token ${appState.token}'},
      );

      final executedResponse = await http.get(
        Uri.parse(
            '${dotenv.env["API_URL"]}/api/commands/?executed=true&all=true'),
        headers: {'Authorization': 'Token ${appState.token}'},
      );

      if (plannedResponse.statusCode == 200 &&
          executedResponse.statusCode == 200) {
        final plannedData = json.decode(plannedResponse.body) as List;
        final executedData = json.decode(executedResponse.body) as List;

        setState(() {
          plannedCommands =
              plannedData.map((json) => Command.fromJson(json)).toList();
          executedCommands =
              executedData.map((json) => Command.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching commands: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteCommand(int commandId) async {
    final appState = context.read<AppState>();

    try {
      final response = await http.delete(
        Uri.parse(
            '${dotenv.env["API_URL"]}/api/commands/$commandId/?cancel=true'),
        headers: {'Authorization': 'Token ${appState.token}'},
      );

      if (response.statusCode == 204) {
        _fetchCommands();
      }
    } catch (e) {
      print('Error deleting command: $e');
    }
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();

    try {
      final username = await storage.read(key: "username");
      final password = await storage.read(key: "password");

      if (username != null) {
        await storage.delete(key: "username");
      }
      if (password != null) {
        await storage.delete(key: "password");
      }

      if (!mounted) return;

      final appState = context.read<AppState>();
      appState.setUsername("");
      appState.setToken("");

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Widget _buildCommandList(List<Command> commands, {bool showDelete = false}) {
    return ListView.builder(
      itemCount: commands.length,
      itemBuilder: (context, index) {
        final command = commands[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text('Device: ${command.deviceName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Component: ${command.data['name']}'),
                Text('Action: ${command.data['action']}'),
                if (command.scheduledAt != null)
                  Text('Scheduled: ${command.scheduledAt!.toLocal()}'),
              ],
            ),
            trailing: showDelete
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCommand(command.id),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDarkTheme = appState.themeMode == ThemeMode.dark;

    final buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
      backgroundColor: Colors.blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => appState.toggleTheme(),
                    style: buttonStyle,
                    child: Text(isDarkTheme ? 'Light Theme' : 'Dark Theme'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: buttonStyle,
                    child: const Text('Log out'),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Planned Commands'),
              Tab(text: 'Executed Commands'),
            ],
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCommandList(plannedCommands, showDelete: true),
                      _buildCommandList(executedCommands),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
