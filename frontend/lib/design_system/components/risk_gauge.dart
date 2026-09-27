import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/batch.dart';

class RiskGauge extends StatelessWidget {
  final String label;
  final double value; // 0 to 100
  final RiskLevel level;
  final String? trend;
  final double size;

  const RiskGauge({
    super.key,
    required this.label,
    required this.value,
    required this.level,
    this.trend,
    this.size = 130.0,
  });

  Color _getRiskColor() {
    switch (level) {
      case RiskLevel.safe:
        return MausamColors.safe;
      case RiskLevel.watch:
        return MausamColors.watch;
      case RiskLevel.highRisk:
        return MausamColors.highRisk;
      case RiskLevel.critical:
        return MausamColors.critical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size * 0.65,
          child: CustomPaint(
            painter: _SemicircleGaugePainter(
              progress: (value / 100.0).clamp(0.0, 1.0),
              activeColor: riskColor,
              trackColor: MausamColors.surfaceElevated,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toInt().toString(),
                      style: MausamTypography.tabularDataLarge.copyWith(
                        fontSize: size * 0.28,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      level.label,
                      style: MausamTypography.micro.copyWith(
                        color: riskColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: MausamTypography.micro.copyWith(
            color: MausamColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        if (trend != null) ...[
          const SizedBox(height: 2),
          Text(
            trend!,
            style: MausamTypography.micro.copyWith(
              color: riskColor,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

class _SemicircleGaugePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  _SemicircleGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // Active Progress Arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SemicircleGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
  }
}
