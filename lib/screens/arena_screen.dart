import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/arena_game.dart';
import '../game_config.dart';
import 'results_screen.dart';

class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: ArenaGame(
          onMatchFinished: (result) {
            GameConfig.matchResult = result;
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ResultsScreen()));
          },
        ),
      ),
    );
  }
}
