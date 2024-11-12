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
  final Map<String, TextEditingController> _customActionControllers = {};

  @override
  void initState() {
    super.initState();
    _devicesFuture = fetchDevices();
  }

  @override
  void dispose() {
    _customActionControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> detachDevice(int deviceId) async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.put(
      Uri.parse('${dotenv.env['API_URL']}/api/devices/$deviceId/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'space': null,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device detached successfully')),
      );
      setState(() {
        _devicesFuture = fetchDevices();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to detach device')),
      );
    }
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
      print("Fetched devices data: $data");
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

  String _getControllerKey(int deviceId, String componentName) {
    return '$deviceId-$componentName';
  }

  Widget _buildComponentActions(Device device, Map<String, dynamic> component) {
    final controllerKey = _getControllerKey(device.id, component['name']);
    _customActionControllers.putIfAbsent(
        controllerKey, () => TextEditingController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(component['name']),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: (component['is_output'] == false
                  ? component['actions'] as List
                  : [])
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
        if (component['has_input_action'] == true) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customActionControllers[controllerKey],
                  decoration: const InputDecoration(
                    hintText: 'Custom action',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final customAction =
                      _customActionControllers[controllerKey]?.text;
                  if (customAction?.isNotEmpty == true) {
                    performAction(device.id, component['name'], customAction!);
                    _customActionControllers[controllerKey]?.clear();
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
        ],
        SizedBox(height: 8),
      ],
    );
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
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(device.name),
                              ElevatedButton(
                                onPressed: () => detachDevice(device.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                  elevation: 0,
                                ),
                                child: const Text('Detach'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (device.data != null &&
                              device.data!['components'] is List &&
                              (device.data!['components'] as List).isNotEmpty)
                            ...device.data!['components'].map((component) {
                              if (component['actions'] is List) {
                                return _buildComponentActions(
                                    device, component);
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
