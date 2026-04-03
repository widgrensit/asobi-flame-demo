import 'dart:async';
import 'package:flutter/material.dart';
import '../game_config.dart';
import '../theme.dart';
import 'arena_screen.dart';
import 'overlays/countdown_overlay.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String _status = 'Connecting...';
  bool _searching = false;
  bool _countdown = false;
  double _searchTime = 0;
  Timer? _timer;
  StreamSubscription? _connectedSub;
  StreamSubscription? _matchedSub;
  StreamSubscription? _errorSub;

  @override
  void initState() {
    super.initState();
    _connectRealtime();
  }

  Future<void> _connectRealtime() async {
    final rt = GameConfig.client.realtime;
    _connectedSub = rt.onConnected.stream.listen((_) {
      if (mounted) setState(() => _status = 'Ready to deploy, Captain.');
    });
    _matchedSub = rt.onMatchmakerMatched.stream.listen((_) {
      _searching = false;
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _status = 'Match found!';
          _countdown = true;
        });
      }
    });
    _errorSub = rt.onError.stream.listen((err) {
      if (mounted) {
        setState(() {
          _status = 'Error: $err';
          _searching = false;
        });
        _timer?.cancel();
      }
    });
    await rt.connect();
  }

  void _findMatch() {
    setState(() {
      _searching = true;
      _searchTime = 0;
      _status = 'Searching for battle...';
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _searchTime++;
          _status = 'Searching for battle... ${_searchTime.toInt()}s';
        });
      }
    });
    GameConfig.client.realtime.addToMatchmaker(mode: GameConfig.gameMode);
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      _searching = false;
      _status = 'Ready to deploy, Captain.';
    });
  }

  void _onCountdownDone() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ArenaScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectedSub?.cancel();
    _matchedSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FLEET COMMAND',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: NavalTheme.primary,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Captain: ${GameConfig.client.playerId?.substring(0, 12) ?? ""}',
                  style: const TextStyle(color: NavalTheme.textDim, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (GameConfig.currentRound > 1)
                  Text(
                    'Round ${GameConfig.currentRound}',
                    style: const TextStyle(
                      color: NavalTheme.secondary,
                      fontSize: 18,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 22, color: NavalTheme.text),
                ),
                const SizedBox(height: 30),
                if (!_searching && !_countdown)
                  ElevatedButton(
                    onPressed: _findMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NavalTheme.primary,
                      foregroundColor: NavalTheme.background,
                      minimumSize: const Size(250, 60),
                    ),
                    child: const Text('SET SAIL', style: TextStyle(fontSize: 20)),
                  ),
                if (_searching)
                  ElevatedButton(
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NavalTheme.error,
                      foregroundColor: NavalTheme.background,
                      minimumSize: const Size(250, 60),
                    ),
                    child: const Text('RETREAT', style: TextStyle(fontSize: 20)),
                  ),
              ],
            ),
          ),
          if (_countdown)
            CountdownOverlay(onComplete: _onCountdownDone),
        ],
      ),
    );
  }
}
