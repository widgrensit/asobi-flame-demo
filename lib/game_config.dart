import 'package:flame_asobi/flame_asobi.dart';

class GameConfig {
  static const host = 'localhost';
  static const port = 8084;
  static const gameMode = 'arena';
  static const leaderboardId = 'arena_kills';

  static final client = AsobiClient(host, port: port);

  static Map<String, dynamic> matchResult = {};
}
