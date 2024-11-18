import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'space_details.dart';
import 'package:inzynierka_client/state/state.dart';
import '../classes/space.dart';
import '../classes/device.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpacesPage extends StatefulWidget {
  const SpacesPage({super.key});

  @override
  SpacesPageState createState() => SpacesPageState();
}

class SpacesPageState extends State<SpacesPage> {
  late Future<List<Space>> _spacesFuture;
  late Future<List<Device>> _spacelessDevicesFuture;
  int? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _spacesFuture = fetchSpaces();
    _spacelessDevicesFuture = fetchSpacelessDevices();
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

  Future<List<Device>> fetchSpacelessDevices() async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/devices/get/?spaceless=True'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((item) => Device.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load spaceless devices');
    }
  }

  Future<void> assignDeviceToSpace(int deviceId, int spaceId) async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.put(
      Uri.parse('${dotenv.env['API_URL']}/api/devices/$deviceId/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'space': spaceId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device assigned successfully')),
      );
      setState(() {
        _selectedDeviceId = null;
        _spacesFuture = fetchSpaces();
        _spacelessDevicesFuture = fetchSpacelessDevices();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign device')),
      );
    }
  }

  void performAction(int deviceId, String componentName, String action) async {
    final token = Provider.of<AppState>(context, listen: false).token;

    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/api/commands/add/?all=True'),
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
        const SnackBar(content: Text('Action performed successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to perform action')),
      );
    }
  }

  Widget buildDeviceCard(Device device) {
    final Map<String, TextEditingController> _customActionControllers = {};
    String _getControllerKey(int deviceId, String componentName) {
      return '$deviceId-$componentName';
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.devices,
                        size: 24, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDeviceId =
                          _selectedDeviceId == device.id ? null : device.id;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedDeviceId == device.id
                        ? Colors.red
                        : Colors.blue,
                  ),
                  child: Text(
                      _selectedDeviceId == device.id ? 'Cancel' : 'Assign'),
                ),
              ],
            ),
            if (device.data != null &&
                device.data!['components'] is List &&
                (device.data!['components'] as List).isNotEmpty)
              ...device.data!['components'].map((component) {
                if (component['actions'] is List) {
                  final controllerKey =
                      _getControllerKey(device.id, component['name']);
                  _customActionControllers.putIfAbsent(
                      controllerKey, () => TextEditingController());

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        component['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: (component['is_output'] == false
                                ? component['actions'] as List
                                : [])
                            .map<Widget>((action) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              performAction(
                                device.id,
                                component['name'],
                                action,
                              );
                            },
                            child: Text(action.toString()),
                          );
                        }).toList(),
                      ),
                      if (component['has_input_action'] == true) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller:
                                    _customActionControllers[controllerKey],
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
                                    _customActionControllers[controllerKey]
                                        ?.text;
                                if (customAction?.isNotEmpty == true) {
                                  performAction(device.id, component['name'],
                                      customAction!);
                                  _customActionControllers[controllerKey]
                                      ?.clear();
                                }
                              },
                              child: const Text('Send'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildSpaceCard(Space space) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.home, size: 40, color: Colors.blueAccent),
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
        trailing: _selectedDeviceId != null
            ? ElevatedButton(
                onPressed: () =>
                    assignDeviceToSpace(_selectedDeviceId!, space.id),
                child: const Text('Add'),
              )
            : const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
        onTap: _selectedDeviceId == null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpaceDetailsPage(space: space),
                  ),
                );
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _selectedDeviceId = null;
            _spacesFuture = fetchSpaces();
            _spacelessDevicesFuture = fetchSpacelessDevices();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spaces',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Space>>(
                  future: _spacesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Failed to load spaces'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No spaces found'));
                    }

                    return Column(
                      children: snapshot.data!
                          .map((space) => buildSpaceCard(space))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'Unassigned Devices',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Device>>(
                  future: _spacelessDevicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(
                          child: Text('Failed to load devices'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No unassigned devices found'));
                    }

                    return Column(
                      children: snapshot.data!
                          .map((device) => buildDeviceCard(device))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
