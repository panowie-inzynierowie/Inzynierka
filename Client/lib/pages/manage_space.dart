import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ManageSpacePage extends StatefulWidget {
  final int spaceId;

  const ManageSpacePage({required this.spaceId, Key? key}) : super(key: key);

  @override
  _ManageSpacePageState createState() => _ManageSpacePageState();
}

class _ManageSpacePageState extends State<ManageSpacePage> {
  final TextEditingController _usernameController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/spaces/${widget.spaceId}/users/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      setState(() {
        _errorMessage = 'Failed to load users';
      });
    }
  }


  Future<void> _addUser() async {
    setState(() {
      _errorMessage = null;
    });

    final token = Provider.of<AppState>(context, listen: false).token;
    final username = _usernameController.text;

    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/api/spaces/${widget.spaceId}/add_user/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(<String, String>{'username': username}),
    );

    if (response.statusCode == 200) {
      _usernameController.clear();
      _fetchUsers();
    } else {
      setState(() {
        _errorMessage = 'Failed to add user';
      });
    }
  }

  Future<void> _removeUser(int userId) async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_URL']}/api/spaces/${widget.spaceId}/remove_user/$userId/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 204) {
      _fetchUsers();
    } else {
      setState(() {
        _errorMessage = 'Failed to remove user';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Space')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Input for adding a user
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username to add',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addUser,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List of users with delete option
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    title: Text(user['username']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _removeUser(user['id']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
