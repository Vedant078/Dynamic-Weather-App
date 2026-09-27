import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';

class OperationsSummary extends StatelessWidget {
  final int activeDeliveries;
  final int needsAttention;
  final double? avgSlumpRetention;
  final String avoidedLoss;

  const OperationsSummary({
    super.key,
    required this.activeDeliveries,
    required this.needsAttention,
    this.avgSlumpRetention,
    required this.avoidedLoss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(color: MausamColors.brd(context)),
        boxShadow: MausamSpacing.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header label (editorial sentence case)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Operations summary',
                  style: MausamTypography.labelBoldOf(context).copyWith(
                    fontSize: 13,
                    color: MausamColors.txtPrimary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (needsAttention > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: MausamColors.highRisk.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: MausamColors.highRisk,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$needsAttention requires triage',
                        style: MausamTypography.microOf(context).copyWith(
                          color: MausamColors.highRisk,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              else if (activeDeliveries > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: MausamColors.safe.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: MausamColors.safe,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'All nominal',
                        style: MausamTypography.microOf(context).copyWith(
                          color: MausamColors.safe,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: MausamColors.brd(context).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                  ),
                  child: Text(
                    'Operational standby',
                    style: MausamTypography.microOf(context).copyWith(
                      color: MausamColors.txtSecondary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Editorial Metric Cells
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  value: '$activeDeliveries',
                  label: 'Active deliveries',
                  subtext: activeDeliveries > 0 ? 'In transit now' : 'No deliveries currently in transit',
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildMetricItem(
                  context,
                  value: '$needsAttention',
                  label: 'Needs attention',
                  subtext: needsAttention > 0 ? 'Risk elevated' : 'No active risk alerts',
                  valueColor: needsAttention > 0 ? MausamColors.highRisk : (activeDeliveries > 0 ? MausamColors.safe : MausamColors.txtSecondary(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: MausamColors.brdSubtle(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  value: avgSlumpRetention != null ? '${(avgSlumpRetention! * 100).toStringAsFixed(1)}%' : '—',
                  label: 'Avg. slump retention',
                  subtext: avgSlumpRetention != null
                      ? (avgSlumpRetention! >= 0.92 ? 'Within 92% SLA' : 'Below threshold')
                      : 'Available after first completed delivery',
                  valueColor: avgSlumpRetention != null
                      ? (avgSlumpRetention! >= 0.92 ? MausamColors.txtPrimary(context) : MausamColors.highRisk)
                      : MausamColors.txtSecondary(context),
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildMetricItem(
                  context,
                  value: avoidedLoss,
                  label: 'Avoided loss',
                  subtext: avoidedLoss != '₹0' ? 'Through proactive rerouting' : 'Calculated from completed operational history',
                  valueColor: avoidedLoss != '₹0' ? MausamColors.safe : MausamColors.txtSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: MausamColors.brdSubtle(context),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String value,
    required String label,
    required String subtext,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: MausamTypography.tabularOf(context).copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: valueColor ?? MausamColors.txtPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: MausamTypography.labelBoldOf(context).copyWith(
            fontSize: 12,
            color: MausamColors.txtPrimary(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtext,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 10.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
