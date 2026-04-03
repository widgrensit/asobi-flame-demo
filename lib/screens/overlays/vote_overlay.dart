import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme.dart';

class VoteOverlay extends StatefulWidget {
  final String voteId;
  final List<Map<String, dynamic>> options;
  final double windowMs;
  final String method;
  final void Function(String voteId, String optionId) onVote;

  const VoteOverlay({
    super.key,
    required this.voteId,
    required this.options,
    required this.windowMs,
    required this.method,
    required this.onVote,
  });

  @override
  State<VoteOverlay> createState() => VoteOverlayState();
}

class VoteOverlayState extends State<VoteOverlay> {
  bool _voted = false;
  String? _selectedId;
  late double _remaining;
  Timer? _timer;
  Map<String, int> _tallies = {};
  String? _winnerId;

  @override
  void initState() {
    super.initState();
    _remaining = widget.windowMs;
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

  void updateTally(Map<String, dynamic> payload) {
    final tallies = payload['tallies'] as Map<String, dynamic>? ?? {};
    setState(() {
      _tallies = tallies.map((k, v) => MapEntry(k, (v as num).toInt()));
    });
  }

  void showResult(Map<String, dynamic> payload) {
    setState(() {
      _winnerId = payload['winner'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_remaining / 1000).ceil();
    final totalVotes = _tallies.values.fold(0, (a, b) => a + b);

    return Container(
      color: NavalTheme.background.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _winnerId != null ? 'VOTE RESULT' : 'VOTE',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: NavalTheme.primary,
            ),
          ),
          if (_winnerId == null) ...[
            const SizedBox(height: 8),
            Text(
              '${seconds}s remaining',
              style: TextStyle(fontSize: 18, color: NavalTheme.textDim),
            ),
          ],
          const SizedBox(height: 24),
          ...widget.options.map((opt) {
            final id = opt['id'] as String? ?? '';
            final label = opt['label'] as String? ?? id;
            final count = _tallies[id] ?? 0;
            final fraction = totalVotes > 0 ? count / totalVotes : 0.0;
            final isWinner = _winnerId == id;
            final isSelected = _selectedId == id;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: _voted || _winnerId != null
                    ? null
                    : () {
                        setState(() {
                          _voted = true;
                          _selectedId = id;
                        });
                        widget.onVote(widget.voteId, id);
                      },
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isWinner
                        ? NavalTheme.tertiary.withValues(alpha: 0.2)
                        : isSelected
                            ? NavalTheme.primary.withValues(alpha: 0.2)
                            : NavalTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isWinner
                          ? NavalTheme.tertiary
                          : isSelected
                              ? NavalTheme.primary
                              : NavalTheme.primary.withValues(alpha: 0.3),
                      width: isWinner || isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 18,
                              color: isWinner ? NavalTheme.tertiary : NavalTheme.text,
                              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (_tallies.isNotEmpty)
                            Text(
                              '$count votes',
                              style: TextStyle(
                                fontSize: 14,
                                color: NavalTheme.textDim,
                              ),
                            ),
                        ],
                      ),
                      if (_tallies.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: NavalTheme.background,
                          color: isWinner ? NavalTheme.tertiary : NavalTheme.secondary,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
