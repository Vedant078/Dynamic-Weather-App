import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/batch.dart';
import 'route_map_view.dart';
import 'status_pill.dart';

class PriorityDeliverySection extends StatelessWidget {
  final BatchModel batch;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenRoutes;

  const PriorityDeliverySection({
    super.key,
    required this.batch,
    required this.onOpenDetail,
    required this.onOpenRoutes,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (batch.elapsedMinutes / (batch.elapsedMinutes + batch.etaMinutes)).clamp(0.05, 0.95);
    final isAtRisk = batch.riskLevel == RiskLevel.highRisk || batch.riskLevel == RiskLevel.critical;
    final isWatch = batch.riskLevel == RiskLevel.watch;

    Color statusColor = MausamColors.safe;
    String statusLabel = 'SAFE';
    if (isAtRisk) {
      statusColor = MausamColors.highRisk;
      statusLabel = 'HIGH RISK';
    } else if (isWatch) {
      statusColor = MausamColors.watch;
      statusLabel = 'WATCH';
    }

    return Container(
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(
          color: isAtRisk ? MausamColors.highRisk.withValues(alpha: 0.35) : MausamColors.brd(context),
          width: isAtRisk ? 1.5 : 1.0,
        ),
        boxShadow: MausamSpacing.shadow(context),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Detail Affordance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Priority delivery',
                  style: MausamTypography.labelBoldOf(context).copyWith(
                    fontSize: 13,
                    color: MausamColors.txtPrimary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onOpenDetail,
                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: MausamTypography.microOf(context).copyWith(
                          color: MausamColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(LucideIcons.chevronRight, size: 13, color: MausamColors.info),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      batch.batchCode,
                      style: MausamTypography.headingXL.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: MausamColors.txtPrimary(context),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '· ${batch.volumeM3} m³',
                        style: MausamTypography.microOf(context).copyWith(
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              StatusPill(
                label: statusLabel,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Plant to Project Route Description
          Row(
            children: [
              Flexible(
                child: Text(
                  batch.plantName,
                  style: MausamTypography.bodyOf(context).copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                    color: MausamColors.txtPrimary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(LucideIcons.arrowRight, size: 12, color: MausamColors.txtMuted(context)),
              ),
              Expanded(
                child: Text(
                  batch.projectName,
                  style: MausamTypography.bodyOf(context).copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                    color: MausamColors.txtPrimary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Progress Bar with moving vehicle dot
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final truckPos = (trackWidth - 18) * progress;

              return SizedBox(
                height: 16,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: MausamColors.surfSecondary(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      height: 4,
                      width: truckPos + 9,
                      decoration: BoxDecoration(
                        color: isAtRisk ? MausamColors.highRisk : MausamColors.info,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Positioned(
                      left: truckPos,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: MausamColors.surf(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAtRisk ? MausamColors.highRisk : MausamColors.info,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Restrained 4-Column Operational Telemetry
          Row(
            children: [
              Expanded(
                child: _buildTelemetryCell(
                  context,
                  label: 'ETA',
                  value: '${batch.etaMinutes.toInt()} min',
                  isWarning: batch.etaMinutes > 35,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildTelemetryCell(
                  context,
                  label: 'Remaining',
                  value: '${batch.distanceRemainingKm} km',
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildTelemetryCell(
                  context,
                  label: 'Slump retention',
                  value: '${(batch.slumpRetentionRatio * 100).toStringAsFixed(1)}%',
                  isWarning: batch.slumpRetentionRatio < 0.92,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildTelemetryCell(
                  context,
                  label: 'Concrete',
                  value: '${batch.concreteTempC}°C',
                  isWarning: batch.concreteTempC > 34.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Seamlessly Integrated Route Map
          RouteMapView(
            batch: batch,
            height: 165,
            onExpand: onOpenRoutes,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: MausamColors.brdSubtle(context),
    );
  }

  Widget _buildTelemetryCell(
    BuildContext context, {
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: MausamTypography.tabularOf(context).copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isWarning ? MausamColors.highRisk : MausamColors.txtPrimary(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
