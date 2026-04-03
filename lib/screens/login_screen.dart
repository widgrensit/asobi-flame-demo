import 'package:flutter/material.dart';
import '../game_config.dart';
import '../theme.dart';
import 'lobby_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _status = '';
  bool _busy = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _status = 'Enter username and password');
      return;
    }
    setState(() { _busy = true; _status = 'Logging in...'; });
    try {
      await GameConfig.client.auth.login(username, password);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LobbyScreen()));
      }
    } catch (e) {
      setState(() => _status = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _status = 'Enter username and password');
      return;
    }
    setState(() { _busy = true; _status = 'Registering...'; });
    try {
      await GameConfig.client.auth.register(username, password);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LobbyScreen()));
      }
    } catch (e) {
      setState(() => _status = 'Register failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: NavalTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: NavalTheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ASOBI ARENA',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: NavalTheme.primary,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Naval Combat',
                style: TextStyle(
                  fontSize: 16,
                  color: NavalTheme.secondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: NavalTheme.text),
                decoration: const InputDecoration(hintText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: NavalTheme.text),
                decoration: const InputDecoration(hintText: 'Password'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _busy ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NavalTheme.primary,
                      foregroundColor: NavalTheme.background,
                      minimumSize: const Size(130, 40),
                    ),
                    child: const Text('LOGIN'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _busy ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NavalTheme.tertiary,
                      foregroundColor: NavalTheme.background,
                      minimumSize: const Size(130, 40),
                    ),
                    child: const Text('REGISTER'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: const TextStyle(color: NavalTheme.error, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
