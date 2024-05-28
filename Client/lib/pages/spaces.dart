import 'package:flutter/material.dart';
import 'package:inzynierka_client/classes/device.dart';
import 'package:inzynierka_client/pages/device_details.dart';

class SpacesPage extends StatefulWidget {
  const SpacesPage({super.key});

  @override
  SpacesPageState createState() => SpacesPageState();
}

class SpacesPageState extends State<SpacesPage> {
  late Future<Map<String, List<Device>>> _spacesFuture;
  Map<String, List<Device>> _spaces = {};

  @override
  void initState() {
    super.initState();
    _spacesFuture = fetchSpacesWithDevices();
  }

  Future<Map<String, List<Device>>> fetchSpacesWithDevices() async {
    await Future.delayed(const Duration(seconds: 1));
    _spaces = {
      'Przestrzeń 1': [
        Device(name: 'Urządzenie 1A'),
        Device(name: 'Urządzenie 1B')
      ],
      'Przestrzeń 2': [
        Device(name: 'Urządzenie 2A'),
        Device(name: 'Urządzenie 2B')
      ],
      'Przestrzeń 3': [
        Device(name: 'Urządzenie 3A'),
        Device(name: 'Urządzenie 3B')
      ],
    };
    return _spaces;
  }

  void updateDevice(String spaceName, Device updatedDevice) {
    setState(() {
      final spaceDevices = _spaces[spaceName];
      if (spaceDevices != null) {
        final index = spaceDevices
            .indexWhere((device) => device.oldName == updatedDevice.oldName);
        if (index != -1) {
          spaceDevices[index] = updatedDevice;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Przestrzenie'),
      ),
      body: FutureBuilder<Map<String, List<Device>>>(
        future: _spacesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Błąd wczytywania danych'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak dostępnych przestrzeni'));
          }

          final spaces = snapshot.data!;
          return ListView(
            children: spaces.entries.map((entry) {
              return ExpansionTile(
                title: Text(entry.key),
                children: entry.value.map((device) {
                  return ListTile(
                    title: Text(device.name),
                    onTap: () async {
                      final updatedDevice = await Navigator.push<Device>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeviceDetailPage(
                            spaceName: entry.key,
                            device: device
                                .copyWith(), // Create a copy to avoid mutating the original directly
                          ),
                        ),
                      );
                      if (updatedDevice != null) {
                        updateDevice(entry.key, updatedDevice);
                      }
                    },
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
