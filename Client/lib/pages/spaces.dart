import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'space_details.dart';
import 'package:inzynierka_client/state/state.dart';
import '../classes/space.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpacesPage extends StatefulWidget {
  const SpacesPage({super.key});

  @override
  SpacesPageState createState() => SpacesPageState();
}

class SpacesPageState extends State<SpacesPage> {
  late Future<List<Space>> _spacesFuture;

  @override
  void initState() {
    super.initState();
    _spacesFuture = fetchSpaces();
  }

  Future<List<Space>> fetchSpaces() async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/spaces/get/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      List<Space> spaces = data.map((item) => Space.fromJson(item)).toList();
      return spaces;
    } else {
      throw Exception('Failed to load spaces');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Space>>(
        future: _spacesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Failed to load data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No spaces found'));
          }

          final spaces = snapshot.data!;
          return ListView.builder(
            itemCount: spaces.length,
            padding: const EdgeInsets.all(16.0),  // Add padding around the list
            itemBuilder: (context, index) {
              final space = spaces[index];
              return Card(
                elevation: 4,  // Add a slight shadow effect
                margin: const EdgeInsets.symmetric(vertical: 8.0),  // Add margin between cards
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),  // Rounded corners
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),  // Add padding inside the ListTile
                  leading: const Icon(Icons.home, size: 40, color: Colors.blueAccent),  // Add an icon
                  title: Text(
                    space.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    space.description ?? 'No description available',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),  // Add a trailing icon
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpaceDetailsPage(space: space),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
