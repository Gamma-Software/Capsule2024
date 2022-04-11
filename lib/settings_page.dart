import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      title: 'Shared preferences',
      home: const SettingsPage(title: 'Shared preferences'),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _SettingsPage createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  final SettingsHandler _settingsHandler = SettingsHandler();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Parametres'),
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
            Widget>[
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                obscureText: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Utilisateur',
                ),
                initialValue: _settingsHandler._user,
                onChanged: (String user) {
                  setState(() {
                    _settingsHandler._user = user;
                  });
                  _settingsHandler._saveParams();
                },
              )),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mot de passe',
                ),
                initialValue: _settingsHandler._pass,
                onChanged: (String pass) {
                  setState(() {
                    _settingsHandler._pass = pass;
                  });
                  _settingsHandler._saveParams();
                },
              )),
          Center(
            child: FloatingActionButton.extended(
              label: const Text('Save'), // <-- Text
              backgroundColor: Colors.white,
              onPressed: () {
                _settingsHandler._saveParams();
                // return to previous page
                Navigator.pop(context);
              },
            ),
          ),
        ]));
  }
}

class SettingsHandler {
  String _user = "";
  String _pass = "";

  // Initializing class
  SettingsHandler() {
    _loadParams();
  }

  //Loading counter value on start
  void _loadParams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _user = prefs.getString('user') ?? "";
    _pass = prefs.getString('pass') ?? "";
  }

  //Incrementing counter after click
  void _saveParams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user', _user);
    prefs.setString('pass', _pass);
  }
}
