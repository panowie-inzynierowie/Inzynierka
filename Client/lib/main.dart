import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String apiUrl = "http://192.168.1.21:2137";
  List<dynamic> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
    Timer.periodic(Duration(seconds: 5), (Timer t) => _refreshDevices());
  }

  Future<void> _refreshDevices() async {
    var response = await http.get(Uri.parse("$apiUrl/devices"));
    setState(() {
      _devices = json.decode(response.body);
    });
  }

  Future<void> _toggleDevice(String id) async {
    setState(() {
      _isLoading = true;
    });
    var response = await http.post(Uri.parse("$apiUrl/device/$id"));
    if (response.statusCode == 200) {
      setState(() {
        _devices = json.decode(response.body);
      });
    } else {
      // obsługa błędów
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Sterowanie urządzeniami'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  var device = _devices[index];
                  return ListTile(
                    title: Text('Urządzenie ${device['id']}'),
                    trailing: IconButton(
                      icon: Icon(device['status'] == 'on' ? Icons.lightbulb : Icons.lightbulb_outline),
                      onPressed: () => _toggleDevice(device['id'].toString()),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
