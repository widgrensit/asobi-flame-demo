import 'dart:async';
import 'package:flutter/material.dart';
import '../game_config.dart';
import 'arena_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String _status = 'Connecting...';
  bool _searching = false;
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
      if (mounted) setState(() => _status = 'Connected! Ready to play.');
    });
    _matchedSub = rt.onMatchmakerMatched.stream.listen((_) {
      _searching = false;
      _timer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ArenaScreen()));
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
      _status = 'Searching for match...';
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _searchTime++;
          _status = 'Searching for match... ${_searchTime.toInt()}s';
        });
      }
    });
    GameConfig.client.realtime.addToMatchmaker(mode: GameConfig.gameMode);
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      _searching = false;
      _status = 'Connected! Ready to play.';
    });
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Player: ${GameConfig.client.playerId ?? ""}',
                style: const TextStyle(color: Colors.grey, fontSize: 18)),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            if (!_searching)
              ElevatedButton(
                onPressed: _findMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(250, 60),
                ),
                child: const Text('FIND MATCH', style: TextStyle(fontSize: 20)),
              ),
            if (_searching)
              ElevatedButton(
                onPressed: _cancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(250, 60),
                ),
                child: const Text('CANCEL', style: TextStyle(fontSize: 20)),
              ),
          ],
        ),
      ),
    );
  }
}
