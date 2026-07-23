import 'dart:async';

import 'package:flutter/material.dart';

class MultiTapDetector extends StatefulWidget {
  const MultiTapDetector({
    super.key,
    required this.child,
    required this.onDoubleTap,
    required this.onTripleTap,
    this.resetDuration = const Duration(milliseconds: 350),
  });

  final Widget child;
  final VoidCallback onDoubleTap;
  final VoidCallback onTripleTap;
  final Duration resetDuration;

  @override
  State<MultiTapDetector> createState() => _MultiTapDetectorState();
}

class _MultiTapDetectorState extends State<MultiTapDetector> {
  int _tapCount = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    _tapCount++;
    _timer?.cancel();
    _timer = Timer(widget.resetDuration, () {
      if (!mounted) return;

      if (_tapCount >= 3) {
        widget.onTripleTap();
      } else if (_tapCount == 2) {
        widget.onDoubleTap();
      }

      _tapCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: widget.child,
    );
  }
}
