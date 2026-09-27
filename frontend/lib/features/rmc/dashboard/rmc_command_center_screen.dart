import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/mausam_colors.dart';
import '../../../core/theme/mausam_spacing.dart';
import '../../../core/theme/mausam_typography.dart';
import '../../../models/batch.dart';
import '../../../state/mausam_state.dart';
import '../../../design_system/components/operations_summary.dart';
import '../../../design_system/components/priority_delivery_section.dart';
import '../../../design_system/components/risk_intelligence_card.dart';
import '../../../design_system/components/batch_card.dart';
import '../../../design_system/components/alert_feed.dart';

class RmcCommandCenterScreen extends StatelessWidget {
  final MausamState state;
  final VoidCallback onOpenBatchDetail;
  final VoidCallback onOpenRoutes;
  final VoidCallback onOpenOutcome;

  const RmcCommandCenterScreen({
    super.key,
    required this.state,
    required this.onOpenBatchDetail,
    required this.onOpenRoutes,
    required this.onOpenOutcome,
  });

  @override
  Widget build(BuildContext context) {
    final hasBatches = state.batches.isNotEmpty;
    final batch = hasBatches ? state.selectedBatch : null;
    final otherBatches = hasBatches ? state.batches.where((b) => b.batchId != batch!.batchId).toList() : <BatchModel>[];
    final atRiskCount = state.batches.where((b) => b.riskLevel != RiskLevel.safe).length;
    final double? avgRetention = state.batches.isEmpty
        ? null
        : (state.batches.fold(0.0, (acc, b) => acc + b.slumpRetentionRatio) / state.batches.length);

    final totalAvoidedLoss = state.outcomes.where((o) => o.financialType == 'AVOIDED_LOSS').fold(0.0, (acc, o) => acc + o.financialImpactInr);
    final avoidedLossStr = totalAvoidedLoss > 0
        ? (totalAvoidedLoss >= 100000 ? '₹${(totalAvoidedLoss / 100000).toStringAsFixed(2)}L' : '₹${totalAvoidedLoss.toInt()}')
        : '₹0';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. OPERATIONAL DISPATCH BAR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasBatches ? MausamColors.safe : MausamColors.txtSecondary(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            hasBatches ? 'GRID ACTIVE' : 'GRID STANDBY',
                            style: MausamTypography.microOf(context).copyWith(
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: hasBatches ? MausamColors.safe : MausamColors.txtSecondary(context),
                              fontSize: 9.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RMC Logistics',
                      style: MausamTypography.headingXL.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: MausamColors.txtPrimary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasBatches) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => state.startCreateDelivery(),
                  icon: const Icon(LucideIcons.plus, size: 13),
                  label: const Text('Create Delivery'),
                  style: FilledButton.styleFrom(
                    backgroundColor: MausamColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // 1. OPERATIONS SUMMARY (Restrained editorial metrics, no heavy card soup)
          OperationsSummary(
            activeDeliveries: state.batches.length,
            needsAttention: atRiskCount,
            avgSlumpRetention: avgRetention,
            avoidedLoss: avoidedLossStr,
          ),
          const SizedBox(height: 18),

          // IF NO ACTIVE DELIVERIES -> Show Clean Empty State (Section 1.4)
          if (!hasBatches) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: MausamColors.surf(context),
                borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
                border: Border.all(color: MausamColors.brd(context)),
                boxShadow: MausamSpacing.shadow(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MausamColors.accent.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.truck, size: 28, color: MausamColors.accent),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No active deliveries',
                    style: MausamTypography.labelBoldOf(context).copyWith(
                      fontSize: 15,
                      color: MausamColors.txtPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your first delivery to begin monitoring transit conditions, route weather and concrete slump retention.',
                    style: MausamTypography.microOf(context).copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => state.startCreateDelivery(),
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Create Delivery'),
                    style: FilledButton.styleFrom(
                      backgroundColor: MausamColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 2. PRIORITY DELIVERY (Primary visual anchor with integrated route preview)
            PriorityDeliverySection(
              batch: batch!,
              onOpenDetail: onOpenBatchDetail,
              onOpenRoutes: onOpenRoutes,
            ),
            const SizedBox(height: 18),

            // 3. EXPLAINABLE RISK INTELLIGENCE & ACTIONS (Replaces artificial gauges)
            RiskIntelligenceCard(
              batch: batch,
              onCalculateRoute: () {
                state.applyAlternativeRoute();
                onOpenRoutes();
              },
              onAddRetarder: state.addRetarderAdmixture,
              onOverride: state.confirmOverride,
            ),
            const SizedBox(height: 18),

            // 4. OTHER ACTIVE DELIVERIES
            if (otherBatches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Other deliveries',
                    style: MausamTypography.labelBoldOf(context).copyWith(
                      fontSize: 13,
                      color: MausamColors.txtPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${otherBatches.length} in transit',
                  style: MausamTypography.microOf(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...otherBatches.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: BatchCard(
                  batch: b,
                  isSelected: false,
                  onTap: () {
                    state.selectBatch(b.batchId);
                    onOpenBatchDetail();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 5. OPERATIONAL ALERTS FEED
          AlertFeed(
            alerts: [
              AlertItemData(
                title: batch.riskLevel == RiskLevel.highRisk
                    ? 'Transit window threshold breach'
                    : 'Corridor traffic active',
                description: batch.riskLevel == RiskLevel.highRisk
                    ? 'Projected transit 82m exceeds 78m safe limit. Bottleneck near Nana Chiloda.'
                    : 'Traffic moving at 38 km/h along SP Ring Road corridor.',
                timestamp: '4m ago',
                severity: batch.riskLevel,
                icon: LucideIcons.clock,
              ),
              AlertItemData(
                title: batch.ambientTempC >= 38.0
                    ? 'Extreme midday heat exposure'
                    : 'Corridor thermal status',
                description: 'Ambient temperature ${batch.ambientTempC.toStringAsFixed(1)}°C influencing hydration kinetics.',
                timestamp: '12m ago',
                severity: batch.ambientTempC >= 38.0
                    ? RiskLevel.highRisk
                    : (batch.ambientTempC >= 35.0 ? RiskLevel.watch : RiskLevel.safe),
                icon: LucideIcons.thermometer,
              ),
              AlertItemData(
                title: batch.precipitationProb >= 50.0
                    ? 'Monsoon rain cell detected'
                    : 'Corridor atmospheric stability',
                description: '${batch.precipitationProb.toInt()}% rain probability along corridor segment.',
                timestamp: '18m ago',
                severity: batch.precipitationProb >= 50.0 ? RiskLevel.watch : RiskLevel.safe,
                icon: LucideIcons.cloudRain,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ],
    ),
  );
  }
}
