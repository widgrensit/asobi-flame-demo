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
    with KeyboardEvents, MouseMovementDetector, TapCallbacks {
  final void Function(Map<String, dynamic> result) onMatchFinished;
  final void Function(Map<String, dynamic> payload)? onBoonPick;
  final void Function(Map<String, dynamic> payload)? onVoteStart;
  final void Function(Map<String, dynamic> payload)? onVoteTally;
  final void Function(Map<String, dynamic> payload)? onVoteResult;

  late final AsobiInputSender _input;
  late final AsobiNetworkSync _sync;
  late final TextComponent _timerText;
  late final TextComponent _killsText;
  late final TextComponent _hpText;
  late final TextComponent _roundText;
  late final TextComponent _boonsText;

  // Vote event subscriptions (installed SDK may not dispatch these yet)
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
  Future<void> onLoad() async {
    final worldW = arenaWidth / ppu;
    final worldH = arenaHeight / ppu;

    camera.viewfinder.position = Vector2(worldW / 2, worldH / 2);
    camera.viewfinder.zoom = size.y / (worldH + 1);

    // Ocean background
    world.add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(worldW, worldH),
      paint: Paint()..color = NavalTheme.background,
    ));

    // Arena border
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
      playerBuilder: (playerId, isLocal) {
        return ShipPlayerComponent(playerId: playerId, isLocal: isLocal);
      },
      projectileBuilder: (id, owner, isLocal) {
        return CannonballComponent(
            projectileId: id, owner: owner, isLocal: isLocal);
      },
      onStateUpdate: _onStateUpdate,
      onMatchFinished: (result) => onMatchFinished(result),
    );
    world.add(_sync);

    _input = AsobiInputSender(
      client: GameConfig.client,
      pixelsPerUnit: ppu,
    );
    world.add(_input);

    // Subscribe to vote events if available on the realtime client.
    // The installed asobi-dart SDK may not dispatch these yet.
    _subscribeVoteEvents();

    // HUD elements
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
    // TODO: update asobi-dart SDK to dispatch vote events.
    // When the SDK is updated, these subscriptions will fire.
    try {
      final rt = GameConfig.client.realtime;
      // Use dynamic access since the installed SDK may not have these
      // stream controllers. This is a forward-compatible pattern.
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
      // Installed SDK version doesn't support vote events yet
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
    _input.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    _input.updateMousePosition(
        camera.viewfinder.globalToLocal(info.eventPosition.global));
  }

  @override
  void onTapDown(TapDownEvent event) {
    _input.setMouseDown(true);
    _input.updateMousePosition(
        camera.viewfinder.globalToLocal(event.canvasPosition));
  }

  @override
  void onTapUp(TapUpEvent event) {
    _input.setMouseDown(false);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _input.setMouseDown(false);
  }

  bool _boonPickTriggered = false;

  void _onStateUpdate(Map<String, dynamic> state) {
    final remainingMs =
        (state['time_remaining'] as num?)?.toDouble() ?? _sync.timeRemainingMs;
    final remainingS = (remainingMs / 1000).toInt();
    _timerText.text =
        '${remainingS ~/ 60}:${(remainingS % 60).toString().padLeft(2, '0')}';

    final local = _sync.localPlayer;
    if (local != null) {
      _killsText.text = 'Kills: ${local.kills}';
      _hpText.text = 'HP: ${local.hp}';
    }

    _roundText.text = _roundLabel();
    _boonsText.text = _boonsLabel();

    // Detect boon_pick phase from raw server state
    final phase = state['phase'] as String?;
    if (phase == 'boon_pick' && !_boonPickTriggered) {
      _boonPickTriggered = true;
      onBoonPick?.call(state);
    }
  }

  void sendBoonPick(String boonId) {
    GameConfig.client.realtime
        .sendMatchInput({'type': 'boon_pick', 'boon_id': boonId});
  }

  void castVote(String voteId, String optionId) {
    // Use sendMatchInput for vote since castVote may not be available
    GameConfig.client.realtime.sendMatchInput(
        {'type': 'vote', 'vote_id': voteId, 'option_id': optionId});
  }
}
