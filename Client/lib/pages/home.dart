import 'package:flutter/material.dart';
import 'package:inzynierka_client/chat.dart';
import 'package:inzynierka_client/pages/commands.dart';
import 'package:inzynierka_client/pages/create_space.dart';
import 'package:inzynierka_client/pages/profile_page.dart';
import 'package:inzynierka_client/pages/create_device.dart';
import 'package:inzynierka_client/pages/spaces.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    SpacesPage(),
    CommandsPage(),
    CreateSpacePage(),
    CreateDevicePage(spaceId: null),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, ${context.watch<AppState>().username}',
          style: const TextStyle(
            fontSize: 22, // Larger font size for the title
            fontWeight: FontWeight.bold, // Bold title text
            color: Colors.white, // White text color for better contrast
          ),
        ),
        backgroundColor: Colors.blueAccent, // Custom background color
        elevation: 2, // Add a slight shadow
        centerTitle: true, // Center the title
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Add functionality for notification icon
            },
            tooltip: 'Notifications', // Tooltip for accessibility
          ),
        ],
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Spaces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'All commands',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add space',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.on_device_training),
            label: 'Add Device',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blueAccent,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[400],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return const Dialog(
                  child: ChatDialog(),
                );
              });
        },
        backgroundColor: Colors.blueAccent, // Match FAB color to theme
        child: const Icon(Icons.chat),
      ),
    );
  }
}
