import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_asobi/flame_asobi.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection;
import '../../theme.dart';

enum ShipDirection { down, left, right, up }

class ShipPlayerComponent extends PositionComponent with AsobiPlayer {
  static const int _cols = 3;
  static const double _frameW = 52;
  static const double _frameH = 53;
  static const double _animScale = 1.5;
  static const double _animSpeed = 0.15;

  late final Map<ShipDirection, List<Sprite>> _frames;
  ShipDirection _direction = ShipDirection.down;
  Vector2 _prevPosition = Vector2.zero();
  double _frameTimer = 0;
  int _frameIndex = 0;

  ShipPlayerComponent({
    required String playerId,
    required bool isLocal,
  }) : super(
          size: Vector2(
            _frameW * _animScale / 50,
            _frameH * _animScale / 50,
          ),
          anchor: Anchor.center,
          priority: 5,
        ) {
    initPlayer(id: playerId, local: isLocal);
  }

  @override
  Future<void> onLoad() async {
    final imageName = isLocal ? 'ship_player.png' : 'ship_enemy.png';
    final image = await Flame.images.load(imageName);
    _frames = {};
    for (final dir in ShipDirection.values) {
      final row = dir.index;
      _frames[dir] = List.generate(_cols, (col) {
        return Sprite(
          image,
          srcPosition: Vector2(col * _frameW, row * _frameH),
          srcSize: Vector2(_frameW, _frameH),
        );
      });
    }
    _prevPosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _frameTimer += dt;
    if (_frameTimer >= _animSpeed) {
      _frameTimer = 0;
      _frameIndex = (_frameIndex + 1) % _cols;
    }

    final dx = position.x - _prevPosition.x;
    final dy = position.y - _prevPosition.y;

    ShipDirection newDir;
    if (dx.abs() > dy.abs()) {
      newDir = dx > 0 ? ShipDirection.right : ShipDirection.left;
    } else if (dy.abs() > 0.001) {
      newDir = dy > 0 ? ShipDirection.down : ShipDirection.up;
    } else {
      newDir = _direction;
    }

    if (newDir != _direction) {
      _direction = newDir;
      _frameIndex = 0;
    }
    _prevPosition = position.clone();
  }

  @override
  void render(Canvas canvas) {
    if (_frames.isNotEmpty) {
      final sprite = _frames[_direction]![_frameIndex];
      sprite.render(canvas, size: size);
    }

    final barWidth = size.x;
    const barHeight = 0.06;
    const barY = -0.15;

    final fraction = hp / 100.0;
    final hpColor = NavalTheme.hpColor(fraction);

    canvas.drawRect(
      Rect.fromLTWH(0, barY, barWidth, barHeight),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, barY, barWidth * fraction.clamp(0.0, 1.0), barHeight),
      Paint()..color = hpColor,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 0.18,
          color: isLocal ? NavalTheme.primary : NavalTheme.text,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, barY - 0.2));
  }
}
