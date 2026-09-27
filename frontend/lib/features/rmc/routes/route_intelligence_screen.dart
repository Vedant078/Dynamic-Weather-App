import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/mausam_colors.dart';
import '../../../core/theme/mausam_spacing.dart';
import '../../../core/theme/mausam_typography.dart';
import '../../../state/mausam_state.dart';
import '../../../design_system/components/route_map_view.dart';
import '../../../design_system/components/route_comparison_view.dart';
import '../../../design_system/components/status_pill.dart';

class RouteIntelligenceScreen extends StatelessWidget {
  final MausamState state;

  const RouteIntelligenceScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final batch = state.selectedBatch;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route intelligence',
                    style: MausamTypography.headingXL.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: MausamColors.txtPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Weather-weighted corridor navigation',
                    style: MausamTypography.microOf(context),
                  ),
                ],
              ),
              StatusPill(
                label: batch.activeRouteId == 'route-b' ? 'ROUTE B ACTIVE' : 'ROUTE A ACTIVE',
                color: batch.activeRouteId == 'route-b' ? MausamColors.safe : MausamColors.info,
                icon: LucideIcons.navigation2,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Operational Principle Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: MausamColors.surfSecondary(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(color: MausamColors.brd(context)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 15, color: MausamColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The shortest geometric distance is not necessarily the safest corridor for fresh concrete hydration.',
                    style: MausamTypography.bodyOf(context).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Full-Detail Interactive Route Map
          RouteMapView(
            batch: batch,
            height: 210,
            isInteractive: true,
          ),
          const SizedBox(height: 16),

          // Route Comparison Cards
          RouteComparisonView(
            routes: state.routes,
            activeRouteId: batch.activeRouteId,
            onSelectRoute: (routeId) {
              if (routeId == 'route-b') {
                state.applyAlternativeRoute();
              } else {
                state.setSimulationStep(0);
              }
            },
          ),
          const SizedBox(height: 16),

          // Corridor Metric Decomposition Table
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
              border: Border.all(color: MausamColors.brd(context)),
              boxShadow: MausamSpacing.shadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Corridor comparison breakdown',
                  style: MausamTypography.labelBoldOf(context).copyWith(
                    fontSize: 13,
                    color: MausamColors.txtPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                _buildComparisonRow(
                  context,
                  'Bottleneck exposure',
                  'High (+14m Nana Chiloda)',
                  'Zero (Expressway bypass)',
                  isLeftWorse: true,
                ),
                Divider(color: MausamColors.brdSubtle(context), height: 16),
                _buildComparisonRow(
                  context,
                  'Hydration temperature',
                  '${batch.ambientTempC.toStringAsFixed(1)}°C ambient / ${batch.concreteTempC.toStringAsFixed(1)}°C concrete',
                  '${(batch.ambientTempC - 2.5).toStringAsFixed(1)}°C ambient / ${(batch.concreteTempC - 1.0).toStringAsFixed(1)}°C concrete',
                  isLeftWorse: true,
                ),
                Divider(color: MausamColors.brdSubtle(context), height: 16),
                _buildComparisonRow(
                  context,
                  'Predicted slump margin',
                  '${(batch.slumpRetentionRatio * 100).toStringAsFixed(1)}% (${batch.slumpRetentionRatio >= 0.92 ? "Compliant" : "Below 92% SLA"})',
                  '${((batch.slumpRetentionRatio + 0.04).clamp(0.0, 0.96) * 100).toStringAsFixed(1)}% (Approved / Safe)',
                  isLeftWorse: batch.slumpRetentionRatio < 0.92,
                ),
                Divider(color: MausamColors.brdSubtle(context), height: 16),
                _buildComparisonRow(
                  context,
                  'Distance differential',
                  '28.2 km (Baseline)',
                  '+2.6 km (+5 min free-flow)',
                  isLeftWorse: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    String metric,
    String leftVal,
    String rightVal, {
    required bool isLeftWorse,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Route A: $leftVal',
                style: MausamTypography.bodyOf(context).copyWith(
                  fontSize: 11.5,
                  color: isLeftWorse ? MausamColors.highRisk : MausamColors.txtSecondary(context),
                  fontWeight: isLeftWorse ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Route B: $rightVal',
                style: MausamTypography.bodyOf(context).copyWith(
                  fontSize: 11.5,
                  color: !isLeftWorse ? MausamColors.safe : MausamColors.txtPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
