import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/arena_game.dart';
import '../game_config.dart';
import 'overlays/boon_pick_overlay.dart';
import 'overlays/vote_overlay.dart';
import 'results_screen.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final ArenaGame _game;

  bool _showBoonPick = false;
  List<Map<String, dynamic>> _boonOffers = [];
  List<String> _picksDone = [];
  double _boonTimeRemaining = 0;

  bool _showVote = false;
  String _voteId = '';
  List<Map<String, dynamic>> _voteOptions = [];
  double _voteWindowMs = 0;
  String _voteMethod = '';
  final GlobalKey<VoteOverlayState> _voteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _game = ArenaGame(
      onMatchFinished: _onMatchFinished,
      onBoonPick: _onBoonPick,
      onVoteStart: _onVoteStart,
      onVoteTally: _onVoteTally,
      onVoteResult: _onVoteResult,
    );
  }

  void _onMatchFinished(Map<String, dynamic> result) {
    GameConfig.matchResult = result;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
    }
  }

  void _onBoonPick(Map<String, dynamic> payload) {
    if (_showBoonPick) return;
    final offers = (payload['boon_offers'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final done = (payload['picks_done'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final timeRemaining =
        (payload['time_remaining'] as num?)?.toDouble() ?? 10000;

    setState(() {
      _showBoonPick = true;
      _boonOffers = offers;
      _picksDone = done;
      _boonTimeRemaining = timeRemaining;
    });
  }

  void _handleBoonPick(String boonId) {
    _game.sendBoonPick(boonId);
    GameConfig.activeBoons.add(
      _boonOffers.firstWhere(
        (b) => b['id'] == boonId,
        orElse: () => {'name': boonId},
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showBoonPick = false);
    });
  }

  void _onVoteStart(Map<String, dynamic> payload) {
    final options = (payload['options'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    setState(() {
      _showVote = true;
      _voteId = payload['vote_id'] as String? ?? '';
      _voteOptions = options;
      _voteWindowMs = (payload['window_ms'] as num?)?.toDouble() ?? 15000;
      _voteMethod = payload['method'] as String? ?? 'plurality';
    });
  }

  void _onVoteTally(Map<String, dynamic> payload) {
    _voteKey.currentState?.updateTally(payload);
  }

  void _onVoteResult(Map<String, dynamic> payload) {
    _voteKey.currentState?.showResult(payload);
    final winnerLabel = payload['winner'] as String?;
    if (winnerLabel != null) {
      GameConfig.currentModifier = winnerLabel;
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showVote = false);
    });
  }

  void _handleVote(String voteId, String optionId) {
    _game.castVote(voteId, optionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          if (_showBoonPick)
            BoonPickOverlay(
              boonOffers: _boonOffers,
              picksDone: _picksDone,
              timeRemainingMs: _boonTimeRemaining,
              onPick: _handleBoonPick,
            ),
          if (_showVote)
            VoteOverlay(
              key: _voteKey,
              voteId: _voteId,
              options: _voteOptions,
              windowMs: _voteWindowMs,
              method: _voteMethod,
              onVote: _handleVote,
            ),
        ],
      ),
    );
  }
}
