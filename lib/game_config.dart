import 'package:flame_asobi/flame_asobi.dart';

class GameConfig {
  static const host = 'localhost';
  static const port = 8085;
  static const gameMode = 'arena';
  static const leaderboardId = 'arena_kills';

  static final client = AsobiClient(host, port: port);

  static Map<String, dynamic>? matchResult;
  static int currentRound = 1;
  static String currentModifier = '';
  static List<Map<String, dynamic>> activeBoons = [];
}
