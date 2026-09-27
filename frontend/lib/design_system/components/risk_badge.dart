import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/batch.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final bool showIcon;
  final double fontSize;

  const RiskBadge({
    super.key,
    required this.level,
    this.showIcon = true,
    this.fontSize = 10.5,
  });

  @override
  Widget build(BuildContext context) {
    Color fg;
    IconData icon;
    String text;

    switch (level) {
      case RiskLevel.safe:
        fg = MausamColors.safe;
        icon = LucideIcons.shieldCheck;
        text = 'SAFE';
        break;
      case RiskLevel.watch:
        fg = MausamColors.watch;
        icon = LucideIcons.alertCircle;
        text = 'WATCH';
        break;
      case RiskLevel.highRisk:
        fg = MausamColors.highRisk;
        icon = LucideIcons.alertTriangle;
        text = 'HIGH RISK';
        break;
      case RiskLevel.critical:
        fg = MausamColors.critical;
        icon = LucideIcons.flame;
        text = 'CRITICAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: fontSize + 1, color: fg),
            const SizedBox(width: 3.5),
          ],
          Text(
            text,
            style: MausamTypography.microOf(context).copyWith(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
