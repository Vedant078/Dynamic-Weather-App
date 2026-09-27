import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'mausam_colors.dart';

/// Atmospheric visual motif painter for MAUSAM (isobars, wind streamlines, transit contours)
/// Provides a subtle, recognizable product signature without visual noise or generic AI blobs.
class MausamAtmosphericMotif extends StatelessWidget {
  final double height;
  final double opacity;
  final bool showWaypoints;
  final Widget? child;

  const MausamAtmosphericMotif({
    super.key,
    this.height = 200,
    this.opacity = 0.08,
    this.showWaypoints = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);
    final strokeColor = isDark
        ? const Color(0xFF38BDF8).withValues(alpha: opacity * 1.5)
        : const Color(0xFF0284C7).withValues(alpha: opacity);

    return CustomPaint(
      painter: _IsobarPainter(
        color: strokeColor,
        isDark: isDark,
        showWaypoints: showWaypoints,
      ),
      child: child != null
          ? SizedBox(
              height: height,
              width: double.infinity,
              child: child,
            )
          : SizedBox(
              height: height,
              width: double.infinity,
            ),
    );
  }
}

class _IsobarPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final bool showWaypoints;

  _IsobarPainter({
    required this.color,
    required this.isDark,
    required this.showWaypoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
          .withValues(alpha: color.a * 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // 1. Draw 4 subtle, organic atmospheric isobar waves
    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = h * (0.2 + (i * 0.22));
      final amplitude = 14.0 + (i * 4.0);
      final frequency = 0.012 + (i * 0.003);

      path.moveTo(0, yOffset + math.sin(0) * amplitude);
      for (double x = 0; x <= w; x += 12) {
        final y = yOffset + math.sin(x * frequency + (i * 0.8)) * amplitude;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, i == 1 ? accentPaint : linePaint);
    }

    // 2. Subtle directional wind streamline
    final streamPath = Path();
    streamPath.moveTo(w * 0.1, h * 0.85);
    streamPath.cubicTo(
      w * 0.35, h * 0.75,
      w * 0.65, h * 0.35,
      w * 0.92, h * 0.25,
    );
    final dashPaint = Paint()
      ..color = color.withValues(alpha: color.a * 1.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(streamPath, dashPaint);

    // 3. Optional transit waypoints along streamline
    if (showWaypoints) {
      final pointPaint = Paint()
        ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
            .withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(w * 0.1, h * 0.85), 3.0, pointPaint);
      canvas.drawCircle(Offset(w * 0.5, h * 0.55), 2.5, pointPaint);
      canvas.drawCircle(Offset(w * 0.92, h * 0.25), 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IsobarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isDark != isDark ||
        oldDelegate.showWaypoints != showWaypoints;
  }
}
