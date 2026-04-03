import 'dart:ui';
import 'package:flame_asobi/flame_asobi.dart';
import '../../theme.dart';

class CannonballComponent extends AsobiProjectile {
  CannonballComponent({
    required super.projectileId,
    required super.owner,
    required super.isLocal,
  }) : super(radius: 0.1) {
    paint = Paint()
      ..color = isLocal ? NavalTheme.secondary : NavalTheme.error;
  }
}
