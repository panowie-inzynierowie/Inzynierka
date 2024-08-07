import 'package:flutter/material.dart';
import 'package:inzynierka_client/chat.dart';
import 'package:inzynierka_client/pages/commands.dart';
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
        title: Text('Hello ${context.watch<AppState>().username}'),
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
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
        child: const Icon(Icons.chat),
      ),
    );
  }
}
