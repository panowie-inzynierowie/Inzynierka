import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import '../classes/device.dart';
import '../classes/space.dart';
import 'manage_space.dart';

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
      Uri.parse(
          '${dotenv.env['API_URL']}/api/devices/get/?space=${widget.space.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      print(
          "Fetched devices data: $data"); // Debug print to check the API response
      if (data.isEmpty) {
        print("No devices found for this space.");
      }
      return data.map((item) => Device.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load devices');
    }
  }

  void performAction(int deviceId, String componentName, String action) async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/api/commands/add/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'device': deviceId,
        'data': {"name": componentName, "action": action}
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action performed successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to perform action')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.space.name),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              tooltip: 'Manage Space',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ManageSpacePage(spaceId: widget.space.id),
                  ),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<List<Device>>(
          future: _devicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return Center(child: Text('No devices found in this space'));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final device = snapshot.data![index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.name),
                          SizedBox(height: 8),
                          if (device.data != null &&
                              device.data!['components'] is List &&
                              (device.data!['components'] as List).isNotEmpty)
                            ...device.data!['components'].map((component) {
                              if (component['actions'] is List) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(component['name']),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: (component['actions'] as List)
                                          .map<Widget>((action) {
                                        return ElevatedButton(
                                          child: Text(action.toString()),
                                          onPressed: () {
                                            performAction(
                                              device.id,
                                              component['name'],
                                              action,
                                            );
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                );
                              }
                              return SizedBox.shrink();
                            }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text('No devices found'));
            }
          },
        ));
  }
}
