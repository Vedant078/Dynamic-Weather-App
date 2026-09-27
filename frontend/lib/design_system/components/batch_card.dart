import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/batch.dart';
import 'status_pill.dart';

class BatchCard extends StatelessWidget {
  final BatchModel batch;
  final VoidCallback onTap;
  final bool isSelected;

  const BatchCard({
    super.key,
    required this.batch,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (batch.elapsedMinutes / (batch.elapsedMinutes + batch.etaMinutes)).clamp(0.05, 0.95);
    final isCritical = batch.riskLevel == RiskLevel.highRisk || batch.riskLevel == RiskLevel.critical;
    final isWatch = batch.riskLevel == RiskLevel.watch;

    Color statusColor = MausamColors.safe;
    String statusLabel = 'SAFE';
    if (isCritical) {
      statusColor = MausamColors.highRisk;
      statusLabel = 'HIGH RISK';
    } else if (isWatch) {
      statusColor = MausamColors.watch;
      statusLabel = 'WATCH';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (MausamColors.isDark(context) ? MausamColors.surfaceElevatedDark : Colors.white)
              : MausamColors.surf(context),
          borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
          border: Border.all(
            color: isSelected
                ? MausamColors.info
                : (isCritical
                    ? MausamColors.highRisk.withValues(alpha: 0.35)
                    : MausamColors.brd(context)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? MausamSpacing.shadow(context) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Batch Code & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      batch.batchCode,
                      style: MausamTypography.labelBoldOf(context).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${batch.volumeM3} m³',
                      style: MausamTypography.microOf(context).copyWith(fontSize: 11),
                    ),
                  ],
                ),
                StatusPill(
                  label: statusLabel,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Plant -> Project Route Labels
            Row(
              children: [
                Flexible(
                  child: Text(
                    batch.plantName,
                    style: MausamTypography.microOf(context).copyWith(
                      color: MausamColors.txtSecondary(context),
                      fontSize: 11.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(LucideIcons.arrowRight, size: 11, color: MausamColors.txtMuted(context)),
                ),
                Expanded(
                  child: Text(
                    batch.projectName,
                    style: MausamTypography.microOf(context).copyWith(
                      color: MausamColors.txtSecondary(context),
                      fontSize: 11.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Linear Progress Track
            LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final truckPos = (trackWidth - 16) * progress;

                return SizedBox(
                  height: 14,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 3.5,
                        width: trackWidth,
                        decoration: BoxDecoration(
                          color: MausamColors.surfSecondary(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        height: 3.5,
                        width: truckPos + 8,
                        decoration: BoxDecoration(
                          color: isCritical ? MausamColors.highRisk : MausamColors.info,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Positioned(
                        left: truckPos,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: MausamColors.surf(context),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCritical ? MausamColors.highRisk : MausamColors.info,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Bottom Metrics: ETA, Distance, Slump Retention, Concrete Temp
            Row(
              children: [
                Expanded(
                  child: _buildMetricCol(
                    context,
                    'ETA',
                    '${batch.etaMinutes.toInt()} min',
                    isUrgent: batch.etaMinutes > 35,
                  ),
                ),
                Expanded(
                  child: _buildMetricCol(
                    context,
                    'Remaining',
                    '${batch.distanceRemainingKm} km',
                  ),
                ),
                Expanded(
                  child: _buildMetricCol(
                    context,
                    'Slump ret.',
                    '${(batch.slumpRetentionRatio * 100).toStringAsFixed(1)}%',
                    isUrgent: batch.slumpRetentionRatio < 0.92,
                  ),
                ),
                Expanded(
                  child: _buildMetricCol(
                    context,
                    'Concrete',
                    '${batch.concreteTempC}°C',
                    isUrgent: batch.concreteTempC > 34.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(BuildContext context, String label, String value, {bool isUrgent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 9.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: MausamTypography.tabularOf(context).copyWith(
            color: isUrgent ? MausamColors.highRisk : MausamColors.txtPrimary(context),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
