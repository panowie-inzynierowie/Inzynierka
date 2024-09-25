import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:udp/udp.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:network_info_plus/network_info_plus.dart';

class CreateDevicePage extends StatefulWidget {
  final int? spaceId;

  const CreateDevicePage({required this.spaceId, Key? key}) : super(key: key);

  @override
  _CreateDevicePageState createState() => _CreateDevicePageState();
}

class _CreateDevicePageState extends State<CreateDevicePage> {
  List<WiFiAccessPoint> _homeLinkAps = [];
  List<WiFiAccessPoint> _allAps = [];
  bool _isConnectedToHomeLink = false;
  String? _selectedNetwork;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanWiFi();
  }

  Future<void> _scanWiFi() async {
    final results = await WiFiScan.instance.getScannedResults();
    setState(() {
      _homeLinkAps =
          results.where((ap) => ap.ssid.contains('HomeLink')).toList();
      _allAps = results;
    });
    _checkHomeLinkConnection();
  }

  Future<void> _checkHomeLinkConnection() async {
    final info = NetworkInfo();
    final wifiName = await info.getWifiName();
    setState(() {
      _isConnectedToHomeLink =
          wifiName != null && wifiName.contains('HomeLink');
      print(wifiName);
      print(_isConnectedToHomeLink);
    });
  }

  Future<void> _sendBroadcast() async {
    if (_selectedNetwork == null) return;
    print(Provider.of<AppState>(context, listen: false).username);
    final jsonPayload = {
      'wifi': {
        'ssid': _selectedNetwork,
        'password': _passwordController.text,
      },
      'server_url': dotenv.env['API_URL'],
      'username': Provider.of<AppState>(context, listen: false).username,
    };
    print(jsonPayload);
    final sender = await UDP.bind(Endpoint.any());
    final data = utf8.encode(jsonEncode(jsonPayload));
    final broadcastEndpoint = Endpoint.broadcast(port: Port(12345));

    await sender.send(data, broadcastEndpoint);
    sender.close();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Success! Device configuration sent.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Device')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isConnectedToHomeLink
            ? _buildNetworkSelection()
            : _buildHomeLinkInstructions(),
      ),
    );
  }

  Widget _buildHomeLinkInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
            'Please connect to a HomeLink network with password \'12345678\'. \n Networks found:'),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _homeLinkAps.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_homeLinkAps[index].ssid),
              trailing: const Icon(Icons.wifi),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _checkHomeLinkConnection,
          child: const Text('I\'ve connected'),
        ),
      ],
    );
  }

  Widget _buildNetworkSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select your home WiFi network:'),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _allAps.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_allAps[index].ssid),
              trailing: const Icon(Icons.wifi),
              onTap: () =>
                  setState(() => _selectedNetwork = _allAps[index].ssid),
              selected: _selectedNetwork == _allAps[index].ssid,
            ),
          ),
        ),
        if (_selectedNetwork != null) ...[
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'WiFi Password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _sendBroadcast,
            child: const Text('Configure Device'),
          ),
        ],
      ],
    );
  }
}
