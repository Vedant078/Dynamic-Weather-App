import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/batch.dart';
import '../../services/route_service.dart';

/// Technical Live Route Map View for MAUSAM RMC Tracking.
/// Visual Anchor implementing Horizon Fleet Route Tracking Reference:
/// - Cartographic coordinate grid & dynamic geographic corridor
/// - Auto-fits viewport to selected route geometry (Section 8)
/// - Empty state before selection (Section 16)
/// - Loading state "Calculating route..." (Section 17)
/// - Error state with retry (Section 18)
/// - Traversed path (solid) vs. Remaining path (dashed forward trajectory)
/// - Vector truck position marker with directional heading & state color
/// - On-map floating operational telemetry HUD (Distance, ETA, Weather)
/// - Standard map legend (Traversed, Remaining, Bottleneck, Bypass, Hubs)
/// - Strictly location-driven from canonical RouteAssessment (PRD & Section 3-7)
class RouteMapView extends StatelessWidget {
  final BatchModel? batch;
  final String? originName;
  final String? destinationName;
  final String? activeRouteId;
  final RouteAssessment? routeAssessment;
  final LocationPoint? customOrigin;
  final LocationPoint? customDestination;
  final bool isCalculating;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isInteractive;
  final double height;
  final VoidCallback? onExpand;
  final VoidCallback? onRecalculate;
  final bool showLegend;
  final bool showFloatingHud;
  final bool showAlternateRoute;

  const RouteMapView({
    super.key,
    this.batch,
    this.originName,
    this.destinationName,
    this.activeRouteId,
    this.routeAssessment,
    this.customOrigin,
    this.customDestination,
    this.isCalculating = false,
    this.isEmpty = false,
    this.hasError = false,
    this.errorMessage,
    this.onRetry,
    this.isInteractive = false,
    this.height = 280.0,
    this.onExpand,
    this.onRecalculate,
    this.showLegend = true,
    this.showFloatingHud = true,
    this.showAlternateRoute = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);

    // Determine if map is in empty state (Section 16)
    final bool effectiveEmpty = isEmpty ||
        (routeAssessment == null &&
            batch == null &&
            (originName == null || originName!.isEmpty || destinationName == null || destinationName!.isEmpty));

    if (effectiveEmpty && !isCalculating && !hasError) {
      return _buildEmptyState(context, isDark);
    }

    final effectiveOrigin = originName ?? batch?.plantName ?? 'Ahmedabad';
    final effectiveDest = destinationName ?? batch?.projectName ?? 'Gandhinagar';
    final effectiveRouteId = activeRouteId ?? batch?.activeRouteId ?? 'route-a';

    final LocationPoint? resolvedOrigin = customOrigin;
    final LocationPoint? resolvedDest = customDestination;

    // 1. Resolve canonical RouteAssessment
    final RouteAssessment? route = routeAssessment ??
        (!effectiveEmpty
            ? RouteService.getRoute(
                originName: effectiveOrigin,
                destinationName: effectiveDest,
                preferredRouteId: effectiveRouteId,
                customOrigin: resolvedOrigin,
                customDestination: resolvedDest,
              )
            : null);

    final bool isRouteValid = route != null &&
        RouteService.validateRoute(
          route: route,
          originName: effectiveOrigin,
          destinationName: effectiveDest,
        );

    final isRouteB = route?.routeId == 'route-b';
    final isCritical = (batch?.riskLevel == RiskLevel.highRisk || batch?.riskLevel == RiskLevel.critical) ||
        (route != null && (route.expectedDelayMin > 10.0 || route.etaMinutes > 78.0));
    final isWatch = (batch?.riskLevel == RiskLevel.watch) || (route != null && route.expectedDelayMin > 4.0);

    final double elapsed = batch?.elapsedMinutes ?? 0.0;
    final double eta = batch?.etaMinutes ?? route?.etaMinutes ?? 0.0;
    final double totalEstimated = elapsed + eta > 0 ? elapsed + eta : 60.0;
    final double progress = (elapsed / totalEstimated).clamp(0.08, 0.94);

    final double distRemaining = batch?.distanceRemainingKm ?? route?.distanceKm ?? 0.0;
    final double ambientTemp = batch?.ambientTempC ?? route?.ambientTempC ?? 35.0;
    final double rainProb = batch?.precipitationProb ?? route?.precipitationProb ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F151C) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(
          color: isCritical
              ? MausamColors.highRisk.withValues(alpha: 0.35)
              : MausamColors.brd(context),
          width: isCritical ? 1.5 : 1.0,
        ),
        boxShadow: MausamSpacing.shadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map Canvas with Floating Telemetry HUD
          SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              children: [
                // Custom Canvas Map Rendering
                CustomPaint(
                  size: Size.infinite,
                  painter: _AhmedabadCorridorPainter(
                    route: route,
                    isDelayZoneActive: isCritical || (route?.routeId == 'route-a' && (route?.expectedDelayMin ?? 0) > 8.0),
                    progress: progress,
                    isDark: isDark,
                    riskLevel: batch?.riskLevel ?? (isCritical ? RiskLevel.highRisk : (isWatch ? RiskLevel.watch : RiskLevel.safe)),
                    showAlternateRoute: showAlternateRoute,
                  ),
                ),

                // Top-Left Floating Badge: Single minimal route name indicator
                if (showFloatingHud && !isCalculating && !hasError && route != null && isRouteValid)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF131B24) : Colors.white).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                        border: Border.all(color: MausamColors.brd(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.navigation2,
                            size: 11,
                            color: isRouteB ? MausamColors.safe : MausamColors.info,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            route.routeName,
                            style: MausamTypography.microOf(context).copyWith(
                              color: MausamColors.txtPrimary(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top-Right Floating Badge: Compact Weather Indicator
                if (showFloatingHud && !isCalculating && !hasError && route != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF131B24) : Colors.white).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                        border: Border.all(color: MausamColors.brd(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${ambientTemp.toStringAsFixed(1)}°C · ${rainProb.toInt()}% rain',
                        style: MausamTypography.microOf(context).copyWith(
                          color: MausamColors.txtPrimary(context),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Bottom-Left Floating Badge: Single Distance & ETA Indicator (Section 9)
                if (showFloatingHud && !isCalculating && !hasError && route != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF131B24) : Colors.white).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                        border: Border.all(color: MausamColors.brd(context)),
                      ),
                      child: Text(
                        '${distRemaining.toStringAsFixed(1)} km · ${eta.toInt()} min ETA',
                        style: MausamTypography.microOf(context).copyWith(
                          color: MausamColors.txtPrimary(context),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Bottom-Right Floating Button: Compare routes
                if (onExpand != null && !isCalculating && !hasError && route != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onExpand,
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF131B24) : Colors.white).withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                            border: Border.all(color: MausamColors.brd(context)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Compare routes',
                                style: MausamTypography.microOf(context).copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: MausamColors.info,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.arrowUpRight, size: 13, color: MausamColors.info),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Loading State: Calculating route... (Section 17)
                if (isCalculating)
                  Container(
                    color: (isDark ? const Color(0xFF0F151C) : Colors.white).withValues(alpha: 0.88),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF131B24) : Colors.white).withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                          border: Border.all(color: MausamColors.accent.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: MausamColors.accent),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Calculating route...',
                              style: MausamTypography.labelBoldOf(context).copyWith(
                                fontSize: 12,
                                letterSpacing: 0.6,
                                color: MausamColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Error State: Unable to calculate route (Section 18)
                if (hasError && !isCalculating)
                  Container(
                    color: (isDark ? const Color(0xFF0F151C) : Colors.white).withValues(alpha: 0.90),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF131B24) : Colors.white).withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                          border: Border.all(color: MausamColors.highRisk.withValues(alpha: 0.45)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.alertTriangle, size: 18, color: MausamColors.highRisk),
                                const SizedBox(width: 8),
                                Text(
                                  'Unable to calculate route.',
                                  style: MausamTypography.labelBoldOf(context).copyWith(
                                    fontSize: 13.5,
                                    color: MausamColors.highRisk,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              errorMessage ?? 'Please try another area combination.',
                              style: MausamTypography.microOf(context),
                              textAlign: TextAlign.center,
                            ),
                            if (onRetry != null) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(LucideIcons.refreshCw, size: 13),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MausamColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

              ],
            ),
          ),

          // Map Legend (Section 2.9)
          if (showLegend && route != null && !effectiveEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111822) : const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: MausamColors.brdSubtle(context), width: 1.0),
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLegendItem(
                        context,
                        color: isRouteB ? MausamColors.safe : MausamColors.info,
                        label: 'Route',
                        isSolid: true,
                      ),
                      const SizedBox(width: 12),
                      if (route.hasBottleneck && isCritical) ...[
                        _buildLegendItem(
                          context,
                          color: MausamColors.highRisk,
                          label: 'Risk segment',
                          isSquare: true,
                        ),
                        const SizedBox(width: 12),
                      ],
                      _buildLegendItem(
                        context,
                        color: MausamColors.txtPrimary(context),
                        label: 'Hub',
                        isHub: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F151C) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(color: MausamColors.brd(context)),
        boxShadow: MausamSpacing.shadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Neutral Cartographic Grid (Section 16)
          CustomPaint(
            size: Size.infinite,
            painter: _AhmedabadCorridorPainter(
              route: null,
              isDelayZoneActive: false,
              progress: 0.0,
              isDark: isDark,
              riskLevel: RiskLevel.safe,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF131B24) : Colors.white).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                border: Border.all(color: MausamColors.brd(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MausamColors.accent.withValues(alpha: 0.12),
                    ),
                    child: const Icon(LucideIcons.navigation2, size: 18, color: MausamColors.accent),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select an origin and destination to view the route.',
                    style: MausamTypography.bodyMediumOf(context).copyWith(
                      color: MausamColors.txtPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Choose areas from the dropdowns above to calculate road geometry, distance & ETA.',
                    style: MausamTypography.microOf(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    bool isSolid = false,
    bool isDashed = false,
    bool isSquare = false,
    bool isHub = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSolid)
          Container(
            width: 12,
            height: 3.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else if (isDashed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 4, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 4, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 4, height: 2, color: color),
            ],
          )
        else if (isSquare)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          )
        else if (isHub)
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: MausamColors.txtSecondary(context),
          ),
        ),
      ],
    );
  }
}

class _AhmedabadCorridorPainter extends CustomPainter {
  final RouteAssessment? route;
  final bool isDelayZoneActive;
  final double progress;
  final bool isDark;
  final RiskLevel riskLevel;
  final bool showAlternateRoute;

  _AhmedabadCorridorPainter({
    required this.route,
    required this.isDelayZoneActive,
    required this.progress,
    required this.isDark,
    required this.riskLevel,
    this.showAlternateRoute = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Subtle Cartographic Grid lines (Cartographic backdrop)
    final gridColor = isDark
        ? MausamColors.borderDark.withValues(alpha: 0.25)
        : const Color(0xFFE2E8F0);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Neutral grid early return if no route loaded (Section 16: Empty State)
    if (route == null) return;
    final r = route!;

    // Location Points resolved dynamically from canonical RouteAssessment
    final origin = r.originPoint.toOffset(size);
    final dest = r.destinationPoint.toOffset(size);

    // Primary Dynamic Spline Path (ONE visually dominant route - Section 2.3)
    final activePath = _buildSplinePath(r.primaryPathPoints, size);

    // Alternate Dynamic Spline Path
    if (showAlternateRoute && r.alternatePathPoints != null && r.alternatePathPoints!.isNotEmpty) {
      final altPath = _buildSplinePath(r.alternatePathPoints!, size);
      final inactivePaint = Paint()
        ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      _drawDashedPath(canvas, altPath, inactivePaint, dashWidth: 5.0, dashSpace: 4.0);
    }

    // Active Route Computation
    final pathMetrics = activePath.computeMetrics().toList();

    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final totalLength = metric.length;
      final traversedLength = (totalLength * progress).clamp(0.0, totalLength);

      // 1. Draw Traversed Segment (Solid vibrant path)
      final traversedPath = metric.extractPath(0, traversedLength);
      final activeColor = r.routeId == 'route-b'
          ? MausamColors.safe
          : (isDelayZoneActive ? MausamColors.highRisk : MausamColors.info);

      final traversedPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round;

      // Subtle glow behind traversed path
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(traversedPath, glowPaint);
      canvas.drawPath(traversedPath, traversedPaint);

      // 2. Draw Remaining Segment (Dashed forward trajectory)
      if (traversedLength < totalLength) {
        final remainingPath = metric.extractPath(traversedLength, totalLength);
        final remainingPaint = Paint()
          ..color = (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)).withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;

        _drawDashedPath(canvas, remainingPath, remainingPaint, dashWidth: 6.0, dashSpace: 4.0);
      }

      // 3. Highlight bottleneck zone if active
      if (r.hasBottleneck && isDelayZoneActive) {
        final bStartRatio = r.bottleneckStart ?? 0.38;
        final bEndRatio = r.bottleneckEnd ?? 0.65;
        final bottleneckStart = (totalLength * bStartRatio).clamp(0.0, totalLength);
        final bottleneckEnd = (totalLength * bEndRatio).clamp(0.0, totalLength);

        if (bottleneckStart < bottleneckEnd) {
          final bottleneckPath = metric.extractPath(bottleneckStart, bottleneckEnd);

          final bottleneckPaint = Paint()
            ..color = MausamColors.highRisk
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.2
            ..strokeCap = StrokeCap.round;

          canvas.drawPath(bottleneckPath, bottleneckPaint);

          final midTangent = metric.getTangentForOffset((bottleneckStart + bottleneckEnd) / 2);
          if (midTangent != null) {
            final delayMin = r.expectedDelayMin > 0 ? r.expectedDelayMin.toInt() : 14;
            _drawCalloutTag(
              canvas,
              midTangent.position + const Offset(0, 16),
              '⚠️ Congestion +$delayMin min',
              MausamColors.highRisk,
            );
          }
        }
      }

      // 4. Draw Truck Position Marker at tangent position
      final truckTangent = metric.getTangentForOffset(traversedLength);
      if (truckTangent != null) {
        _drawTruckMarker(
          canvas,
          truckTangent.position,
          truckTangent.angle,
          isHighRisk: isDelayZoneActive,
          color: activeColor,
        );
      }
    }

    // Origin Marker (Plant / Origin Area - Section 6: ● Origin marker)
    _drawHubMarker(
      canvas,
      origin,
      label: r.origin.shortName,
      color: MausamColors.info,
      isOrigin: true,
    );

    // Destination Marker (Project Site / Destination Area - Section 6: ● Destination marker)
    _drawHubMarker(
      canvas,
      dest,
      label: r.destination.shortName,
      color: MausamColors.safe,
      isOrigin: false,
    );
  }

  Path _buildSplinePath(List<MapPoint> points, Size size) {
    final path = Path();
    if (points.isEmpty) return path;
    final first = points.first.toOffset(size);
    path.moveTo(first.dx, first.dy);

    if (points.length == 2) {
      final p1 = points[1].toOffset(size);
      path.lineTo(p1.dx, p1.dy);
      return path;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1].toOffset(size) : points[i].toOffset(size);
      final p1 = points[i].toOffset(size);
      final p2 = points[i + 1].toOffset(size);
      final p3 = i < points.length - 2 ? points[i + 2].toOffset(size) : p2;

      final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 4.5, p1.dy + (p2.dy - p0.dy) / 4.5);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 4.5, p2.dy - (p3.dy - p1.dy) / 4.5);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {double dashWidth = 6.0, double dashSpace = 4.0}) {
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawCalloutTag(Canvas canvas, Offset pos, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: pos,
        width: textPainter.width + 10,
        height: textPainter.height + 5,
      ),
      const Radius.circular(3),
    );

    canvas.drawRRect(
      bgRect,
      Paint()..color = (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2));
  }

  void _drawHubMarker(
    Canvas canvas,
    Offset pos, {
    required String label,
    required Color color,
    required bool isOrigin,
  }) {
    final fillPaint = Paint()..color = color;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Hub marker circle
    canvas.drawCircle(pos, 7.5, ringPaint);
    canvas.drawCircle(pos, 4.5, fillPaint);
    canvas.drawCircle(pos, 1.8, Paint()..color = Colors.white);

    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final yOffset = isOrigin ? 10.0 : -20.0;
    labelPainter.paint(
      canvas,
      Offset(pos.dx - labelPainter.width / 2, pos.dy + yOffset),
    );
  }

  void _drawTruckMarker(
    Canvas canvas,
    Offset pos,
    double angle, {
    required bool isHighRisk,
    required Color color,
  }) {
    canvas.drawCircle(pos, 13.0, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(pos, 9.0, Paint()..color = isDark ? const Color(0xFF0F172A) : Colors.white);
    canvas.drawCircle(pos, 9.0, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final arrowPath = Path()
      ..moveTo(4.5, 0)
      ..lineTo(-3.0, -3.5)
      ..lineTo(-1.2, 0)
      ..lineTo(-3.0, 3.5)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AhmedabadCorridorPainter oldDelegate) {
    return oldDelegate.route != route ||
        oldDelegate.isDelayZoneActive != isDelayZoneActive ||
        oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.riskLevel != riskLevel ||
        oldDelegate.showAlternateRoute != showAlternateRoute;
  }
}
