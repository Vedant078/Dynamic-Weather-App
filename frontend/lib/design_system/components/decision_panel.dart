import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/batch.dart';
import 'risk_badge.dart';

class DecisionPanel extends StatelessWidget {
  final BatchModel batch;
  final VoidCallback onCalculateRoute;
  final VoidCallback onAddRetarder;
  final VoidCallback onReschedule;
  final VoidCallback onOverride;

  const DecisionPanel({
    super.key,
    required this.batch,
    required this.onCalculateRoute,
    required this.onAddRetarder,
    required this.onReschedule,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = batch.riskLevel == RiskLevel.highRisk || batch.riskLevel == RiskLevel.critical;

    return Container(
      padding: const EdgeInsets.all(MausamSpacing.standard),
      decoration: BoxDecoration(
        color: isCritical
            ? MausamColors.highRiskSubtle.withValues(alpha: 0.12)
            : MausamColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(
          color: isCritical ? MausamColors.highRisk.withValues(alpha: 0.5) : MausamColors.border,
          width: isCritical ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isCritical ? LucideIcons.alertOctagon : LucideIcons.shieldCheck,
                      size: 17,
                      color: isCritical ? MausamColors.highRisk : MausamColors.safe,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isCritical ? 'OPERATIONAL ACTION REQUIRED' : 'DELIVERY ON TRACK',
                        style: MausamTypography.labelBold.copyWith(
                          color: isCritical ? MausamColors.highRisk : MausamColors.safe,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RiskBadge(level: batch.riskLevel),
            ],
          ),
          const SizedBox(height: 10),

          // Problem Statement & Primary Driver
          Text(
            batch.primaryDriver,
            style: MausamTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // AI Evidence Factors (skills.md Section 14.1)
          Container(
            padding: const EdgeInsets.all(MausamSpacing.compact + 2),
            decoration: BoxDecoration(
              color: MausamColors.surfaceElevated,
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(color: MausamColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.binary, size: 12, color: MausamColors.info),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'WHY RISK CHANGED (AI EXPLAINABILITY)',
                        style: MausamTypography.micro.copyWith(
                          color: MausamColors.info,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...batch.riskFactors.map(
                  (factor) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(color: MausamColors.highRisk, fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            factor,
                            style: MausamTypography.body.copyWith(
                              fontSize: 12,
                              color: MausamColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Primary Recommended Action (Prominent Button)
          if (isCritical) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onCalculateRoute,
                icon: const Icon(LucideIcons.navigation, size: 16),
                label: const Text('CALCULATE & APPLY ROUTE B (-9 min)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MausamColors.info,
                  foregroundColor: MausamColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Secondary Alternative Mitigations
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddRetarder,
                    icon: const Icon(LucideIcons.beaker, size: 13),
                    label: const Text('Add Retarder', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: MausamColors.border),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOverride,
                    icon: const Icon(LucideIcons.shieldAlert, size: 13, color: MausamColors.watch),
                    label: const Text('Override', style: TextStyle(fontSize: 11, color: MausamColors.watch)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: MausamColors.watch.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(LucideIcons.checkCircle2, size: 14, color: MausamColors.safe),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Transit <= 78m & Slump >= 92%. Standard navigation active.',
                    style: MausamTypography.body.copyWith(fontSize: 12, color: MausamColors.safe),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
