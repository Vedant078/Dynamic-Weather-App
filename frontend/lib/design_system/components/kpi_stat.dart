import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';

enum KpiValence { positive, negative, neutral }

class KpiStat extends StatelessWidget {
  final String label;
  final String value;
  final String? changeText;
  final KpiValence valence;
  final IconData? icon;
  final List<double>? sparklineData;

  const KpiStat({
    super.key,
    required this.label,
    required this.value,
    this.changeText,
    this.valence = KpiValence.neutral,
    this.icon,
    this.sparklineData,
  });

  Color _getValenceColor(BuildContext context) {
    switch (valence) {
      case KpiValence.positive:
        return MausamColors.safe;
      case KpiValence.negative:
        return MausamColors.highRisk;
      case KpiValence.neutral:
        return MausamColors.txtSecondary(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valenceColor = _getValenceColor(context);

    return Container(
      padding: const EdgeInsets.all(MausamSpacing.compact + 2),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(color: MausamColors.brd(context), width: 1.0),
        boxShadow: MausamSpacing.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: MausamTypography.microOf(context).copyWith(
                    letterSpacing: 0.1,
                    fontSize: 10.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: MausamColors.txtMuted(context)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: MausamTypography.tabularOf(context).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (changeText != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: valenceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                    ),
                    child: Text(
                      changeText!,
                      style: MausamTypography.microOf(context).copyWith(
                        color: valenceColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (sparklineData != null && sparklineData!.isNotEmpty) ...[
                const SizedBox(width: 4),
                _MiniSparkline(data: sparklineData!, color: valenceColor),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _MiniSparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 14,
      child: CustomPaint(
        painter: _MiniSparklinePainter(data: data, color: color),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniSparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * (size.height - 2) - 1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) => true;
}
