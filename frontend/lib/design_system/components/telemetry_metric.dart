import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';

class TelemetryMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? delta;
  final bool isWarning;
  final IconData? icon;

  const TelemetryMetric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.isWarning = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MausamSpacing.small,
        vertical: MausamSpacing.compact + 2,
      ),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        border: Border.all(
          color: isWarning ? MausamColors.highRisk.withValues(alpha: 0.35) : MausamColors.brd(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isWarning ? MausamColors.highRisk : MausamColors.txtMuted(context),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: MausamTypography.microOf(context).copyWith(
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: MausamTypography.tabularOf(context).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isWarning ? MausamColors.highRisk : MausamColors.txtPrimary(context),
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit!,
                    style: MausamTypography.labelOf(context).copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Text(
              delta!,
              style: MausamTypography.microOf(context).copyWith(
                color: isWarning ? MausamColors.highRisk : MausamColors.safe,
                fontSize: 9.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
