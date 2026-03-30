import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show TextStyle;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flame_asobi/flame_asobi.dart';
import '../game_config.dart';

const double arenaWidth = 800;
const double arenaHeight = 600;
const double ppu = 50;

class ArenaGame extends FlameGame with KeyboardEvents, MouseMovementDetector, TapCallbacks {
  final void Function(Map<String, dynamic> result) onMatchFinished;

  late final AsobiInputSender _input;
  late final AsobiNetworkSync _sync;
  late final TextComponent _timerText;
  late final TextComponent _killsText;
  late final TextComponent _hpText;

  ArenaGame({required this.onMatchFinished});

  @override
  Future<void> onLoad() async {
    final worldW = arenaWidth / ppu;
    final worldH = arenaHeight / ppu;

    // Camera
    camera.viewfinder.position = Vector2(worldW / 2, worldH / 2);
    camera.viewfinder.zoom = size.y / (worldH + 1);

    // Arena bounds
    world.add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(worldW, worldH),
      paint: Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.04,
    ));

    // Network sync — handles all player/projectile components
    _sync = AsobiNetworkSync(
      client: GameConfig.client,
      pixelsPerUnit: ppu,
      onStateUpdate: _onStateUpdate,
      onMatchFinished: (payload) => onMatchFinished(payload),
    );
    world.add(_sync);

    // Input sender — captures WASD + mouse and sends to server
    _input = AsobiInputSender(
      client: GameConfig.client,
      pixelsPerUnit: ppu,
    );
    world.add(_input);

    // HUD
    _timerText = TextComponent(
      text: '1:30',
      position: Vector2(10, 10),
      textRenderer: TextPaint(style: TextStyle(fontSize: 24, color: const Color(0xFFFFFFFF))),
    );
    _killsText = TextComponent(
      text: 'Kills: 0',
      position: Vector2(size.x - 10, 10),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(style: TextStyle(fontSize: 20, color: const Color(0xFFFFFFFF))),
    );
    _hpText = TextComponent(
      text: 'HP: 100',
      position: Vector2(size.x - 10, 35),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(style: TextStyle(fontSize: 20, color: const Color(0xFFFFFFFF))),
    );
    camera.viewport.addAll([_timerText, _killsText, _hpText]);
  }

  // -- Input forwarding to AsobiInputSender --

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _input.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    _input.updateMousePosition(camera.viewfinder.globalToLocal(info.eventPosition.global));
  }

  @override
  void onTapDown(TapDownEvent event) {
    _input.setMouseDown(true);
    _input.updateMousePosition(camera.viewfinder.globalToLocal(event.canvasPosition));
  }

  @override
  void onTapUp(TapUpEvent event) {
    _input.setMouseDown(false);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _input.setMouseDown(false);
  }

  // -- HUD update from network sync --

  void _onStateUpdate(Map<String, dynamic> state) {
    // Timer
    final remainingMs = _sync.timeRemainingMs;
    final remainingS = (remainingMs / 1000).toInt();
    _timerText.text = '${remainingS ~/ 60}:${(remainingS % 60).toString().padLeft(2, '0')}';

    // Local player stats
    final local = _sync.localPlayer;
    if (local != null) {
      _killsText.text = 'Kills: ${local.kills}';
      _hpText.text = 'HP: ${local.hp}';
    }
  }
}
