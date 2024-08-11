import 'package:flutter/foundation.dart';

import 'package:inzynierka_client/classes/chat.dart';

class AppState with ChangeNotifier, DiagnosticableTreeMixin {
  String _username = '';
  String _token = '';
  List<ChatMessage> _messages = [
    ChatMessage(content: "Hello", author: Author.llm),
  ];

  String get token => _token;

  void setToken(token) {
    _token = token;
    notifyListeners();
  }

  String get username => _username;

  void setUsername(username) {
    _username = username;
    notifyListeners();
  }

  List<ChatMessage> get chatMessages => _messages;

  void setChatMessages(messages) {
    _messages = messages;
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('username', username));
  }
}
