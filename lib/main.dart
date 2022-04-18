import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'page/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Capsule 2024',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: const MQTTClient(),
    );
  }
}
