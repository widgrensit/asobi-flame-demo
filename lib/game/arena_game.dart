import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show TextStyle, TextPainter, TextSpan, TextDirection;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import '../game_config.dart';

const double arenaWidth = 800;
const double arenaHeight = 600;
const double ppu = 50; // pixels per unit

class ArenaGame extends FlameGame with KeyboardEvents, MouseMovementDetector, TapCallbacks {
  final void Function(Map<String, dynamic> result) onMatchFinished;

  final Map<String, _PlayerSprite> _players = {};
  final Map<int, CircleComponent> _projectiles = {};
  Map<String, dynamic> _latestState = {};
  Vector2 _mouseWorld = Vector2.zero();
  final Set<LogicalKeyboardKey> _keysPressed = {};
  bool _mouseDown = false;
  String _myId = '';

  // HUD
  late TextComponent _timerText;
  late TextComponent _killsText;
  late TextComponent _hpText;

  StreamSubscription? _stateSub;
  StreamSubscription? _finishSub;

  ArenaGame({required this.onMatchFinished});

  @override
  Future<void> onLoad() async {
    _myId = GameConfig.client.playerId ?? '';

    // Camera setup
    final worldW = arenaWidth / ppu;
    final worldH = arenaHeight / ppu;
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

    // Subscribe to match state
    final rt = GameConfig.client.realtime;
    _stateSub = rt.onMatchState.stream.listen((payload) {
      _latestState = payload;
    });
    _finishSub = rt.onMatchFinished.stream.listen((payload) {
      onMatchFinished(payload);
    });
  }

  @override
  void onRemove() {
    _stateSub?.cancel();
    _finishSub?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sendInput();
    if (_latestState.isNotEmpty) {
      _updatePlayers();
      _updateProjectiles();
      _updateHud();
    }
  }

  // -- Input --

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed.clear();
    _keysPressed.addAll(keysPressed);
    return KeyEventResult.handled;
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    _mouseWorld = camera.viewfinder.globalToLocal(info.eventPosition.global);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _mouseDown = true;
    _mouseWorld = camera.viewfinder.globalToLocal(event.canvasPosition);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _mouseDown = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _mouseDown = false;
  }

  void _sendInput() {
    final up = _keysPressed.contains(LogicalKeyboardKey.keyW);
    final down = _keysPressed.contains(LogicalKeyboardKey.keyS);
    final left = _keysPressed.contains(LogicalKeyboardKey.keyA);
    final right = _keysPressed.contains(LogicalKeyboardKey.keyD);
    final shoot = _mouseDown || _keysPressed.contains(LogicalKeyboardKey.space);

    if (!(up || down || left || right || shoot)) return;

    GameConfig.client.realtime.sendMatchInput({
      'up': up,
      'down': down,
      'left': left,
      'right': right,
      'shoot': shoot,
      'aim_x': _mouseWorld.x * ppu,
      'aim_y': _mouseWorld.y * ppu,
    });
  }

  // -- Players --

  void _updatePlayers() {
    final players = _latestState['players'] as Map<String, dynamic>? ?? {};
    final seenIds = <String>{};

    for (final entry in players.entries) {
      final pid = entry.key;
      final data = entry.value as Map<String, dynamic>;
      seenIds.add(pid);

      final targetPos = Vector2(
        (data['x'] as num).toDouble() / ppu,
        (data['y'] as num).toDouble() / ppu,
      );
      final hp = (data['hp'] as num?)?.toInt() ?? 0;
      final kills = (data['kills'] as num?)?.toInt() ?? 0;
      final isMe = pid == _myId;

      if (!_players.containsKey(pid)) {
        final sprite = _PlayerSprite(isMe: isMe, label: isMe ? 'YOU' : pid.substring(0, 8));
        _players[pid] = sprite;
        world.add(sprite);
      }

      final sprite = _players[pid]!;
      sprite.position.lerp(targetPos, 0.3);
      sprite.hp = hp;
      if (hp <= 0) {
        sprite.color = const Color(0xFF888888);
      } else if (isMe) {
        sprite.color = const Color(0xFF00FFFF);
      } else {
        sprite.color = const Color(0xFFFF4444);
      }

      if (isMe) {
        _killsText.text = 'Kills: $kills';
        _hpText.text = 'HP: $hp';
      }
    }

    for (final pid in _players.keys.toList()) {
      if (!seenIds.contains(pid)) {
        _players[pid]!.removeFromParent();
        _players.remove(pid);
      }
    }
  }

  // -- Projectiles --

  void _updateProjectiles() {
    final projectiles = _latestState['projectiles'] as List<dynamic>? ?? [];
    final seenIds = <int>{};

    for (final proj in projectiles) {
      final data = proj as Map<String, dynamic>;
      final id = (data['id'] as num).toInt();
      final owner = data['owner'] as String? ?? '';
      seenIds.add(id);

      final pos = Vector2(
        (data['x'] as num).toDouble() / ppu,
        (data['y'] as num).toDouble() / ppu,
      );

      if (!_projectiles.containsKey(id)) {
        final color = owner == _myId ? const Color(0xFFFFFF00) : const Color(0xFFFFFFFF);
        final circle = CircleComponent(
          radius: 0.15,
          paint: Paint()..color = color,
          position: pos,
          anchor: Anchor.center,
          priority: 3,
        );
        _projectiles[id] = circle;
        world.add(circle);
      } else {
        _projectiles[id]!.position.setFrom(pos);
      }
    }

    for (final id in _projectiles.keys.toList()) {
      if (!seenIds.contains(id)) {
        _projectiles[id]!.removeFromParent();
        _projectiles.remove(id);
      }
    }
  }

  // -- HUD --

  void _updateHud() {
    final remainingMs = (_latestState['time_remaining'] as num?)?.toDouble() ?? 0;
    final remainingS = (remainingMs / 1000).toInt();
    final minutes = remainingS ~/ 60;
    final seconds = remainingS % 60;
    _timerText.text = '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _PlayerSprite extends PositionComponent {
  final bool isMe;
  final String label;
  Color color;
  int hp = 100;

  _PlayerSprite({required this.isMe, required this.label})
      : color = isMe ? const Color(0xFF00FFFF) : const Color(0xFFFF4444),
        super(
          size: Vector2(0.64, 0.64),
          anchor: Anchor.center,
          priority: 5,
        );

  @override
  void render(Canvas canvas) {
    // Body circle
    final bodyPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, bodyPaint);

    // HP bar background
    final hpBgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, size.y + 0.05, size.x, 0.08), hpBgPaint);

    // HP bar
    final hpPaint = Paint()..color = const Color(0xFF00FF00);
    final hpWidth = size.x * (hp / 100).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(0, size.y + 0.05, hpWidth, 0.08), hpPaint);

    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: 1.4, color: const Color(0xFFFFFFFF)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset((size.x - labelPainter.width) / 2, -1.6));
  }
}
