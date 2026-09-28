import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/mausam_colors.dart';
import '../../../core/theme/mausam_spacing.dart';
import '../../../core/theme/mausam_typography.dart';
import '../../../models/area.dart';
import '../../../models/batch.dart';
import '../../../models/delivery_order_draft.dart';
import '../../../services/area_service.dart';
import '../../../services/route_service.dart';
import '../../../state/mausam_state.dart';
import '../../../design_system/components/route_map_view.dart';
import '../../../design_system/components/searchable_area_dropdown.dart';
import '../../../design_system/components/status_pill.dart';

/// RMC Route Intelligence Screen (PRD.md Section 3 & 8, User Request Section 1-22)
/// Implements generalized area dropdowns with dynamic map route:
/// 1. Origin selector (FROM / Plant / Origin)
/// 2. Destination selector (TO / Project Site / Destination)
/// 3. Map (Dynamic road route polyline, auto-fit viewport, empty/loading/error states)
/// 4. Route summary (Distance XX.X km, ETA XX min, Traffic status)
/// 5. Risk / Decision (Travel Risk, Heat Risk, Delivery Risk, Overall Risk)
/// 6. Relevant financial impact (Transport cost, loss exposure)
/// 7. Secondary expandable details
class RouteIntelligenceScreen extends StatefulWidget {
  final MausamState state;
  final Area? initialOrigin;
  final Area? initialDestination;

  const RouteIntelligenceScreen({
    super.key,
    required this.state,
    this.initialOrigin,
    this.initialDestination,
  });

  @override
  State<RouteIntelligenceScreen> createState() => _RouteIntelligenceScreenState();
}

class _RouteIntelligenceScreenState extends State<RouteIntelligenceScreen> {
  Area? _originArea;
  Area? _destinationArea;

  RouteAssessment? _activeRoute;
  List<RouteAssessment> _candidateRoutes = [];
  String _selectedRouteId = 'route-a';

  DeliveryRiskAssessment? _currentRisk;
  bool _isCalculating = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showSecondaryDetails = false;

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Corridor quick-preset shortcuts for testing required combinations (Section 21)
  final List<Map<String, String>> _corridorShortcuts = [
    {'from': 'Ahmedabad', 'to': 'Gandhinagar', 'label': 'Ahmedabad → Gandhinagar'},
    {'from': 'Ahmedabad', 'to': 'Vadodara', 'label': 'Ahmedabad → Vadodara'},
    {'from': 'Vadodara', 'to': 'Surat', 'label': 'Vadodara → Surat'},
    {'from': 'Surat', 'to': 'Ahmedabad', 'label': 'Surat → Ahmedabad'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialOrigin != null && widget.initialDestination != null) {
      _originArea = widget.initialOrigin;
      _destinationArea = widget.initialDestination;
      _calculateRoute();
    }
  }

  void _onOriginChanged(Area? newArea) {
    if (_originArea == newArea) return;
    setState(() {
      _originArea = newArea;
      _activeRoute = null; // Stale route immediately cleared (Section 19)
      _candidateRoutes = [];
      _currentRisk = null;
    });

    if (_originArea != null && _destinationArea != null) {
      _calculateRoute();
    }
  }

  void _onDestinationChanged(Area? newArea) {
    if (_destinationArea == newArea) return;
    setState(() {
      _destinationArea = newArea;
      _activeRoute = null; // Stale route immediately cleared (Section 19)
      _candidateRoutes = [];
      _currentRisk = null;
    });

    if (_originArea != null && _destinationArea != null) {
      _calculateRoute();
    }
  }

  void _applyCorridorShortcut(String fromName, String toName) {
    final fromArea = AreaService.findAreaByName(fromName);
    final toArea = AreaService.findAreaByName(toName);

    if (fromArea != null && toArea != null) {
      setState(() {
        _originArea = fromArea;
        _destinationArea = toArea;
        _activeRoute = null; // Invalidate previous route immediately (Section 19)
        _candidateRoutes = [];
        _currentRisk = null;
      });
      _calculateRoute();
    }
  }

  void _swapAreas() {
    if (_originArea == null && _destinationArea == null) return;
    final temp = _originArea;
    setState(() {
      _originArea = _destinationArea;
      _destinationArea = temp;
      _activeRoute = null; // Invalidate stale route (Section 19)
      _candidateRoutes = [];
      _currentRisk = null;
    });

    if (_originArea != null && _destinationArea != null) {
      _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    if (_originArea == null || _destinationArea == null) return;

    setState(() {
      _isCalculating = true; // Loading State (Section 17)
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final originPt = LocationPoint.fromArea(_originArea!, isPlant: true);
      final destPt = LocationPoint.fromArea(_destinationArea!, isPlant: false);

      // 1. Fetch real highway routing (OSRM live with verified corridor geometry - Section 7)
      final activeAssessment = await RouteService.fetchDynamicRoute(
        origin: originPt,
        destination: destPt,
        preferredRouteId: _selectedRouteId,
      );

      final candidateAssessments = RouteService.getCandidateRoutes(
        originName: _originArea!.name,
        destinationName: _destinationArea!.name,
        customOrigin: originPt,
        customDestination: destPt,
      );

      // 2. Recalculate RMC Risk using actual route distance, duration, and weather (Section 11)
      final draft = DeliveryOrderDraft(
        batchCode: 'RMC-NAV',
        plantId: _originArea!.id,
        plantName: _originArea!.name,
        projectId: _destinationArea!.id,
        projectName: _destinationArea!.name,
        concreteGrade: 'M35',
        volumeM3: 6.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 33.5,
        ambientTempC: activeAssessment.ambientTempC,
        humidityPct: 52.0,
        admixtureRetarder: 'None',
        selectedRouteId: _selectedRouteId,
        plannedTransitMinutes: activeAssessment.baseTransitMinutes,
        expectedDelayMin: activeAssessment.expectedDelayMin,
        plantLat: _originArea!.latitude,
        plantLng: _originArea!.longitude,
        projectLat: _destinationArea!.latitude,
        projectLng: _destinationArea!.longitude,
      );

      final risk = await widget.state.riskEngine.calculateRisk(draft);

      if (mounted) {
        setState(() {
          _activeRoute = activeAssessment;
          _candidateRoutes = candidateAssessments;
          _currentRisk = risk;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _hasError = true;
          _errorMessage = 'Unable to calculate route. Please try another area combination.';
        });
      }
    }
  }

  void _onSelectRoute(String routeId) {
    if (_originArea == null || _destinationArea == null) return;
    setState(() {
      _selectedRouteId = routeId;
    });
    _calculateRoute();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);
    final hasBothAreas = _originArea != null && _destinationArea != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
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
                        'Weather-weighted dynamic corridor navigation',
                        style: MausamTypography.microOf(context),
                      ),
                    ],
                  ),
                  if (_activeRoute != null)
                    StatusPill(
                      label: _activeRoute!.routeId == 'route-b' ? 'ROUTE B ACTIVE' : 'ROUTE A ACTIVE',
                      color: _activeRoute!.routeId == 'route-b' ? MausamColors.safe : MausamColors.info,
                      icon: LucideIcons.navigation2,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // ==============================================================
              // SECTION 1: ORIGIN & DESTINATION SELECTORS (Hierarchy 1 & 2)
              // ==============================================================
              Container(
                padding: const EdgeInsets.all(16),
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
                        Row(
                          children: [
                            Icon(LucideIcons.route, size: 16, color: MausamColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Delivery Corridor Selection',
                              style: MausamTypography.labelBoldOf(context).copyWith(
                                fontSize: 13.5,
                                color: MausamColors.txtPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        if (_originArea != null || _destinationArea != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _originArea = null;
                                _destinationArea = null;
                                _activeRoute = null;
                                _candidateRoutes = [];
                                _currentRisk = null;
                                _hasError = false;
                              });
                            },
                            icon: const Icon(LucideIcons.rotateCcw, size: 12),
                            label: const Text('Reset', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: MausamColors.txtMuted(context),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Two Area Dropdowns (Section 1)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 560;
                        if (isCompact) {
                          return Column(
                            children: [
                              SearchableAreaDropdown(
                                label: 'FROM (PLANT / ORIGIN)',
                                hint: 'Select origin area',
                                selectedArea: _originArea,
                                icon: LucideIcons.factory,
                                onChanged: _onOriginChanged,
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: IconButton(
                                  icon: const Icon(LucideIcons.arrowDownUp, size: 16),
                                  tooltip: 'Swap origin and destination',
                                  color: MausamColors.txtSecondary(context),
                                  onPressed: _swapAreas,
                                ),
                              ),
                              const SizedBox(height: 2),
                              SearchableAreaDropdown(
                                label: 'TO (PROJECT SITE / DESTINATION)',
                                hint: 'Select destination area',
                                selectedArea: _destinationArea,
                                icon: LucideIcons.mapPin,
                                onChanged: _onDestinationChanged,
                              ),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: SearchableAreaDropdown(
                                label: 'FROM (PLANT / ORIGIN)',
                                hint: 'Select origin area',
                                selectedArea: _originArea,
                                icon: LucideIcons.factory,
                                onChanged: _onOriginChanged,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: IconButton(
                                icon: const Icon(LucideIcons.arrowLeftRight, size: 16),
                                tooltip: 'Swap origin and destination',
                                color: MausamColors.txtSecondary(context),
                                onPressed: _swapAreas,
                              ),
                            ),
                            Expanded(
                              child: SearchableAreaDropdown(
                                label: 'TO (PROJECT SITE / DESTINATION)',
                                hint: 'Select destination area',
                                selectedArea: _destinationArea,
                                icon: LucideIcons.mapPin,
                                onChanged: _onDestinationChanged,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quick Corridor Presets (Required test combinations - Section 21)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Test corridors:',
                          style: MausamTypography.microOf(context).copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ..._corridorShortcuts.map((sc) {
                          final isSelected = _originArea?.name == sc['from'] && _destinationArea?.name == sc['to'];
                          return InkWell(
                            onTap: () => _applyCorridorShortcut(sc['from']!, sc['to']!),
                            borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? MausamColors.accent.withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                                border: Border.all(
                                  color: isSelected ? MausamColors.accent : MausamColors.brdSubtle(context),
                                ),
                              ),
                              child: Text(
                                sc['label']!,
                                style: MausamTypography.microOf(context).copyWith(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? MausamColors.accent : MausamColors.txtSecondary(context),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==============================================================
              // SECTION 2: MAP VIEW (Hierarchy 3)
              // ==============================================================
              RouteMapView(
                height: 230,
                isEmpty: !hasBothAreas,
                isCalculating: _isCalculating,
                hasError: _hasError,
                errorMessage: _errorMessage,
                onRetry: _calculateRoute,
                routeAssessment: _activeRoute,
                originName: _originArea?.name,
                destinationName: _destinationArea?.name,
                activeRouteId: _selectedRouteId,
                isInteractive: true,
                showLegend: hasBothAreas && !_hasError,
                showFloatingHud: hasBothAreas && !_hasError,
              ),
              const SizedBox(height: 16),

              // ==============================================================
              // SECTIONS 3, 4, 5: ROUTE SUMMARY + RISK + FINANCIAL IMPACT
              // (Only shown when both areas are selected and route is calculated)
              // ==============================================================
              if (hasBothAreas && _activeRoute != null && !_isCalculating) ...[
                // 3. Route Summary (Hierarchy 4)
                _buildRouteSummarySection(context),
                const SizedBox(height: 16),

                // 4. Risk / Decision Section (Hierarchy 5)
                _buildRiskDecisionSection(context),
                const SizedBox(height: 16),

                // 5. Relevant Financial Impact (Hierarchy 6)
                _buildFinancialImpactSection(context),
                const SizedBox(height: 16),

                // 6. Secondary technical details collapsible
                _buildSecondaryDetailsCollapsible(context),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HIERARCHY 4: ROUTE SUMMARY
  // ===========================================================================
  Widget _buildRouteSummarySection(BuildContext context) {
    final route = _activeRoute!;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'Route summary',
                style: MausamTypography.labelBoldOf(context).copyWith(
                  fontSize: 13.5,
                  color: MausamColors.txtPrimary(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: MausamColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                ),
                child: Text(
                  route.trafficLevel,
                  style: MausamTypography.microOf(context).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MausamColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Distance + ETA + Corridor + Weather Grid (Section 9 & 10)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'DISTANCE',
                  value: '${route.distanceKm.toStringAsFixed(1)} km',
                  icon: LucideIcons.milestone,
                  color: MausamColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'ESTIMATED TRAVEL TIME',
                  value: '${route.etaMinutes.toInt()} min',
                  icon: LucideIcons.clock,
                  color: route.etaMinutes > 78.0 ? MausamColors.highRisk : MausamColors.safe,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'CORRIDOR WEATHER',
                  value: '${route.ambientTempC.toStringAsFixed(1)}°C',
                  subtitle: '${route.precipitationProb.toInt()}% rain',
                  icon: LucideIcons.sun,
                  color: route.ambientTempC >= 38.0 ? MausamColors.watch : MausamColors.txtPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Corridor Name & Bottleneck note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: MausamColors.surfSecondary(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(color: MausamColors.brdSubtle(context)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.map, size: 14, color: MausamColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.primaryDriver,
                    style: MausamTypography.microOf(context).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Candidate Route Selection Chips (Route A vs Route B Expressway)
          if (_candidateRoutes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Route corridor options:',
              style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _candidateRoutes.map((cand) {
                final isSelected = cand.routeId == _selectedRouteId;
                return ChoiceChip(
                  label: Text(
                    '${cand.routeName} · ${cand.distanceKm} km · ${cand.etaMinutes.toInt()}m',
                    style: MausamTypography.microOf(context).copyWith(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : MausamColors.txtPrimary(context),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: MausamColors.accent,
                  backgroundColor: MausamColors.surfSecondary(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                    side: BorderSide(
                      color: isSelected ? MausamColors.accent : MausamColors.brdSubtle(context),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) _onSelectRoute(cand.routeId);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // HIERARCHY 5: RISK & OPERATIONAL DECISION
  // ===========================================================================
  Widget _buildRiskDecisionSection(BuildContext context) {
    final risk = _currentRisk;
    if (risk == null) return const SizedBox();

    final isCritical = risk.riskLevel == RiskLevel.critical;
    final isHigh = risk.riskLevel == RiskLevel.highRisk;
    final isWatch = risk.riskLevel == RiskLevel.watch;
    final isSafe = risk.riskLevel == RiskLevel.safe;

    final statusColor = isCritical
        ? MausamColors.critical
        : (isHigh ? MausamColors.highRisk : (isWatch ? MausamColors.watch : MausamColors.safe));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(
          color: (isCritical || isHigh) ? statusColor.withValues(alpha: 0.4) : MausamColors.brd(context),
          width: (isCritical || isHigh) ? 1.5 : 1.0,
        ),
        boxShadow: MausamSpacing.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.shieldAlert, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Operational Risk Assessment',
                        overflow: TextOverflow.ellipsis,
                        style: MausamTypography.labelBoldOf(context).copyWith(
                          fontSize: 13.5,
                          color: MausamColors.txtPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: risk.statusLabel,
                color: statusColor,
                icon: isSafe ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4-Dimension Risk Gauge Grid (Section 11)
          Row(
            children: [
              Expanded(
                child: _buildRiskScoreCell(
                  context,
                  label: 'TRAVEL RISK',
                  score: risk.travelRisk,
                  riskLevel: risk.travelRiskLevel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRiskScoreCell(
                  context,
                  label: 'HEAT RISK',
                  score: risk.heatRisk,
                  riskLevel: risk.heatRiskLevel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRiskScoreCell(
                  context,
                  label: 'DELIVERY RISK',
                  score: risk.deliveryRisk,
                  riskLevel: risk.deliveryRiskLevel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRiskScoreCell(
                  context,
                  label: 'OVERALL RISK',
                  score: risk.compositeRisk,
                  riskLevel: risk.riskLevel,
                  isPrimary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Driver Callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  isSafe ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${risk.primaryDriver} (${risk.worstMaterialFactor})',
                    style: MausamTypography.microOf(context).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
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
  // HIERARCHY 6: RELEVANT FINANCIAL IMPACT
  // ===========================================================================
  Widget _buildFinancialImpactSection(BuildContext context) {
    final route = _activeRoute;
    final risk = _currentRisk;
    if (route == null || risk == null) return const SizedBox();

    // Transport financial model derived strictly from route distance and delivery parameters (Section 12)
    const double volumeM3 = 6.0;
    const double materialRatePerM3 = 5300.0; // M35 standard
    final double materialValue = volumeM3 * materialRatePerM3; // ₹31,800
    final double transportCost = double.parse((route.distanceKm * 75.0).toStringAsFixed(0)); // ₹75/km
    final double disposalCost = volumeM3 * 850.0; // ₹5,100
    final double fullLossLiability = (materialValue * 2.0) + transportCost + disposalCost;

    // Loss exposure scales dynamically with composite risk
    final double riskPct = (risk.compositeRisk / 100.0).clamp(0.0, 1.0);
    final double calculatedLossExposure = double.parse((fullLossLiability * riskPct).toStringAsFixed(0));

    final bool isHighExposure = risk.riskLevel == RiskLevel.highRisk || risk.riskLevel == RiskLevel.critical;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  Icon(LucideIcons.indianRupee, size: 16, color: MausamColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Route Economics & Financial Impact',
                    style: MausamTypography.labelBoldOf(context).copyWith(
                      fontSize: 13.5,
                      color: MausamColors.txtPrimary(context),
                    ),
                  ),
                ],
              ),
              Text(
                'M35 Grade · 6 m³ batch',
                style: MausamTypography.microOf(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Economic Cells (Section 12: No hardcoded ₹1.68 lakh or ₹2 lakh!)
          Row(
            children: [
              Expanded(
                child: _buildFinancialCell(
                  context,
                  label: 'TRANSPORT COST',
                  sublabel: '@ ₹75/km (${route.distanceKm.toStringAsFixed(1)} km)',
                  value: currencyFormatter.format(transportCost),
                  color: MausamColors.txtPrimary(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFinancialCell(
                  context,
                  label: 'MATERIAL VALUE',
                  sublabel: '@ ₹5,300/m³ (6 m³)',
                  value: currencyFormatter.format(materialValue),
                  color: MausamColors.txtPrimary(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFinancialCell(
                  context,
                  label: 'CALCULATED LOSS EXPOSURE',
                  sublabel: 'Risk-weighted exposure',
                  value: currencyFormatter.format(calculatedLossExposure),
                  color: isHighExposure ? MausamColors.highRisk : MausamColors.safe,
                  isAlert: isHighExposure,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EXPANDABLE SECONDARY DETAILS
  // ===========================================================================
  Widget _buildSecondaryDetailsCollapsible(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        border: Border.all(color: MausamColors.brd(context)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showSecondaryDetails = !_showSecondaryDetails),
            borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _showSecondaryDetails ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 15,
                    color: MausamColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _showSecondaryDetails
                          ? 'Hide Technical Slump & Hydration Decomposition'
                          : 'Show Technical Slump & Hydration Decomposition',
                      style: MausamTypography.microOf(context).copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: MausamColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showSecondaryDetails && _activeRoute != null && _currentRisk != null) ...[
            Divider(height: 1, color: MausamColors.brdSubtle(context)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildDecompRow(
                    context,
                    'Slump Retention Margin',
                    '${(_currentRisk!.slumpRetentionRatio * 100).toStringAsFixed(1)}% (${_currentRisk!.predictedSlumpMm} mm)',
                    _currentRisk!.slumpRetentionRatio >= 0.92 ? 'Compliant (>92% SLA)' : 'Quality SLA Breach',
                    isWarning: _currentRisk!.slumpRetentionRatio < 0.92,
                  ),
                  Divider(height: 14, color: MausamColors.brdSubtle(context)),
                  _buildDecompRow(
                    context,
                    'Hydration Window SLA',
                    '${_activeRoute!.etaMinutes.toInt()} min predicted transit',
                    _activeRoute!.etaMinutes <= 78.0 ? 'Within 78 min window' : '+${(_activeRoute!.etaMinutes - 78).toInt()}m delay breach',
                    isWarning: _activeRoute!.etaMinutes > 78.0,
                  ),
                  Divider(height: 14, color: MausamColors.brdSubtle(context)),
                  _buildDecompRow(
                    context,
                    'Corridor Traffic Bottleneck',
                    _activeRoute!.trafficLevel,
                    '+${_activeRoute!.expectedDelayMin.toInt()}m variance delay',
                    isWarning: _activeRoute!.expectedDelayMin > 8.0,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: MausamColors.surfSecondary(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        border: Border.all(color: MausamColors.brdSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: MausamTypography.microOf(context).copyWith(fontSize: 9.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: MausamTypography.tabularOf(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: MausamTypography.microOf(context).copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskScoreCell(
    BuildContext context, {
    required String label,
    required double score,
    required RiskLevel riskLevel,
    bool isPrimary = false,
  }) {
    final color = riskLevel == RiskLevel.critical
        ? MausamColors.critical
        : (riskLevel == RiskLevel.highRisk
            ? MausamColors.highRisk
            : (riskLevel == RiskLevel.watch ? MausamColors.watch : MausamColors.safe));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? color.withValues(alpha: 0.12) : MausamColors.surfSecondary(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        border: Border.all(
          color: isPrimary ? color.withValues(alpha: 0.4) : MausamColors.brdSubtle(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MausamTypography.microOf(context).copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${score.toInt()}/100',
            style: MausamTypography.tabularOf(context).copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCell(
    BuildContext context, {
    required String label,
    required String sublabel,
    required String value,
    required Color color,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAlert ? color.withValues(alpha: 0.10) : MausamColors.surfSecondary(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        border: Border.all(
          color: isAlert ? color.withValues(alpha: 0.35) : MausamColors.brdSubtle(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MausamTypography.microOf(context).copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: MausamTypography.tabularOf(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sublabel,
            style: MausamTypography.microOf(context).copyWith(fontSize: 9),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDecompRow(
    BuildContext context,
    String title,
    String value,
    String status, {
    required bool isWarning,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600)),
            Text(value, style: MausamTypography.bodyMediumOf(context).copyWith(fontSize: 12)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isWarning ? MausamColors.highRisk.withValues(alpha: 0.12) : MausamColors.safe.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isWarning ? MausamColors.highRisk : MausamColors.safe,
            ),
          ),
        ),
      ],
    );
  }
}
