import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _logout() async {
    const storage = FlutterSecureStorage();

    try {
      // Safely delete stored credentials
      final username = await storage.read(key: "username");
      final password = await storage.read(key: "password");

      if (username != null) {
        await storage.delete(key: "username");
      }

      if (password != null) {
        await storage.delete(key: "password");
      }

      // Ensure the widget is still mounted before using the context
      if (!mounted) return;

      // Clear the AppState (remove user data)
      final appState = context.read<AppState>();
      appState.setUsername(""); // Clear username
      appState.setToken("");    // Clear token

      // Navigate back to the login page using the named route
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Log any error that happens during logout
      print('Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AppState>().username;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Log out button
              SizedBox(
                width: double.infinity,  // Button takes full width
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 32.0),
                    backgroundColor: Colors.blue,  // Custom button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),  // Rounded corners
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
