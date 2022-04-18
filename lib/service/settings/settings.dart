import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  final String user;
  final String pass;

  Settings({required this.user, required this.pass});
}

class PreferencesService {
  Future saveSettings(Settings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('user', settings.user);
    await preferences.setString('pass', settings.pass);
  }

  Future<Settings> getSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final user = preferences.getString('user') ?? "";
    final pass = preferences.getString('pass') ?? "";
    return Settings(user: user, pass: pass);
  }
}
