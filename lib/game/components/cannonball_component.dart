import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_asobi/flame_asobi.dart';
import '../../theme.dart';

class CannonballComponent extends CircleComponent with AsobiProjectile {
  CannonballComponent({
    required int projectileId,
    required String owner,
    required bool isLocal,
  }) : super(radius: 0.1, anchor: Anchor.center, priority: 3) {
    initProjectile(id: projectileId, ownerId: owner, local: isLocal);
    paint = Paint()..color = isLocal ? NavalTheme.secondary : NavalTheme.error;
  }
}
