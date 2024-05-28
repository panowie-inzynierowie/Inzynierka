import 'package:flutter/foundation.dart';

class AppState with ChangeNotifier, DiagnosticableTreeMixin {
  String _username = '';

  String get username => _username;

  void setUsername(username) {
    _username = username;
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('username', username));
  }
}
