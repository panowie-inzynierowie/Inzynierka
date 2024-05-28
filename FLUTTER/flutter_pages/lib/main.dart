import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    SpacesPage(),
    CommandsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Przestrzenie',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Komendy',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class SpacesPage extends StatefulWidget {
  const SpacesPage({super.key});

  @override
  _SpacesPageState createState() => _SpacesPageState();
}

class _SpacesPageState extends State<SpacesPage> {
  late Future<Map<String, List<Device>>> _spacesFuture;
  Map<String, List<Device>> _spaces = {};

  @override
  void initState() {
    super.initState();
    _spacesFuture = fetchSpacesWithDevices();
  }

  Future<Map<String, List<Device>>> fetchSpacesWithDevices() async {
    await Future.delayed(Duration(seconds: 1));
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

class Device {
  String name;
  String description;
  String oldName;

  Device({required this.name, this.description = 'Opis urządzenia'})
      : oldName = name;

  Device copyWith({String? name, String? description}) {
    return Device(
      name: name ?? this.name,
      description: description ?? this.description,
    )..oldName = this.oldName;
  }
}

class DeviceDetailPage extends StatefulWidget {
  final String spaceName;
  final Device device;

  const DeviceDetailPage(
      {super.key, required this.spaceName, required this.device});

  @override
  _DeviceDetailPageState createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _descriptionController =
        TextEditingController(text: widget.device.description);
  }

  void _editDevice() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edytuj urządzenie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nazwa'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Opis'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  widget.device.name = _nameController.text;
                  widget.device.description = _descriptionController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Zatwierdź'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDevice() {
    // Tu można dodać logikę do usunięcia urządzenia z przestrzeni
    Navigator.of(context).pop(); // Just pop for now, implement logic as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Opis: ${widget.device.description}'),
            ElevatedButton(
              onPressed: _editDevice,
              child: const Text('Edytuj'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(widget.device.copyWith(
                  name: _nameController.text,
                  description: _descriptionController.text,
                ));
              },
              child: const Text('Usuń z przestrzeni'),
            ),
          ],
        ),
      ),
    );
  }
}

class CommandsPage extends StatelessWidget {
  const CommandsPage({super.key});

  Future<List<String>> fetchCommands() async {
    await Future.delayed(Duration(seconds: 1));
    return ['Komenda 1', 'Komenda 2', 'Komenda 3'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komendy'),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchCommands(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Błąd wczytywania danych'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak dostępnych komend'));
          }

          final commands = snapshot.data!;
          return ListView.builder(
            itemCount: commands.length,
            itemBuilder: (context, index) {
              final command = commands[index];
              return ListTile(
                title: Text(command),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommandDetailPage(commandName: command),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CommandDetailPage extends StatefulWidget {
  final String commandName;

  const CommandDetailPage({super.key, required this.commandName});

  @override
  _CommandDetailPageState createState() => _CommandDetailPageState();
}

class _CommandDetailPageState extends State<CommandDetailPage> {
  bool _isSwitched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.commandName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Szczegóły dla ${widget.commandName}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: _isSwitched,
                  onChanged: (bool value) {
                    setState(() {
                      _isSwitched = value;
                    });
                  },
                ),
                SizedBox(width: 10),
                Text(_isSwitched ? 'Wyłącz' : 'Włącz'),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Tu można dodać logikę do usunięcia komendy
              },
              child: const Text('Usuń'),
            ),
          ],
        ),
      ),
    );
  }
}
