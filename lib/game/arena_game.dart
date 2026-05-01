import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show TextStyle;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flame_asobi/flame_asobi.dart';
import '../game_config.dart';
import '../theme.dart';
import 'components/cannonball_component.dart';
import 'components/ship_player_component.dart';

const double arenaWidth = 800;
const double arenaHeight = 600;
const double ppu = 50;

class ArenaGame extends FlameGame
    with HasAsobiInput, KeyboardEvents, MouseMovementDetector, TapCallbacks {
  final void Function(Map<String, dynamic> result) onMatchFinished;
  final void Function(Map<String, dynamic> state)? onBoonPick;
  final void Function(Map<String, dynamic> payload)? onVoteStart;
  final void Function(Map<String, dynamic> payload)? onVoteTally;
  final void Function(Map<String, dynamic> payload)? onVoteResult;

  late final AsobiNetworkSync _sync;
  late final TextComponent _timerText;
  late final TextComponent _killsText;
  late final TextComponent _hpText;
  late final TextComponent _roundText;
  late final TextComponent _boonsText;

  StreamSubscription? _voteStartSub;
  StreamSubscription? _voteTallySub;
  StreamSubscription? _voteResultSub;

  ArenaGame({
    required this.onMatchFinished,
    this.onBoonPick,
    this.onVoteStart,
    this.onVoteTally,
    this.onVoteResult,
  });

  @override
  AsobiClient get inputClient => GameConfig.client;

  @override
  double get inputPixelsPerUnit => ppu;

  /// Arena uses boolean WASD flags + aim_x/aim_y (not the default
  /// move_x/move_y) — its match script reads those fields directly.
  @override
  Map<String, dynamic>? buildMatchInput({
    required Set<LogicalKeyboardKey> keysPressed,
    required Vector2 mouseWorld,
    required bool mouseDown,
  }) {
    final up = keysPressed.contains(keyUp);
    final down = keysPressed.contains(keyDown);
    final left = keysPressed.contains(keyLeft);
    final right = keysPressed.contains(keyRight);
    final shoot = mouseDown || keysPressed.contains(keyShoot);
    if (!(up || down || left || right || shoot)) {
      return null;
    }
    return {
      'up': up,
      'down': down,
      'left': left,
      'right': right,
      'shoot': shoot,
      'aim_x': mouseWorld.x * inputPixelsPerUnit,
      'aim_y': mouseWorld.y * inputPixelsPerUnit,
    };
  }

  @override
  Future<void> onLoad() async {
    final worldW = arenaWidth / ppu;
    final worldH = arenaHeight / ppu;

    camera.viewfinder.position = Vector2(worldW / 2, worldH / 2);
    camera.viewfinder.zoom = size.y / (worldH + 1);

    world.add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(worldW, worldH),
      paint: Paint()..color = NavalTheme.background,
    ));

    world.add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(worldW, worldH),
      paint: Paint()
        ..color = NavalTheme.primary.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.04,
    ));

    _sync = AsobiNetworkSync(
      client: GameConfig.client,
      pixelsPerUnit: ppu,
      playerBuilder: (playerId, {required isLocal}) =>
          ShipPlayerComponent(playerId: playerId, isLocal: isLocal),
      projectileBuilder: (id, owner, {required isLocal}) =>
          CannonballComponent(projectileId: id, owner: owner, isLocal: isLocal),
      onStateUpdate: _onStateUpdate,
      onMatchFinished: (result) => onMatchFinished(result.toJson()),
    );
    world.add(_sync);

    _subscribeVoteEvents();

    _timerText = TextComponent(
      text: '1:30',
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 24, color: NavalTheme.text),
      ),
    );
    _killsText = TextComponent(
      text: 'Kills: 0',
      position: Vector2(10, 40),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 18, color: NavalTheme.secondary),
      ),
    );
    _hpText = TextComponent(
      text: 'HP: 100',
      position: Vector2(10, 62),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 18, color: NavalTheme.tertiary),
      ),
    );
    _roundText = TextComponent(
      text: _roundLabel(),
      position: Vector2(size.x - 10, 10),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 18, color: NavalTheme.primary),
      ),
    );
    _boonsText = TextComponent(
      text: _boonsLabel(),
      position: Vector2(size.x / 2, size.y - 10),
      anchor: Anchor.bottomCenter,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 14, color: NavalTheme.textDim),
      ),
    );
    camera.viewport.addAll([
      _timerText,
      _killsText,
      _hpText,
      _roundText,
      _boonsText,
    ]);
  }

  void _subscribeVoteEvents() {
    try {
      final rt = GameConfig.client.realtime;
      final dyn = rt as dynamic;
      _voteStartSub =
          (dyn.onVoteStart as StreamController).stream.listen((p) {
        onVoteStart?.call(p as Map<String, dynamic>);
      });
      _voteTallySub =
          (dyn.onVoteTally as StreamController).stream.listen((p) {
        onVoteTally?.call(p as Map<String, dynamic>);
      });
      _voteResultSub =
          (dyn.onVoteResult as StreamController).stream.listen((p) {
        onVoteResult?.call(p as Map<String, dynamic>);
      });
    } catch (_) {
      // Installed SDK version doesn't dispatch vote events yet
    }
  }

  @override
  void onRemove() {
    _voteStartSub?.cancel();
    _voteTallySub?.cancel();
    _voteResultSub?.cancel();
    super.onRemove();
  }

  String _roundLabel() {
    final mod = GameConfig.currentModifier;
    return 'Round ${GameConfig.currentRound}${mod.isNotEmpty ? ' - $mod' : ''}';
  }

  String _boonsLabel() {
    if (GameConfig.activeBoons.isEmpty) return '';
    return GameConfig.activeBoons
        .map((b) => b['name'] as String? ?? '?')
        .join('  |  ');
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    handleKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    updateMousePosition(
        camera.viewfinder.globalToLocal(info.eventPosition.global));
  }

  @override
  void onTapDown(TapDownEvent event) {
    setMouseDown(down: true);
    updateMousePosition(camera.viewfinder.globalToLocal(event.canvasPosition));
  }

  @override
  void onTapUp(TapUpEvent event) => setMouseDown(down: false);

  @override
  void onTapCancel(TapCancelEvent event) => setMouseDown(down: false);

  bool _boonPickTriggered = false;

  void _onStateUpdate(MatchState state) {
    final remainingMs = state.timeRemaining;
    final remainingS = (remainingMs / 1000).toInt();
    _timerText.text =
        '${remainingS ~/ 60}:${(remainingS % 60).toString().padLeft(2, '0')}';

    final local = _sync.localPlayer;
    if (local is AsobiPlayer) {
      _killsText.text = 'Kills: ${local.kills}';
      _hpText.text = 'HP: ${local.hp}';
    }

    _roundText.text = _roundLabel();
    _boonsText.text = _boonsLabel();

    final phase = state.raw['phase'] as String?;
    if (phase == 'boon_pick' && !_boonPickTriggered) {
      _boonPickTriggered = true;
      onBoonPick?.call(state.raw);
    }
  }

  void sendBoonPick(String boonId) {
    GameConfig.client.realtime
        .sendMatchInput({'type': 'boon_pick', 'boon_id': boonId});
  }

  void castVote(String voteId, String optionId) {
    GameConfig.client.realtime.sendMatchInput(
        {'type': 'vote', 'vote_id': voteId, 'option_id': optionId});
  }
}
