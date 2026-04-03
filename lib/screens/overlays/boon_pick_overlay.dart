import 'dart:async';
import 'package:flutter/material.dart';
import '../../game_config.dart';
import '../../theme.dart';

class BoonPickOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> boonOffers;
  final List<String> picksDone;
  final double timeRemainingMs;
  final void Function(String boonId) onPick;

  const BoonPickOverlay({
    super.key,
    required this.boonOffers,
    required this.picksDone,
    required this.timeRemainingMs,
    required this.onPick,
  });

  @override
  State<BoonPickOverlay> createState() => _BoonPickOverlayState();
}

class _BoonPickOverlayState extends State<BoonPickOverlay> {
  bool _picked = false;
  late double _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.timeRemainingMs;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() => _remaining = (_remaining - 100).clamp(0, double.infinity));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _alreadyPicked {
    final myId = GameConfig.client.playerId ?? '';
    return _picked || widget.picksDone.contains(myId);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_remaining / 1000).ceil();

    return Container(
      color: NavalTheme.background.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CHOOSE A BOON',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: NavalTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${seconds}s remaining',
            style: TextStyle(fontSize: 18, color: NavalTheme.textDim),
          ),
          const SizedBox(height: 24),
          if (widget.boonOffers.isEmpty)
            Text(
              'Waiting for top players to pick...',
              style: TextStyle(fontSize: 20, color: NavalTheme.secondary),
            )
          else if (_alreadyPicked)
            Text(
              'Boon selected! Waiting for others...',
              style: TextStyle(fontSize: 20, color: NavalTheme.tertiary),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: widget.boonOffers.map((boon) {
                final id = boon['id'] as String? ?? '';
                final name = boon['name'] as String? ?? 'Unknown';
                final desc = boon['description'] as String? ?? '';
                return _BoonCard(
                  name: name,
                  description: desc,
                  onTap: () {
                    setState(() => _picked = true);
                    widget.onPick(id);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _BoonCard extends StatelessWidget {
  final String name;
  final String description;
  final VoidCallback onTap;

  const _BoonCard({
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NavalTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NavalTheme.primary.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NavalTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: NavalTheme.text),
            ),
          ],
        ),
      ),
    );
  }
}
