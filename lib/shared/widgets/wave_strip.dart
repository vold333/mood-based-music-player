import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A static, decorative wave band for the bottom of a screen.
///
/// Drawn from the active theme's colours, so Night and Day share one widget
/// and there are no image assets to duplicate. It never animates, ignores
/// touches, and is hidden from screen readers.
class WaveStrip extends StatelessWidget {
  const WaveStrip({super.key, this.height = 72});

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _WavePainter(
                backColor: scheme.secondary.withValues(alpha: 0.20),
                frontColor: scheme.primary.withValues(alpha: 0.24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.backColor,
    required this.frontColor,
  });

  final Color backColor;
  final Color frontColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintWave(
      canvas,
      size,
      color: backColor,
      baseline: size.height * 0.42,
      amplitude: size.height * 0.20,
      cycles: 1.6,
      phase: 0.6,
    );
    _paintWave(
      canvas,
      size,
      color: frontColor,
      baseline: size.height * 0.62,
      amplitude: size.height * 0.16,
      cycles: 2.2,
      phase: 2.1,
    );
  }

  void _paintWave(
    Canvas canvas,
    Size size, {
    required Color color,
    required double baseline,
    required double amplitude,
    required double cycles,
    required double phase,
  }) {
    const steps = 48;
    final path = Path()..moveTo(0, size.height);

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = baseline + amplitude * math.sin(t * cycles * 2 * math.pi + phase);
      path.lineTo(size.width * t, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.backColor != backColor ||
        oldDelegate.frontColor != frontColor;
  }
}