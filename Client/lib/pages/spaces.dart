import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'space_details.dart'; // Assuming you have a SpaceDetailsPage in space_details.dart
import 'create_space.dart'; // Assuming you have a CreateSpacePage in create_space.dart
import 'package:inzynierka_client/state/state.dart';
import '../classes/space.dart';

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
      Uri.parse('http://127.0.0.1:8001/api/spaces/get/'),
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
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
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
            print('Error: ${snapshot.error}');
            return const Center(child: Text('Błąd wczytywania danych'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak dostępnych przestrzeni'));
          }

          final spaces = snapshot.data!;
          return ListView.builder(
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final space = spaces[index];
              return ListTile(
                title: Text(space.name),
                subtitle: Text(space.description ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpaceDetailsPage(space: space),
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
              builder: (context) => CreateSpacePage(),
            ),
          );
          if (result == true) {
            setState(() {
              _spacesFuture = fetchSpaces(); // Refresh the spaces list
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
