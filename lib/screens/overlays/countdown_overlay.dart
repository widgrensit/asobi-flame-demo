import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const CountdownOverlay({super.key, required this.onComplete});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  final _labels = ['3', '2', '1', 'GO!'];
  int _index = 0;
  Timer? _timer;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );
    _scaleCtrl.forward();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      setState(() => _index++);
      if (_index >= _labels.length) {
        _timer?.cancel();
        widget.onComplete();
      } else {
        _scaleCtrl.reset();
        _scaleCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _labels.length) return const SizedBox.shrink();
    return Container(
      color: NavalTheme.background.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Text(
          _labels[_index],
          style: TextStyle(
            fontSize: _labels[_index] == 'GO!' ? 80 : 100,
            fontWeight: FontWeight.bold,
            color: _labels[_index] == 'GO!'
                ? NavalTheme.tertiary
                : NavalTheme.primary,
          ),
        ),
      ),
    );
  }
}
