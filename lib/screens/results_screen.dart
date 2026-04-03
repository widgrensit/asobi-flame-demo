import 'dart:async';
import 'package:flutter/material.dart';
import '../game_config.dart';
import '../theme.dart';
import 'lobby_screen.dart';
import 'login_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _leaderboardText = 'Loading leaderboard...';
  int _autoQueueSeconds = 3;
  Timer? _autoQueueTimer;

  @override
  void initState() {
    super.initState();
    _submitAndFetch();
    _startAutoQueue();
  }

  void _startAutoQueue() {
    _autoQueueTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _autoQueueSeconds--);
        if (_autoQueueSeconds <= 0) {
          _autoQueueTimer?.cancel();
          _goToLobby();
        }
      }
    });
  }

  void _goToLobby() {
    GameConfig.currentRound++;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LobbyScreen()),
      );
    }
  }

  Future<void> _submitAndFetch() async {
    final result = GameConfig.matchResult;
    if (result == null) return;

    final myId = GameConfig.client.playerId ?? '';
    final players = result['players'] as Map<String, dynamic>? ?? {};
    final myData = players[myId] as Map<String, dynamic>?;
    final myKills = (myData?['kills'] as num?)?.toInt() ?? 0;

    try {
      await GameConfig.client.leaderboards.submitScore(
          GameConfig.leaderboardId, myKills);
      final entries = await GameConfig.client.leaderboards.getTop(
          GameConfig.leaderboardId, limit: 10);

      final lines = <String>['--- TOP 10 ---'];
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        final marker = e.playerId == myId ? ' *' : '';
        lines.add(
            '${i + 1}. ${e.playerId.substring(0, 12)} - ${e.score} kills$marker');
      }
      if (mounted) setState(() => _leaderboardText = lines.join('\n'));
    } catch (e) {
      if (mounted) {
        setState(() => _leaderboardText = 'Failed to load leaderboard: $e');
      }
    }
  }

  @override
  void dispose() {
    _autoQueueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = GameConfig.matchResult ?? {};
    final myId = GameConfig.client.playerId ?? '';
    final winnerId = result['winner_id'] as String? ?? '';
    final isVictory = winnerId == myId;
    final players = result['players'] as Map<String, dynamic>? ?? {};

    final sortedEntries = players.entries.toList()
      ..sort((a, b) {
        final aKills =
            ((a.value as Map<String, dynamic>)['kills'] as num?)?.toInt() ?? 0;
        final bKills =
            ((b.value as Map<String, dynamic>)['kills'] as num?)?.toInt() ?? 0;
        return bKills.compareTo(aKills);
      });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVictory ? 'VICTORY!' : 'DEFEAT',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: isVictory ? NavalTheme.tertiary : NavalTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Round ${GameConfig.currentRound}',
              style: const TextStyle(fontSize: 18, color: NavalTheme.secondary),
            ),
            const SizedBox(height: 24),
            ...sortedEntries.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final pid = entry.value.key;
              final data = entry.value.value as Map<String, dynamic>;
              final kills = (data['kills'] as num?)?.toInt() ?? 0;
              final deaths = (data['deaths'] as num?)?.toInt() ?? 0;
              final isMe = pid == myId;
              final displayId = pid.length > 8 ? pid.substring(0, 8) : pid;
              final suffix = isMe ? ' (YOU)' : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '#$rank  $displayId$suffix  K:$kills D:$deaths',
                  style: TextStyle(
                    fontSize: 18,
                    color: isMe ? NavalTheme.primary : NavalTheme.text,
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text(
              _leaderboardText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: NavalTheme.textDim),
            ),
            const SizedBox(height: 20),
            Text(
              'Next round in ${_autoQueueSeconds}s...',
              style: const TextStyle(fontSize: 16, color: NavalTheme.secondary),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _goToLobby,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavalTheme.primary,
                    foregroundColor: NavalTheme.background,
                    minimumSize: const Size(160, 50),
                  ),
                  child: const Text('PLAY AGAIN'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    _autoQueueTimer?.cancel();
                    GameConfig.currentRound = 1;
                    GameConfig.activeBoons.clear();
                    GameConfig.currentModifier = '';
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavalTheme.error,
                    foregroundColor: NavalTheme.background,
                    minimumSize: const Size(160, 50),
                  ),
                  child: const Text('QUIT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
