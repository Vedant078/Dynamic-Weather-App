import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/batch.dart';
import 'status_pill.dart';

class RiskIntelligenceCard extends StatelessWidget {
  final BatchModel batch;
  final VoidCallback onCalculateRoute;
  final VoidCallback onAddRetarder;
  final VoidCallback onOverride;

  const RiskIntelligenceCard({
    super.key,
    required this.batch,
    required this.onCalculateRoute,
    required this.onAddRetarder,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = batch.riskLevel == RiskLevel.highRisk || batch.riskLevel == RiskLevel.critical;
    final isWatch = batch.riskLevel == RiskLevel.watch;

    Color riskColor = MausamColors.safe;
    String riskTier = 'Low risk';
    if (isCritical) {
      riskColor = MausamColors.highRisk;
      riskTier = 'High risk';
    } else if (isWatch) {
      riskColor = MausamColors.watch;
      riskTier = 'Moderate risk';
    }

    return Container(
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(
          color: isCritical ? MausamColors.highRisk.withValues(alpha: 0.35) : MausamColors.brd(context),
          width: isCritical ? 1.5 : 1.0,
        ),
        boxShadow: MausamSpacing.shadow(context),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Delivery risk & score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery risk',
                    style: MausamTypography.labelBoldOf(context).copyWith(
                      fontSize: 13,
                      color: MausamColors.txtPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${batch.deliveryRisk.toInt()}',
                        style: MausamTypography.tabularOf(context).copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: riskColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· $riskTier',
                        style: MausamTypography.bodyMediumOf(context).copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusPill(
                label: isCritical ? 'ACTION REQUIRED' : (isWatch ? 'MONITORING' : 'ON TRACK'),
                color: riskColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Factor Statement
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCritical
                  ? MausamColors.highRisk.withValues(alpha: 0.06)
                  : MausamColors.surfSecondary(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(
                color: isCritical
                    ? MausamColors.highRisk.withValues(alpha: 0.2)
                    : MausamColors.brdSubtle(context),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isCritical ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
                  size: 15,
                  color: riskColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary factor',
                        style: MausamTypography.microOf(context).copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        batch.primaryDriver,
                        style: MausamTypography.bodyMediumOf(context).copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Contributing Risk Factors Breakdown (Editorial table)
          Text(
            'Contributing factors',
            style: MausamTypography.microOf(context).copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          _buildFactorRow(
            context,
            icon: LucideIcons.trafficCone,
            label: 'Traffic delay',
            value: batch.etaMinutes > 32 ? '+14 min congestion' : 'Normal flow',
            isNegative: batch.etaMinutes > 32,
          ),
          Divider(height: 12, color: MausamColors.brdSubtle(context)),
          _buildFactorRow(
            context,
            icon: LucideIcons.thermometer,
            label: 'Concrete temperature',
            value: '${batch.concreteTempC}°C (${batch.concreteTempC > 33.0 ? '+2.4°C rise' : 'nominal'})',
            isNegative: batch.concreteTempC > 34.0,
          ),
          Divider(height: 12, color: MausamColors.brdSubtle(context)),
          _buildFactorRow(
            context,
            icon: LucideIcons.cloudRain,
            label: 'Rain probability',
            value: '${batch.precipitationProb.toInt()}% along route',
            isNegative: batch.precipitationProb > 40.0,
          ),
          Divider(height: 12, color: MausamColors.brdSubtle(context)),
          _buildFactorRow(
            context,
            icon: LucideIcons.percent,
            label: 'Predicted slump retention',
            value: '${(batch.slumpRetentionRatio * 100).toStringAsFixed(1)}% (92% SLA)',
            isNegative: batch.slumpRetentionRatio < 0.92,
          ),
          const SizedBox(height: 16),

          // Actionable Recommendation Section
          if (isCritical) ...[
            Text(
              'Recommended action',
              style: MausamTypography.microOf(context).copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Delivery is projected to exceed the 78-minute safe window on Route A. Divert via Airport Bypass Expressway to protect slump retention.',
              style: MausamTypography.bodyOf(context).copyWith(
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onCalculateRoute,
                icon: const Icon(LucideIcons.navigation, size: 15),
                label: const Text('Calculate & Apply Route B (-9 min)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MausamColors.info,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddRetarder,
                    icon: const Icon(LucideIcons.beaker, size: 13),
                    label: const Text('Add retarder', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: BorderSide(color: MausamColors.brd(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOverride,
                    icon: const Icon(LucideIcons.shieldAlert, size: 13),
                    label: const Text('Log override', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: BorderSide(color: MausamColors.brd(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: MausamColors.safe.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.check, size: 14, color: MausamColors.safe),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'No operational intervention required. Transit conditions nominal.',
                      style: MausamTypography.bodyOf(context).copyWith(
                        fontSize: 12,
                        color: MausamColors.safe,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFactorRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isNegative,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: isNegative ? MausamColors.highRisk : MausamColors.txtMuted(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: MausamTypography.bodyOf(context).copyWith(
              fontSize: 12.5,
              color: MausamColors.txtPrimary(context),
            ),
          ),
        ),
        Text(
          value,
          style: MausamTypography.labelBoldOf(context).copyWith(
            fontSize: 12,
            color: isNegative ? MausamColors.highRisk : MausamColors.txtSecondary(context),
          ),
        ),
      ],
    );
  }
}
