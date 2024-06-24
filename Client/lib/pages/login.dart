import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';
import 'package:inzynierka_client/state/state.dart';
import 'package:inzynierka_client/pages/home.dart';

enum FormType { login, register }

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String username = '';
  String password = '';
  String confirmPassword = '';
  FormType currentForm = FormType.login;

  void switchForm() {
    setState(() {
      currentForm =
          currentForm == FormType.login ? FormType.register : FormType.login;
    });
  }

  void _login() async {
    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/login/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      context.read<AppState>().setUsername(username);
      context
          .read<AppState>()
          .setToken(json.decoder.convert(response.body)['token']);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } else {
      throw Exception('Failed to log in.');
    }
  }

  void _register() async {
    if (password != confirmPassword) {
      throw Exception('Passwords do not match.');
    }

    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/register/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );
    if (response.statusCode == 201) {
      context.read<AppState>().setUsername(username);
      _login();
    } else {
      throw Exception('Failed to register.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login to your account!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
              onChanged: (value) {
                setState(() {
                  username = value;
                });
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
            ),
            if (currentForm == FormType.register) ...[
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    confirmPassword = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (currentForm == FormType.login) {
                  _login();
                } else {
                  _register();
                }
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: switchForm,
              child: Text(currentForm == FormType.login ? 'Register' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }
}
