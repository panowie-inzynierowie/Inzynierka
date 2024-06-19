import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'create_device.dart'; // Assuming you have a CreateDevicePage
import '../classes/device.dart';
import '../classes/space.dart';

class SpaceDetailsPage extends StatefulWidget {
  final Space space;

  const SpaceDetailsPage({required this.space, Key? key}) : super(key: key);

  @override
  _SpaceDetailsPageState createState() => _SpaceDetailsPageState();
}

class _SpaceDetailsPageState extends State<SpaceDetailsPage> {
  late Future<List<Device>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _devicesFuture = fetchDevices();
  }

  Future<List<Device>> fetchDevices() async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8001/api/devices/get/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      log('Pobrane dane:');
      log('Response data: $data'); // Print the data to verify
      return data.map((item) => Device.fromJson(item)).toList();
    } else {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load devices');
    }
  }

  void refreshDevices() {
    setState(() {
      _devicesFuture = fetchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.space.name),
      ),
      body: FutureBuilder<List<Device>>(
        future: _devicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return const Center(child: Text('Błąd wczytywania danych'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak dostępnych urządzeń'));
          }

          final devices = snapshot.data!
              .where((device) => device.spaceId == widget.space.id)
              .toList();
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.name),
                subtitle: Text(device.description ?? ''),
                onTap: () {
                  // Navigate to device details or perform any action
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
              builder: (context) => CreateDevicePage(spaceId: widget.space.id),
            ),
          );
          if (result == true) {
            refreshDevices();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
