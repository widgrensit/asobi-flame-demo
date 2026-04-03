import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  runApp(const AsobiArenaApp());
}

class AsobiArenaApp extends StatelessWidget {
  const AsobiArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asobi Arena',
      debugShowCheckedModeBanner: false,
      theme: NavalTheme.themeData,
      home: const LoginScreen(),
    );
  }
}
