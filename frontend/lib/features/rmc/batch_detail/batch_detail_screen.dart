import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/mausam_colors.dart';
import '../../../core/theme/mausam_spacing.dart';
import '../../../core/theme/mausam_typography.dart';
import '../../../models/batch.dart';
import '../../../state/mausam_state.dart';
import '../../../design_system/components/status_pill.dart';
import '../../../design_system/components/telemetry_metric.dart';
import '../../../design_system/components/route_map_view.dart';

/// Simplified, High-Hierarchy Tracking Delivery Screen for MAUSAM.
///
/// Implements 5-Level Operational Hierarchy (PRD & Section 10-22):
/// - LEVEL 1: Delivery Identity (Batch ID, RMC grade/volume, Origin → Destination, status)
/// - LEVEL 2: Dominant Live Route Map (Visual anchor, dynamic location-driven trajectory)
/// - LEVEL 3: Current Status & Primary Grounded "WHY" (Single high-impact operational signal)
/// - LEVEL 4: Essential Telemetry (Only 4 core metrics: ETA, Transit, Slump, Concrete Temp)
/// - LEVEL 5: Context-Aware Action (Intervene, Reroute, Log Site Arrival)
/// - Secondary details (Microclimate, Full Factor Matrix, Timeline) accessible via clean expandable panel.
class BatchDetailScreen extends StatefulWidget {
  final MausamState state;
  final VoidCallback onNavigateToRoutes;
  final VoidCallback onNavigateToOutcome;

  const BatchDetailScreen({
    super.key,
    required this.state,
    required this.onNavigateToRoutes,
    required this.onNavigateToOutcome,
  });

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  bool _showSecondaryDetails = true;

  @override
  Widget build(BuildContext context) {
    final batch = widget.state.selectedBatch;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24.0 : 16.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===============================================================
              // LEVEL 1: DELIVERY IDENTITY & FLEET SELECTOR
              // ===============================================================
              _buildDeliveryIdentityHeader(context, batch, statusColor, statusLabel),
              const SizedBox(height: 16),

              // ===============================================================
              // DESKTOP: 2-COLUMN LAYOUT (Map dominates 62%, Status/Telemetry 38%)
              // MOBILE: FOCUSED 1-COLUMN FLOW (Identity → Map → Status → Telemetry → Action)
              // ===============================================================
              if (isDesktop)
                _buildDesktopLayout(context, batch, statusColor, isCritical, isWatch)
              else
                _buildMobileLayout(context, batch, statusColor, isCritical, isWatch),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // LEVEL 1: DELIVERY IDENTITY HEADER
  // ===========================================================================
  Widget _buildDeliveryIdentityHeader(
    BuildContext context,
    BatchModel batch,
    Color statusColor,
    String statusLabel,
  ) {
    final isDark = MausamColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(color: MausamColors.brd(context)),
        boxShadow: MausamSpacing.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vehicle Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Icon(LucideIcons.truck, size: 20, color: statusColor),
              ),
              const SizedBox(width: 12),

              // Batch Identity & Concrete Mix
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Batch #${batch.batchCode}',
                          style: MausamTypography.headingXL.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: MausamColors.txtPrimary(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'TRC-042',
                            style: MausamTypography.microOf(context).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              color: MausamColors.txtPrimary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${batch.concreteGrade} · ${batch.volumeM3} m³ · Target Slump ${batch.targetSlumpMm.toInt()} mm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MausamTypography.microOf(context).copyWith(
                        fontSize: 12,
                        color: MausamColors.txtSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Pill
              StatusPill(label: statusLabel, color: statusColor),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: MausamColors.brdSubtle(context)),
          const SizedBox(height: 10),

          // Corridor Origin -> Destination Strip
          Row(
            children: [
              const Icon(LucideIcons.factory, size: 14, color: MausamColors.info),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  batch.plantName,
                  style: MausamTypography.labelBoldOf(context).copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(LucideIcons.arrowRight, size: 13, color: MausamColors.txtMuted(context)),
              ),
              const Icon(LucideIcons.mapPin, size: 14, color: MausamColors.safe),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  batch.projectName,
                  textAlign: TextAlign.end,
                  style: MausamTypography.labelBoldOf(context).copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Active Fleet Quick Selector
          if (widget.state.batches.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Active fleet:',
                  style: MausamTypography.microOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    color: MausamColors.txtMuted(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: widget.state.batches.map((b) {
                        final isSelected = b.batchId == batch.batchId;
                        final isCrit = b.riskLevel == RiskLevel.highRisk || b.riskLevel == RiskLevel.critical;
                        final isW = b.riskLevel == RiskLevel.watch;
                        final bColor = isCrit ? MausamColors.highRisk : (isW ? MausamColors.watch : MausamColors.safe);

                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InkWell(
                            onTap: () => widget.state.selectBatch(b.batchId),
                            borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                                border: Border.all(
                                  color: isSelected ? MausamColors.info : MausamColors.brdSubtle(context),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: bColor),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '#${b.batchCode}',
                                    style: MausamTypography.microOf(context).copyWith(
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 11,
                                      color: isSelected
                                          ? MausamColors.txtPrimary(context)
                                          : MausamColors.txtSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // DESKTOP LAYOUT (Dominant Map 62% Flex, Operational Command 38% Flex)
  // ===========================================================================
  Widget _buildDesktopLayout(
    BuildContext context,
    BatchModel batch,
    Color statusColor,
    bool isCritical,
    bool isWatch,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: LEVEL 2 LIVE ROUTE MAP (Dominant Visual Anchor)
        Expanded(
          flex: 58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RouteMapView(
                batch: batch,
                height: 420,
                onExpand: widget.onNavigateToRoutes,
                showLegend: true,
                showFloatingHud: true,
              ),
              const SizedBox(height: 14),

              // Secondary Details Expander
              _buildSecondaryDetailsExpander(context, batch, statusColor, isCritical, isWatch),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Right Column: LEVEL 3 STATUS → LEVEL 4 TELEMETRY → LEVEL 5 ACTIONS
        Expanded(
          flex: 42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEVEL 3: CURRENT STATUS & PRIMARY WHY
              _buildStatusAndWhyCard(context, batch, statusColor, isCritical, isWatch),
              const SizedBox(height: 16),

              // LEVEL 4: ESSENTIAL TELEMETRY (Only 4 Core Metrics)
              _buildEssentialTelemetrySection(context, batch),
              const SizedBox(height: 16),

              // LEVEL 5: ACTION DECISION AREA
              _buildActionArea(context, batch, isCritical),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT (Clean Single-Column Flow with Zero Overflow)
  // ===========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    BatchModel batch,
    Color statusColor,
    bool isCritical,
    bool isWatch,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEVEL 2: LIVE ROUTE MAP (Prominent Visual Anchor)
        RouteMapView(
          batch: batch,
          height: 280,
          onExpand: widget.onNavigateToRoutes,
          showLegend: true,
          showFloatingHud: true,
        ),
        const SizedBox(height: 16),

        // LEVEL 3: CURRENT STATUS & PRIMARY WHY
        _buildStatusAndWhyCard(context, batch, statusColor, isCritical, isWatch),
        const SizedBox(height: 16),

        // LEVEL 4: ESSENTIAL TELEMETRY (Only 4 Core Metrics)
        _buildEssentialTelemetrySection(context, batch),
        const SizedBox(height: 16),

        // LEVEL 5: ACTION DECISION AREA
        _buildActionArea(context, batch, isCritical),
        const SizedBox(height: 16),

        // Secondary Details Expander
        _buildSecondaryDetailsExpander(context, batch, statusColor, isCritical, isWatch),
      ],
    );
  }

  // ===========================================================================
  // LEVEL 3: CURRENT STATUS & PRIMARY OPERATIONAL "WHY"
  // ===========================================================================
  Widget _buildStatusAndWhyCard(
    BuildContext context,
    BatchModel batch,
    Color statusColor,
    bool isCritical,
    bool isWatch,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(
          color: isCritical
              ? MausamColors.highRisk.withValues(alpha: 0.35)
              : MausamColors.brd(context),
          width: isCritical ? 1.5 : 1.0,
        ),
        boxShadow: MausamSpacing.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Signal Headline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery risk state',
                      style: MausamTypography.microOf(context).copyWith(
                        fontSize: 11,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w700,
                        color: MausamColors.txtMuted(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${batch.deliveryRisk.toInt()}',
                          style: MausamTypography.tabularOf(context).copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          ' / 100',
                          style: MausamTypography.microOf(context).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: MausamColors.txtMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: isCritical ? 'ACTION REQUIRED' : (isWatch ? 'WATCH' : 'SAFE'),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Direct Operational Grounding (WHY)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCritical
                  ? MausamColors.highRisk.withValues(alpha: 0.08)
                  : (isWatch ? MausamColors.watch.withValues(alpha: 0.08) : MausamColors.surfSecondary(context)),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(
                color: isCritical
                    ? MausamColors.highRisk.withValues(alpha: 0.25)
                    : (isWatch ? MausamColors.watch.withValues(alpha: 0.25) : MausamColors.brdSubtle(context)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isCritical ? LucideIcons.alertTriangle : (isWatch ? LucideIcons.alertCircle : LucideIcons.checkCircle2),
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRIMARY RISK DRIVER',
                        style: MausamTypography.microOf(context).copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        batch.primaryDriver,
                        style: MausamTypography.bodyMediumOf(context).copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LEVEL 4: ESSENTIAL TELEMETRY (Only 4 Key Metrics: ETA, Transit, Slump, Temp)
  // ===========================================================================
  Widget _buildEssentialTelemetrySection(BuildContext context, BatchModel batch) {
    final bool isSlaBreached = (batch.elapsedMinutes + batch.etaMinutes) > 78.0;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Live hydration & transit telemetry',
                  style: MausamTypography.labelBoldOf(context).copyWith(
                    fontSize: 13,
                    color: MausamColors.txtPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '4 core signals',
                style: MausamTypography.microOf(context).copyWith(
                  fontSize: 10.5,
                  color: MausamColors.txtMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Telemetry Grid (Typography-driven, clean dividers)
          Row(
            children: [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.hourglass,
                  label: 'Elapsed transit',
                  value: '${batch.elapsedMinutes.toInt()}',
                  unit: 'min',
                  delta: isSlaBreached ? 'Exceeds 78m SLA' : 'Max 78m SLA',
                  isWarning: isSlaBreached,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.navigation,
                  label: 'Remaining distance',
                  value: '${batch.distanceRemainingKm}',
                  unit: 'km',
                  delta: '+${batch.etaMinutes.toInt()}m ETA',
                  isWarning: isSlaBreached,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.percent,
                  label: 'Slump retention',
                  value: (batch.slumpRetentionRatio * 100).toStringAsFixed(1),
                  unit: '%',
                  delta: '${batch.currentSlumpMm.toInt()} mm slump',
                  isWarning: batch.slumpRetentionRatio < 0.92,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.thermometer,
                  label: 'Concrete temp',
                  value: '${batch.concreteTempC}',
                  unit: '°C',
                  delta: batch.concreteTempC > 34.0 ? '+2.4°C rise' : 'Nominal',
                  isWarning: batch.concreteTempC > 34.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LEVEL 5: ACTION DECISION AREA
  // ===========================================================================
  Widget _buildActionArea(BuildContext context, BatchModel batch, bool isCritical) {
    final isDelivered = batch.status == 'DELIVERED';

    if (isDelivered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MausamColors.safe.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
          border: Border.all(color: MausamColors.safe.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.checkCheck, size: 18, color: MausamColors.safe),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delivery completed & slump verified on specification.',
                    style: MausamTypography.bodyMediumOf(context).copyWith(
                      color: MausamColors.safe,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: widget.onNavigateToOutcome,
                icon: const Icon(LucideIcons.clipboardCheck, size: 15, color: MausamColors.safe),
                label: const Text('View Quality Assurance Outcome Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MausamColors.safe,
                  side: BorderSide(color: MausamColors.safe.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isCritical) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: MausamColors.surf(context),
          borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
          border: Border.all(color: MausamColors.highRisk.withValues(alpha: 0.35), width: 1.5),
          boxShadow: MausamSpacing.shadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.alertOctagon, size: 16, color: MausamColors.highRisk),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OPERATIONAL INTERVENTION REQUIRED',
                    style: MausamTypography.microOf(context).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.3,
                      color: MausamColors.highRisk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Transit is projected to exceed the safe operating window. Divert to alternative bypass to protect concrete slump.',
              style: MausamTypography.bodyOf(context).copyWith(
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Primary Action: Apply Alternative Route B
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.state.applyAlternativeRoute();
                  widget.onNavigateToRoutes();
                },
                icon: const Icon(LucideIcons.navigation, size: 16),
                label: const Text(
                  'Apply Route B Bypass (-9 min)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
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
            const SizedBox(height: 10),

            // Secondary Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.state.addRetarderAdmixture,
                    icon: const Icon(LucideIcons.beaker, size: 14),
                    label: const Text(
                      'Inject retarder',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: MausamColors.brd(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.state.confirmOverride,
                    icon: const Icon(LucideIcons.shieldAlert, size: 14),
                    label: const Text(
                      'Log override',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: MausamColors.brd(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Nominal / Safe State
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(color: MausamColors.brd(context)),
        boxShadow: MausamSpacing.shadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(LucideIcons.checkCircle2, size: 16, color: MausamColors.safe),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transit within nominal specification envelope. No intervention required.',
                  style: MausamTypography.bodyOf(context).copyWith(
                    fontSize: 12,
                    color: MausamColors.safe,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: widget.onNavigateToOutcome,
              icon: const Icon(LucideIcons.clipboardCheck, size: 16, color: MausamColors.safe),
              label: const Text(
                'Log site arrival & verify slump outcome',
                style: TextStyle(color: MausamColors.safe, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: MausamColors.safe.withValues(alpha: 0.4), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECONDARY DETAILS: COLLAPSIBLE EXPANDER (Timeline, Microclimate, Factor Matrix)
  // ===========================================================================
  Widget _buildSecondaryDetailsExpander(
    BuildContext context,
    BatchModel batch,
    Color statusColor,
    bool isCritical,
    bool isWatch,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(color: MausamColors.brd(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showSecondaryDetails = !_showSecondaryDetails),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(
                    _showSecondaryDetails ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 16,
                    color: MausamColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _showSecondaryDetails
                          ? 'Hide Corridor & Environmental Details'
                          : 'Show Corridor Microclimate & Contributing Factors',
                      overflow: TextOverflow.ellipsis,
                      style: MausamTypography.microOf(context).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: MausamColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${batch.ambientTempC}°C · ${batch.precipitationProb.toInt()}% rain',
                    style: MausamTypography.microOf(context).copyWith(
                      color: MausamColors.txtMuted(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showSecondaryDetails) ...[
            Divider(height: 1, color: MausamColors.brdSubtle(context)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linear Journey Progress Bar (Lesson 6)
                  _buildLinearJourneyProgressBar(context, batch, statusColor),
                  const SizedBox(height: 16),

                  // Corridor Microclimate Exposure
                  _buildMicroclimateStrip(context, batch),
                  const SizedBox(height: 16),

                  // Contributing Factors Breakdown
                  Text(
                    'Contributing risk factors',
                    style: MausamTypography.microOf(context).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFactorRow(
                    context,
                    icon: LucideIcons.trafficCone,
                    label: 'Route & traffic congestion',
                    value: batch.etaMinutes > 32 ? '+14 min bottleneck' : 'Normal flow',
                    isNegative: batch.etaMinutes > 32,
                  ),
                  Divider(height: 12, color: MausamColors.brdSubtle(context)),
                  _buildFactorRow(
                    context,
                    icon: LucideIcons.thermometer,
                    label: 'Hydration temperature',
                    value: '${batch.concreteTempC}°C (${batch.concreteTempC > 34.0 ? 'Accelerating' : 'Nominal'})',
                    isNegative: batch.concreteTempC > 34.0,
                  ),
                  Divider(height: 12, color: MausamColors.brdSubtle(context)),
                  _buildFactorRow(
                    context,
                    icon: LucideIcons.cloudRain,
                    label: 'Route rain probability',
                    value: '${batch.precipitationProb.toInt()}% along corridor',
                    isNegative: batch.precipitationProb > 40.0,
                  ),
                  Divider(height: 12, color: MausamColors.brdSubtle(context)),
                  _buildFactorRow(
                    context,
                    icon: LucideIcons.percent,
                    label: 'Slump retention ratio',
                    value: '${(batch.slumpRetentionRatio * 100).toStringAsFixed(1)}% (92.0% SLA)',
                    isNegative: batch.slumpRetentionRatio < 0.92,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinearJourneyProgressBar(
    BuildContext context,
    BatchModel batch,
    Color statusColor,
  ) {
    final double totalEstimated = (batch.elapsedMinutes + batch.etaMinutes > 0)
        ? (batch.elapsedMinutes + batch.etaMinutes)
        : 60.0;
    final double progress = (batch.elapsedMinutes / totalEstimated).clamp(0.06, 0.94);
    final bool isSlaBreached = (batch.elapsedMinutes + batch.etaMinutes) > 78.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Track
        LayoutBuilder(
          builder: (context, trackConstraints) {
            final double trackWidth = trackConstraints.maxWidth;
            final double truckX = (trackWidth * progress) - 13;
            final double slaRatio = (78.0 / (totalEstimated > 78.0 ? totalEstimated : 78.0)).clamp(0.1, 0.95);
            final double slaX = trackWidth * slaRatio;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 6,
                  width: trackWidth,
                  decoration: BoxDecoration(
                    color: MausamColors.surfSecondary(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  height: 6,
                  width: trackWidth * progress,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Positioned(
                  left: slaX,
                  top: -3,
                  child: Container(
                    width: 2,
                    height: 12,
                    color: isSlaBreached ? MausamColors.highRisk : MausamColors.txtMuted(context),
                  ),
                ),
                Positioned(
                  left: truckX.clamp(0.0, trackWidth - 24),
                  top: -8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: MausamColors.surf(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(LucideIcons.truck, size: 11, color: statusColor),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // Sub-Track Metrics
        Row(
          children: [
            Expanded(
              child: Text(
                'Elapsed: ${batch.elapsedMinutes.toInt()}m',
                style: MausamTypography.microOf(context).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: MausamColors.txtSecondary(context),
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${batch.distanceRemainingKm} km left',
                textAlign: TextAlign.center,
                style: MausamTypography.microOf(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: MausamColors.txtPrimary(context),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'ETA: +${batch.etaMinutes.toInt()}m',
                textAlign: TextAlign.end,
                style: MausamTypography.microOf(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: isSlaBreached ? MausamColors.highRisk : MausamColors.safe,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMicroclimateStrip(BuildContext context, BatchModel batch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MausamColors.surfSecondary(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        border: Border.all(color: MausamColors.brdSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Corridor microclimate context',
            style: MausamTypography.microOf(context).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMicroclimateMetric(
                  context,
                  icon: LucideIcons.sun,
                  label: 'Ambient temp',
                  value: '${batch.ambientTempC}°C',
                ),
              ),
              _buildVerticalDivider(context),
              Expanded(
                child: _buildMicroclimateMetric(
                  context,
                  icon: LucideIcons.droplets,
                  label: 'Humidity',
                  value: '48%',
                ),
              ),
              _buildVerticalDivider(context),
              Expanded(
                child: _buildMicroclimateMetric(
                  context,
                  icon: LucideIcons.wind,
                  label: 'Wind velocity',
                  value: '16 km/h',
                ),
              ),
              _buildVerticalDivider(context),
              Expanded(
                child: _buildMicroclimateMetric(
                  context,
                  icon: LucideIcons.cloudRain,
                  label: 'Rain prob',
                  value: '${batch.precipitationProb.toInt()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroclimateMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 13, color: MausamColors.info),
        const SizedBox(height: 2),
        Text(
          value,
          style: MausamTypography.labelBoldOf(context).copyWith(fontSize: 11.5),
        ),
        Text(
          label,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 9,
            color: MausamColors.txtMuted(context),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: MausamColors.brdSubtle(context),
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
              fontSize: 11.5,
              color: MausamColors.txtPrimary(context),
            ),
          ),
        ),
        Text(
          value,
          style: MausamTypography.labelBoldOf(context).copyWith(
            fontSize: 11.5,
            color: isNegative ? MausamColors.highRisk : MausamColors.txtSecondary(context),
          ),
        ),
      ],
    );
  }
}
