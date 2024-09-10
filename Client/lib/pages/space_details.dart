import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'create_device.dart';
import '../classes/device.dart';
import '../classes/space.dart';
import 'device_details.dart';  // Import the DeviceDetailsPage

class SpaceDetailsPage extends StatefulWidget {
  final Space space;

  const SpaceDetailsPage({required this.space, Key? key}) : super(key: key);

  @override
  SpaceDetailsPageState createState() => SpaceDetailsPageState();
}

class SpaceDetailsPageState extends State<SpaceDetailsPage> {
  late Future<List<Device>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _devicesFuture = fetchDevices();
  }

  Future<List<Device>> fetchDevices() async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/devices/get/'),
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
            return const Center(child: Text('Failed to load data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No devices found'));
          }

          final devices = snapshot.data!
              .where((device) => device.spaceId == widget.space.id)
              .toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // Changes position of shadow
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceDetailsPage(device: device),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.devices,  // You can change this to any relevant icon
                          size: 40,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                device.description ?? 'No description available',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DeviceDetailsPage(device: device),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,  // Customize FAB color
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
