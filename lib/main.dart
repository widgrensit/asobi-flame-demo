import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AsobiArenaApp());
}

class AsobiArenaApp extends StatelessWidget {
  const AsobiArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asobi Arena Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A26),
      ),
      home: const LoginScreen(),
    );
  }
}
