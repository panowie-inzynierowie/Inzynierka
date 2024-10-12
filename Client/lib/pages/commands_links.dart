import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import '../classes/device.dart';

class CreateLinksScreen extends StatefulWidget {
  @override
  _CreateLinksScreenState createState() => _CreateLinksScreenState();

  const CreateLinksScreen({Key? key}) : super(key: key);
}

class _CreateLinksScreenState extends State<CreateLinksScreen> {
  List<CommandsLink> _links = [];
  List<Device> _devices = [];
  List<Map<String, dynamic>> _triggers = [];
  List<Map<String, dynamic>> _results = [];
  String? _ttl;

  @override
  void initState() {
    super.initState();
    _fetchLinks();
    _fetchDevices();
  }

  Future<void> _fetchLinks() async {
    final token = Provider.of<AppState>(context, listen: false).token;
    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/commands-links/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _links = data.map((item) => CommandsLink.fromJson(item)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load links')),
      );
    }
  }

  Future<void> _fetchDevices() async {
    final token = Provider.of<AppState>(context, listen: false).token;
    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/devices/get/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _devices = data.map((item) => Device.fromJson(item)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load devices')),
      );
    }
  }

  Future<void> _createLink() async {
    final token = Provider.of<AppState>(context, listen: false).token;
    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/api/commands-links/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'triggers': _triggers,
        'results': _results,
        'ttl': _ttl,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link created successfully')),
      );
      _fetchLinks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Links')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ..._links.map((link) => _buildLinkCard(link)),
            _buildCreateLinkForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(CommandsLink link) {
    return Card(
      child: ListTile(
        title: Text('Link ID: ${link.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Triggers: ${link.triggers.length}'),
            Text('Results: ${link.results.length}'),
            if (link.ttl != null) Text('TTL: ${link.ttl}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateLinkForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create New Link'),
            SizedBox(height: 16),
            Text('Triggers:'),
            ..._buildTriggersList(),
            ElevatedButton(
              onPressed: _addTrigger,
              child: Text('Add Trigger'),
            ),
            SizedBox(height: 16),
            Text('Results:'),
            ..._buildResultsList(),
            ElevatedButton(
              onPressed: _addResult,
              child: Text('Add Result'),
            ),
            SizedBox(height: 16),
            if (_triggers.length > 1)
              Row(
                children: [
                  Text('TTL:'),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: 'e.g., 1 00:00:00 for 1 day',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _ttl = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createLink,
              child: Text('Create Link'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTriggersList() {
    return _triggers.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> trigger = entry.value;
      return _buildTriggerItem(index, trigger);
    }).toList();
  }

  Widget _buildTriggerItem(int index, Map<String, dynamic> trigger) {
    int deviceIndex = _devices.indexWhere((d) => d.id == trigger['device_id']);
    Device? selectedDevice = deviceIndex != -1 ? _devices[deviceIndex] : null;
    List<dynamic> components = selectedDevice?.data?['components'] ?? [];

    return Row(
      children: [
        Expanded(
          child: DropdownButton<int>(
            value: trigger['device_id'],
            items: _devices.map((Device device) {
              return DropdownMenuItem<int>(
                value: device.id,
                child: Text(device.name),
              );
            }).toList(),
            onChanged: (int? deviceId) {
              setState(() {
                _triggers[index]['device_id'] = deviceId;
                _triggers[index]['component_name'] = null;
                _triggers[index]['action'] = null;
              });
            },
          ),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: trigger['component_name'],
            items: components.map<DropdownMenuItem<String>>((component) {
              return DropdownMenuItem<String>(
                value: component['name'] is String ? component['name'] : null,
                child: Text(component['name']?.toString() ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (String? componentName) {
              setState(() {
                _triggers[index]['component_name'] = componentName;
                _triggers[index]['action'] = null;
              });
            },
          ),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: trigger['action'],
            items: selectedDevice?.data?['components'] != null
                ? (selectedDevice!.data!['components'] as List).indexWhere(
                            (c) => c['name'] == trigger['component_name']) !=
                        -1
                    ? (selectedDevice.data!['components'] as List)[
                                (selectedDevice.data!['components'] as List)
                                    .indexWhere((c) =>
                                        c['name'] == trigger['component_name'])]
                            ['actions']
                        .map<DropdownMenuItem<String>>((action) {
                        return DropdownMenuItem<String>(
                          value: action is String ? action : null,
                          child: Text(action?.toString() ?? 'Unknown'),
                        );
                      }).toList()
                    : []
                : [],
            onChanged: (String? action) {
              setState(() {
                _triggers[index]['action'] = action;
              });
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _triggers.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  List<Widget> _buildResultsList() {
    return _results.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> result = entry.value;
      return _buildResultItem(index, result);
    }).toList();
  }

  Widget _buildResultItem(int index, Map<String, dynamic> result) {
    int deviceIndex = _devices.indexWhere((d) => d.id == result['device_id']);
    Device? selectedDevice = deviceIndex != -1 ? _devices[deviceIndex] : null;

    List<Map<String, dynamic>> components = [];
    if (selectedDevice != null &&
        selectedDevice.data != null &&
        selectedDevice.data!['components'] is List) {
      components =
          List<Map<String, dynamic>>.from(selectedDevice.data!['components']);
    }

    List<String> actions = [];
    if (result['data'] != null && result['data']['name'] != null) {
      int componentIndex =
          components.indexWhere((c) => c['name'] == result['data']['name']);
      if (componentIndex != -1 &&
          components[componentIndex]['actions'] is List) {
        actions = List<String>.from(components[componentIndex]['actions']);
      }
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButton<int>(
            value: result['device_id'],
            items: _devices.map((Device device) {
              return DropdownMenuItem<int>(
                value: device.id,
                child: Text(device.name),
              );
            }).toList(),
            onChanged: (int? deviceId) {
              setState(() {
                result['device_id'] = deviceId;
                result['data'] = {};
              });
            },
          ),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: result['data']?['name'] as String?,
            items: components.map<DropdownMenuItem<String>>((component) {
              return DropdownMenuItem<String>(
                value: component['name'] as String?,
                child: Text(component['name']?.toString() ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (String? componentName) {
              setState(() {
                if (result['data'] == null) {
                  result['data'] = {};
                }
                result['data']['name'] = componentName;
                result['data']['action'] = null;
              });
            },
          ),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: result['data']?['action'] as String?,
            items: actions.map<DropdownMenuItem<String>>((action) {
              return DropdownMenuItem<String>(
                value: action,
                child: Text(action),
              );
            }).toList(),
            onChanged: (String? action) {
              setState(() {
                if (result['data'] == null) {
                  result['data'] = {};
                }
                result['data']['action'] = action;
              });
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _results.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  void _addTrigger() {
    setState(() {
      _triggers.add({
        'device_id': null,
        'component_name': null,
        'action': null,
        'satisfied_at': null,
      });
    });
  }

  void _addResult() {
    setState(() {
      _results.add({
        'device_id': null,
        'data': {'name': null, 'action': null},
      });
    });
  }
}

class CommandsLink {
  final int id;
  final List<Map<String, dynamic>> triggers;
  final List<Map<String, dynamic>> results;
  final String? ttl;
  final DateTime? startedAt;

  CommandsLink({
    required this.id,
    required this.triggers,
    required this.results,
    this.ttl,
    this.startedAt,
  });

  factory CommandsLink.fromJson(Map<String, dynamic> json) {
    return CommandsLink(
      id: json['id'],
      triggers: List<Map<String, dynamic>>.from(json['triggers']),
      results: List<Map<String, dynamic>>.from(json['results']),
      ttl: json['ttl']?.toString(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
    );
  }
}
