import 'package:flutter/material.dart';
import '../game_config.dart';
import 'lobby_screen.dart';
import 'login_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _leaderboardText = 'Loading leaderboard...';

  @override
  void initState() {
    super.initState();
    _submitAndFetch();
  }

  Future<void> _submitAndFetch() async {
    final result = GameConfig.matchResult;
    final standings = result['standings'] as List<dynamic>? ?? [];
    final myId = GameConfig.client.playerId ?? '';

    // Find my kills
    var myKills = 0;
    for (final entry in standings) {
      final data = entry as Map<String, dynamic>;
      if (data['player_id'] == myId) {
        myKills = (data['kills'] as num?)?.toInt() ?? 0;
        break;
      }
    }

    try {
      await GameConfig.client.leaderboards.submitScore(
          GameConfig.leaderboardId, myKills);
      final entries = await GameConfig.client.leaderboards.getTop(
          GameConfig.leaderboardId, limit: 10);

      final lines = <String>['--- TOP 10 ---'];
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        final marker = e.playerId == myId ? ' *' : '';
        lines.add('${i + 1}. ${e.playerId.substring(0, 12)} - ${e.score} kills$marker');
      }
      if (mounted) setState(() => _leaderboardText = lines.join('\n'));
    } catch (e) {
      if (mounted) setState(() => _leaderboardText = 'Failed to load leaderboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = GameConfig.matchResult;
    final standings = result['standings'] as List<dynamic>? ?? [];
    final winner = result['winner'] as String? ?? '';
    final myId = GameConfig.client.playerId ?? '';
    final isVictory = winner == myId;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVictory ? 'VICTORY!' : 'DEFEAT',
              style: TextStyle(
                fontSize: 48,
                color: isVictory ? Colors.yellow : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Standings
            ...standings.map((entry) {
              final data = entry as Map<String, dynamic>;
              final pid = data['player_id'] as String? ?? '';
              final kills = (data['kills'] as num?)?.toInt() ?? 0;
              final deaths = (data['deaths'] as num?)?.toInt() ?? 0;
              final rank = (data['rank'] as num?)?.toInt() ?? 0;
              final suffix = pid == myId ? ' (YOU)' : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '#$rank  ${pid.substring(0, 12)}$suffix  K:$kills D:$deaths',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text(_leaderboardText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LobbyScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(160, 50),
                  ),
                  child: const Text('PLAY AGAIN'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.black,
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
