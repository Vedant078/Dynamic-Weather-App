import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/mausam_colors.dart';
import '../../../core/theme/mausam_icons.dart';
import '../../../core/theme/mausam_spacing.dart';
import '../../../core/theme/mausam_typography.dart';
import '../../../models/batch.dart';
import '../../../models/delivery_order_draft.dart';
import '../../../state/mausam_state.dart';
import '../../../design_system/components/status_pill.dart';
import '../../../design_system/components/route_map_view.dart';
import '../../../models/area.dart';
import '../../../services/area_service.dart';
import '../../../design_system/components/searchable_area_dropdown.dart';
import '../../../services/route_service.dart';

class CreateDeliveryScreen extends StatefulWidget {
  final MausamState state;
  final VoidCallback onDispatched;

  const CreateDeliveryScreen({
    super.key,
    required this.state,
    required this.onDispatched,
  });

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  // Form controllers
  late TextEditingController _batchCodeController;
  late TextEditingController _volumeController;
  late TextEditingController _dispatchTimeController;

  // Selected values
  String _originAreaId = 'area-ahmedabad';
  String _selectedPlant = 'Ahmedabad';
  String _destinationAreaId = 'area-gandhinagar';
  String _selectedProject = 'Gandhinagar';
  String _selectedGrade = 'M35';
  String _dispatchTime = '14:00';
  double _initialSlumpMm = 120.0;
  double _targetSlumpMm = 100.0;
  double _retentionRequirementPct = 92.0;
  double _concreteTempC = 33.5;
  double _ambientTempC = 36.5;
  double _humidityPct = 52.0;
  String _selectedRetarder = 'None';
  String _selectedRouteId = 'route_a';
  double? _customTransitMinutes;
  double? _customDelayMinutes;
  bool _showAdvanced = false;
  bool _showTransitTuner = false;
  bool _isRecalculatingRoute = false;

  Area? get _originArea => AreaService.getAreaById(_originAreaId) ?? AreaService.findAreaByName(_selectedPlant);
  Area? get _destinationArea => AreaService.getAreaById(_destinationAreaId) ?? AreaService.findAreaByName(_selectedProject);


  LocationPoint _getPlantPoint(String name) {
    final area = _originArea ?? AreaService.findAreaByName(name);
    if (area != null) {
      return LocationPoint.fromArea(area, isPlant: true);
    }
    try {
      final loc = widget.state.savedPlants.firstWhere((p) => p.name == name);
      return loc.toLocationPoint();
    } catch (_) {
      return RouteService.resolvePlant(name);
    }
  }

  LocationPoint _getProjectPoint(String name) {
    final area = _destinationArea ?? AreaService.findAreaByName(name);
    if (area != null) {
      return LocationPoint.fromArea(area, isPlant: false);
    }
    try {
      final loc = widget.state.savedProjectSites.firstWhere((p) => p.name == name);
      return loc.toLocationPoint();
    } catch (_) {
      return RouteService.resolveProject(name);
    }
  }


  final List<Map<String, String>> _gradeDefinitions = [
    {'grade': 'M20', 'label': 'Foundation / Low Heat'},
    {'grade': 'M25', 'label': 'Slab / Standard'},
    {'grade': 'M30', 'label': 'Reinforced Structural'},
    {'grade': 'M35', 'label': 'High Strength Core'},
    {'grade': 'M40', 'label': 'Accelerated Hydration'},
    {'grade': 'M45', 'label': 'Critical Thermal Kinetics'},
  ];

  final List<Map<String, String>> _dispatchSlots = [
    {'time': '08:30', 'label': 'Morning (Cool)'},
    {'time': '11:30', 'label': 'Heat Onset'},
    {'time': '14:00', 'label': 'Peak Solar Heat'},
    {'time': '17:30', 'label': 'Evening Traffic'},
    {'time': '21:00', 'label': 'Night Window'},
  ];

  final List<String> _retarders = ['None', '0.4% by wt', '0.6% by wt'];

  @override
  void initState() {
    super.initState();
    final draft = widget.state.currentDraft;
    _batchCodeController = TextEditingController(text: draft.batchCode);
    _volumeController = TextEditingController(text: draft.volumeM3.toStringAsFixed(1));
    _dispatchTime = draft.dispatchTime;
    _dispatchTimeController = TextEditingController(text: _dispatchTime);
    
    // Dynamic Area Initialization (Section 4 & 8)
    if (draft.plantId.isNotEmpty && AreaService.getAreaById(draft.plantId) != null) {
      _originAreaId = draft.plantId;
      _selectedPlant = draft.plantName;
    } else {
      final found = AreaService.findAreaByName(draft.plantName);
      if (found != null) {
        _originAreaId = found.id;
        _selectedPlant = found.name;
      } else {
        _originAreaId = 'area-ahmedabad';
        _selectedPlant = 'Ahmedabad';
      }
    }

    if (draft.projectId.isNotEmpty && AreaService.getAreaById(draft.projectId) != null) {
      _destinationAreaId = draft.projectId;
      _selectedProject = draft.projectName;
    } else {
      final found = AreaService.findAreaByName(draft.projectName);
      if (found != null) {
        _destinationAreaId = found.id;
        _selectedProject = found.name;
      } else {
        _destinationAreaId = 'area-gandhinagar';
        _selectedProject = 'Gandhinagar';
      }
    }

    _selectedGrade = draft.concreteGrade;
    _initialSlumpMm = draft.initialSlumpMm;
    _targetSlumpMm = draft.targetSlumpMm;
    _retentionRequirementPct = draft.slumpRetentionRequirementPct;
    _concreteTempC = draft.concreteTempC;
    _ambientTempC = draft.ambientTempC;
    _humidityPct = draft.humidityPct;
    _selectedRetarder = draft.retarderAdmixture;
    _customTransitMinutes = draft.plannedTransitMinutes;
    _customDelayMinutes = draft.expectedDelayMin;

    final plantPoint = _getPlantPoint(_selectedPlant);
    final projectPoint = _getProjectPoint(_selectedProject);

    final route = RouteService.getRoute(
      originName: _selectedPlant,
      destinationName: _selectedProject,
      preferredRouteId: _selectedRouteId,
      customOrigin: plantPoint,
      customDestination: projectPoint,
    );
    final double delay = _customDelayMinutes ?? route.expectedDelayMin;
    final double baseTransit = _customTransitMinutes ?? route.baseTransitMinutes;
    final double totalTransit = baseTransit + delay;

    final telemetry = widget.state.weatherService.getDeliveryWindowWeather(
      location: route.routeName,
      dispatchTime: _dispatchTime,
      transitMinutes: totalTransit,
    );
    _ambientTempC = telemetry.ambientTempC;
    _humidityPct = telemetry.humidityPct;
  }

  void _updateWeatherFromCanonical() {
    final plantPoint = _getPlantPoint(_selectedPlant);
    final projectPoint = _getProjectPoint(_selectedProject);

    final route = RouteService.getRoute(
      originName: _selectedPlant,
      destinationName: _selectedProject,
      preferredRouteId: _selectedRouteId,
      customOrigin: plantPoint,
      customDestination: projectPoint,
    );
    final double delay = _customDelayMinutes ?? route.expectedDelayMin;
    final double baseTransit = _customTransitMinutes ?? route.baseTransitMinutes;
    final double totalTransit = baseTransit + delay;

    final telemetry = widget.state.weatherService.getDeliveryWindowWeather(
      location: route.routeName,
      dispatchTime: _dispatchTime,
      transitMinutes: totalTransit,
    );

    setState(() {
      _ambientTempC = telemetry.ambientTempC;
      _humidityPct = telemetry.humidityPct;
    });
  }

  Future<void> _handleLocationChanged({
    Area? newOriginArea,
    Area? newDestinationArea,
    String? newPlant,
    String? newProject,
  }) async {
    setState(() {
      _isRecalculatingRoute = true;
      if (newOriginArea != null) {
        _originAreaId = newOriginArea.id;
        _selectedPlant = newOriginArea.qualifiedName;
      } else if (newPlant != null) {
        _selectedPlant = newPlant;
        final matched = AreaService.findAreaByName(newPlant);
        if (matched != null) _originAreaId = matched.id;
      }

      if (newDestinationArea != null) {
        _destinationAreaId = newDestinationArea.id;
        _selectedProject = newDestinationArea.qualifiedName;
      } else if (newProject != null) {
        _selectedProject = newProject;
        final matched = AreaService.findAreaByName(newProject);
        if (matched != null) _destinationAreaId = matched.id;
      }
    });

    // Invalidate route and show "Calculating route..." (Section 13)
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final plantPoint = _getPlantPoint(_selectedPlant);
    final projectPoint = _getProjectPoint(_selectedProject);

    final candidates = RouteService.getCandidateRoutes(
      originName: _selectedPlant,
      destinationName: _selectedProject,
      customOrigin: plantPoint,
      customDestination: projectPoint,
    );

    final candidateIds = candidates.map((c) => c.routeId).toList();
    if (!candidateIds.contains(_selectedRouteId)) {
      _selectedRouteId = candidateIds.contains('route-b') ? 'route-b' : candidateIds.first;
    }

    final activeRoute = candidates.firstWhere(
      (c) => c.routeId == _selectedRouteId,
      orElse: () => candidates.first,
    );

    setState(() {
      _customTransitMinutes = activeRoute.baseTransitMinutes;
      _customDelayMinutes = activeRoute.expectedDelayMin;
      _isRecalculatingRoute = false;
    });

    _updateWeatherFromCanonical();
    _syncDraft();
    if (widget.state.currentDraftRisk != null) {
      await widget.state.calculateDeliveryRisk();
    }
  }

  @override
  void dispose() {
    _batchCodeController.dispose();
    _volumeController.dispose();
    _dispatchTimeController.dispose();
    super.dispose();
  }

  void _syncDraft() {
    final vol = double.tryParse(_volumeController.text.trim()) ?? 6.0;
    final route = widget.state.riskEngine.getRouteById(_selectedRouteId);
    final normRoute = _selectedRouteId.replaceAll('_', '-').toLowerCase();
    final double defaultDelay = normRoute.contains('route-a') ? 17.0 : (normRoute.contains('route-b') ? 2.0 : 8.0);
    final double delay = _customDelayMinutes ?? defaultDelay;
    final double baseTransit = _customTransitMinutes ?? route.etaMinutes.toDouble();

    final plantPoint = _getPlantPoint(_selectedPlant);
    final projectPoint = _getProjectPoint(_selectedProject);

    final draft = DeliveryOrderDraft(
      batchCode: _batchCodeController.text.trim().isEmpty ? 'RMC-205' : _batchCodeController.text.trim(),
      plantId: _originAreaId,
      plantName: _selectedPlant,
      projectId: _destinationAreaId,
      projectName: _selectedProject,
      volumeM3: vol,
      concreteGrade: _selectedGrade,
      initialSlumpMm: _initialSlumpMm,
      targetSlumpMm: _targetSlumpMm,
      slumpRetentionRequirementPct: _retentionRequirementPct,
      concreteTempC: _concreteTempC,
      ambientTempC: _ambientTempC,
      humidityPct: _humidityPct,
      admixtureRetarder: _selectedRetarder,
      selectedRouteId: _selectedRouteId,
      dispatchTime: _dispatchTime,
      plannedTransitMinutes: baseTransit,
      expectedDelayMin: delay,
      plantLat: plantPoint.latitude,
      plantLng: plantPoint.longitude,
      projectLat: projectPoint.latitude,
      projectLng: projectPoint.longitude,
    );
    widget.state.updateDeliveryDraft(draft);
  }

  Future<void> _handleCalculateRisk() async {
    _syncDraft();
    await widget.state.calculateDeliveryRisk();
  }

  Future<void> _handleConfirmDispatch() async {
    _syncDraft();
    final newBatch = await widget.state.confirmAndDispatchDelivery();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Batch #${newBatch.batchCode} dispatched successfully! Telemetry monitoring active.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: MausamColors.safe,
          duration: const Duration(seconds: 3),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDispatched();
      });
    }
  }

  void _showOverrideDialog(DeliveryRiskAssessment assessment) {
    final reasonController = TextEditingController(text: 'Commercial dispatch approved under plant manager authority');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MausamColors.surf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MausamSpacing.radiusModals)),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: MausamColors.highRisk, size: 20),
            const SizedBox(width: 8),
            Text(
              'Operational Risk Override',
              style: MausamTypography.labelBoldOf(context).copyWith(fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This delivery violates PRD operational thresholds (${assessment.worstMaterialFactor}). Proceeding requires formal override confirmation and is logged for ML feedback.',
              style: MausamTypography.bodyMediumOf(context).copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Override Justification / Authority *',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(MausamSpacing.radiusControls)),
              ),
              style: MausamTypography.bodyMediumOf(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MausamColors.highRisk,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleConfirmDispatch();
            },
            child: const Text('Confirm Override & Dispatch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;
    final assessment = widget.state.currentDraftRisk;
    final isCalculating = widget.state.isCalculatingRisk;

    return Scaffold(
      backgroundColor: MausamColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Operational Header
            _buildTopAppBar(context),

            // Main Scrollable Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 1180 : 720),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column: Order + Mix + Corridors + Telemetry Controls
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDeliveryInfoSection(context),
                                    const SizedBox(height: 16),
                                    _buildConcreteMixSection(context),
                                    const SizedBox(height: 16),
                                    _buildRouteSection(context),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Right column: Live Delivery Window + Risk Engine Results
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildEnvironmentalContext(context),
                                    const SizedBox(height: 16),
                                    _buildRiskSection(context, assessment, isCalculating),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDeliveryInfoSection(context),
                              const SizedBox(height: 16),
                              _buildConcreteMixSection(context),
                              const SizedBox(height: 16),
                              _buildRouteSection(context),
                              const SizedBox(height: 16),
                              _buildEnvironmentalContext(context),
                              const SizedBox(height: 16),
                              _buildRiskSection(context, assessment, isCalculating),
                              const SizedBox(height: 32),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        border: Border(bottom: BorderSide(color: MausamColors.brd(context))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            tooltip: 'Cancel and return to dashboard',
            onPressed: () {
              widget.state.cancelCreateDelivery();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'DISPATCH CONTROL',
                      style: MausamTypography.microOf(context).copyWith(
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: MausamColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: MausamColors.safe.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                      ),
                      child: Text(
                        'CENTRALIZED RISK ENGINE ACTIVE',
                        style: MausamTypography.microOf(context).copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: MausamColors.safe,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Create RMC Delivery Order',
                  style: MausamTypography.heading.copyWith(
                    fontSize: 16,
                    color: MausamColors.txtPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => widget.state.cancelCreateDelivery(),
            icon: const Icon(LucideIcons.x, size: 16),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: MausamColors.txtSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 01: DELIVERY INFORMATION & PLANNED DISPATCH
  // ===========================================================================
  Widget _buildDeliveryInfoSection(BuildContext context) {
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
            children: [
              _buildStepNumber('01'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Information',
                      style: MausamTypography.labelBoldOf(context).copyWith(
                        fontSize: 14,
                        color: MausamColors.txtPrimary(context),
                      ),
                    ),
                    Text(
                      'Origin plant, destination project, batch volume & planned dispatch window',
                      style: MausamTypography.microOf(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Batch / Order ID *', style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _batchCodeController,
                      style: MausamTypography.bodyMediumOf(context).copyWith(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                          borderSide: BorderSide(color: MausamColors.brd(context)),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.refreshCw, size: 14),
                          tooltip: 'Generate new ID',
                          onPressed: () {
                            final nextNum = 200 + (DateTime.now().millisecondsSinceEpoch % 800);
                            setState(() {
                              _batchCodeController.text = 'RMC-$nextNum';
                            });
                            _syncDraft();
                          },
                        ),
                      ),
                      onChanged: (_) => _syncDraft(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume (m³) *', style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _volumeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: MausamTypography.tabularOf(context).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixText: 'm³',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                          borderSide: BorderSide(color: MausamColors.brd(context)),
                        ),
                      ),
                      onChanged: (_) => _syncDraft(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SearchableAreaDropdown(
            label: 'PLANT / ORIGIN',
            pickerTitle: 'Select Origin Area',
            hint: 'Select dispatch origin area',
            selectedArea: _originArea ??
                Area(
                  id: _originAreaId,
                  name: _selectedPlant,
                  city: _selectedPlant,
                  state: 'Gujarat',
                  country: 'India',
                  latitude: _getPlantPoint(_selectedPlant).latitude,
                  longitude: _getPlantPoint(_selectedPlant).longitude,
                ),
            icon: MausamIcons.plant,
            isRequired: true,
            onChanged: (area) {
              if (area != null) {
                _handleLocationChanged(newOriginArea: area);
              }
            },
          ),
          const SizedBox(height: 14),
          SearchableAreaDropdown(
            label: 'PROJECT SITE / DESTINATION',
            pickerTitle: 'Select Destination Area',
            hint: 'Select project destination area',
            selectedArea: _destinationArea ??
                Area(
                  id: _destinationAreaId,
                  name: _selectedProject,
                  city: _selectedProject,
                  state: 'Gujarat',
                  country: 'India',
                  latitude: _getProjectPoint(_selectedProject).latitude,
                  longitude: _getProjectPoint(_selectedProject).longitude,
                ),
            icon: MausamIcons.project,
            isRequired: true,
            onChanged: (area) {
              if (area != null) {
                _handleLocationChanged(newDestinationArea: area);
              }
            },
          ),
          const SizedBox(height: 14),

          // Planned Dispatch Time (Time-based Exposure Window)
          Text('Planned Dispatch Time (Evaluates Delivery Exposure Window) *', style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dispatchSlots.map((slot) {
              final isSelected = _dispatchTime == slot['time'];
              return ChoiceChip(
                label: Text(
                  '${slot['time']} · ${slot['label']}',
                  style: MausamTypography.microOf(context).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : MausamColors.txtPrimary(context),
                  ),
                ),
                selected: isSelected,
                selectedColor: slot['time'] == '14:00' ? MausamColors.watch : MausamColors.accent,
                backgroundColor: MausamColors.surfSecondary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                  side: BorderSide(color: isSelected ? MausamColors.accent : MausamColors.brd(context)),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _dispatchTime = slot['time']!;
                      _dispatchTimeController.text = _dispatchTime;
                    });
                    _updateWeatherFromCanonical();
                    _syncDraft();
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 02: CONCRETE / RMC MIX SPECIFICATION
  // ===========================================================================
  Widget _buildConcreteMixSection(BuildContext context) {
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
            children: [
              _buildStepNumber('02'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Concrete / RMC Mix Specification',
                      style: MausamTypography.labelBoldOf(context).copyWith(
                        fontSize: 14,
                        color: MausamColors.txtPrimary(context),
                      ),
                    ),
                    Text(
                      'Mix grade influences hydration kinetics & slump retention sensitivity',
                      style: MausamTypography.microOf(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Concrete Grade Chips with Hydration Descriptions
          Text('Concrete Grade (Characteristic Strength & Hydration Kinetics) *', style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _gradeDefinitions.map((g) {
              final grade = g['grade']!;
              final label = g['label']!;
              final isSelected = _selectedGrade == grade;
              final isHighSensitivity = grade == 'M40' || grade == 'M45';

              return ChoiceChip(
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      grade,
                      style: MausamTypography.labelBoldOf(context).copyWith(
                        fontSize: 12,
                        color: isSelected ? Colors.white : MausamColors.txtPrimary(context),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected ? Colors.white.withValues(alpha: 0.8) : (isHighSensitivity ? MausamColors.watch : MausamColors.txtMuted(context)),
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: isHighSensitivity ? MausamColors.highRisk : MausamColors.accent,
                backgroundColor: MausamColors.surfSecondary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                  side: BorderSide(
                    color: isSelected ? MausamColors.accent : MausamColors.brd(context),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedGrade = grade);
                    _syncDraft();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Slump Parameters Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Initial Plant Slump', style: MausamTypography.microOf(context)),
                        Text('${_initialSlumpMm.toInt()} mm', style: MausamTypography.tabularOf(context).copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Slider(
                      value: _initialSlumpMm,
                      min: 90.0,
                      max: 160.0,
                      divisions: 14,
                      activeColor: MausamColors.accent,
                      onChanged: (v) {
                        setState(() => _initialSlumpMm = v);
                        _syncDraft();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Site Slump', style: MausamTypography.microOf(context)),
                        Text('${_targetSlumpMm.toInt()} mm', style: MausamTypography.tabularOf(context).copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Slider(
                      value: _targetSlumpMm,
                      min: 80.0,
                      max: 130.0,
                      divisions: 10,
                      activeColor: MausamColors.safe,
                      onChanged: (v) {
                        setState(() => _targetSlumpMm = v);
                        _syncDraft();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Advanced Parameters Collapsible
          InkWell(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(
                    _showAdvanced ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 16,
                    color: MausamColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _showAdvanced ? 'Hide Advanced Mix Parameters' : 'Show Advanced Parameters (Concrete Temp, Retarder Admixture)',
                      overflow: TextOverflow.ellipsis,
                      style: MausamTypography.microOf(context).copyWith(
                        color: MausamColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showAdvanced) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MausamColors.surfSecondary(context),
                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                border: Border.all(color: MausamColors.brdSubtle(context)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Batching Concrete Temp', style: MausamTypography.bodyMediumOf(context)),
                      Text('${_concreteTempC.toStringAsFixed(1)}°C', style: MausamTypography.tabularOf(context).copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Slider(
                    value: _concreteTempC,
                    min: 26.0,
                    max: 39.0,
                    divisions: 26,
                    activeColor: _concreteTempC > 34 ? MausamColors.highRisk : MausamColors.info,
                    onChanged: (v) {
                      setState(() => _concreteTempC = v);
                      _syncDraft();
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chemical Retarder Admixture', style: MausamTypography.bodyMediumOf(context)),
                          Text('Extends hydration dormancy by +25 to +45 min', style: MausamTypography.microOf(context)),
                        ],
                      ),
                      DropdownButton<String>(
                        value: _selectedRetarder,
                        underline: const SizedBox(),
                        items: _retarders.map((r) => DropdownMenuItem(value: r, child: Text(r, style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600)))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRetarder = val);
                            _syncDraft();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 03: ROUTE & CORRIDOR SELECTION + TRANSIT TUNER
  // ===========================================================================
  Widget _buildRouteSection(BuildContext context) {
    final plantPoint = _getPlantPoint(_selectedPlant);
    final projectPoint = _getProjectPoint(_selectedProject);

    final candidates = RouteService.getCandidateRoutes(
      originName: _selectedPlant,
      destinationName: _selectedProject,
      customOrigin: plantPoint,
      customDestination: projectPoint,
    );

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
            children: [
              _buildStepNumber('03'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Corridors & Bottleneck Tradeoffs',
                      style: MausamTypography.labelBoldOf(context).copyWith(
                        fontSize: 14,
                        color: MausamColors.txtPrimary(context),
                      ),
                    ),
                    Text(
                      'Compare corridor delay, travel SLA threshold (78m), and thermal exposure',
                      style: MausamTypography.microOf(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live Route Map Preview (Section 6 & 8)
          RouteMapView(
            originName: _selectedPlant,
            destinationName: _selectedProject,
            activeRouteId: _selectedRouteId,
            customOrigin: plantPoint,
            customDestination: projectPoint,
            isCalculating: _isRecalculatingRoute,
            height: 220,
            showLegend: false,
            showFloatingHud: true,
          ),
          const SizedBox(height: 14),

          // Dynamic Candidate Cards derived from canonical RouteService
          ...candidates.map((cand) {
            final isRec = cand.routeId == 'route-b' || (candidates.indexOf(cand) == 1);
            final isCrit = cand.expectedDelayMin > 10.0 || cand.etaMinutes > 78.0;
            final isWatch = cand.expectedDelayMin > 4.0;
            final riskColor = isCrit ? MausamColors.highRisk : (isWatch ? MausamColors.watch : MausamColors.safe);
            final riskLabel = isRec
                ? 'RECOMMENDED (Safe Window)'
                : (isCrit ? 'HIGH RISK (Slump loss & delay)' : 'WATCH (Marginal transit buffer)');

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildRouteOptionCard(
                context,
                id: cand.routeId,
                name: cand.routeName,
                distanceKm: cand.distanceKm,
                baseMin: cand.baseTransitMinutes.toInt(),
                delayMin: cand.expectedDelayMin.toInt(),
                totalMin: cand.etaMinutes.toInt(),
                bottleneck: cand.primaryDriver,
                riskLabel: riskLabel,
                riskColor: riskColor,
                isRecommended: isRec,
              ),
            );
          }),
          const SizedBox(height: 4),

          // Transit Duration & Delay Tuner (For operational testing & stress-testing SLA breaches)
          InkWell(
            onTap: () => setState(() => _showTransitTuner = !_showTransitTuner),
            borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    _showTransitTuner ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 16,
                    color: MausamColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _showTransitTuner ? 'Hide Transit Duration Tuner' : 'Tune Planned Transit / Traffic Delay (Test SLA Breach)',
                      overflow: TextOverflow.ellipsis,
                      style: MausamTypography.microOf(context).copyWith(
                        color: MausamColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showTransitTuner) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MausamColors.surfSecondary(context),
                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                border: Border.all(color: MausamColors.brdSubtle(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Planned Base Transit Time', style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600)),
                      Text('${(_customTransitMinutes ?? 60.0).toInt()} min', style: MausamTypography.tabularOf(context).copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Slider(
                    value: (_customTransitMinutes ?? 60.0).clamp(40.0, 110.0),
                    min: 40.0,
                    max: 110.0,
                    divisions: 14,
                    activeColor: (_customTransitMinutes ?? 60.0) > 78.0 ? MausamColors.highRisk : MausamColors.accent,
                    onChanged: (v) {
                      setState(() => _customTransitMinutes = v);
                      _syncDraft();
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Expected Traffic Delay', style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w600)),
                      Text('+${(_customDelayMinutes ?? 5.0).toInt()} min', style: MausamTypography.tabularOf(context).copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Slider(
                    value: (_customDelayMinutes ?? 5.0).clamp(0.0, 30.0),
                    min: 0.0,
                    max: 30.0,
                    divisions: 15,
                    activeColor: (_customDelayMinutes ?? 5.0) > 8.0 ? MausamColors.highRisk : MausamColors.watch,
                    onChanged: (v) {
                      setState(() => _customDelayMinutes = v);
                      _syncDraft();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteOptionCard(
    BuildContext context, {
    required String id,
    required String name,
    required double distanceKm,
    required int baseMin,
    required int delayMin,
    required int totalMin,
    required String bottleneck,
    required String riskLabel,
    required Color riskColor,
    required bool isRecommended,
  }) {
    final isSelected = _selectedRouteId == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRouteId = id;
          _customTransitMinutes = baseMin.toDouble();
          _customDelayMinutes = delayMin.toDouble();
        });
        _updateWeatherFromCanonical();
        _syncDraft();
        if (widget.state.currentDraftRisk != null) {
          widget.state.calculateDeliveryRisk();
        }
      },
      borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? riskColor.withValues(alpha: 0.08)
              : MausamColors.surfSecondary(context),
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          border: Border.all(
            color: isSelected ? riskColor : MausamColors.brdSubtle(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 16,
                  color: isSelected ? riskColor : MausamColors.txtMuted(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: MausamTypography.labelBoldOf(context).copyWith(
                      fontSize: 12.5,
                      color: isSelected ? riskColor : MausamColors.txtPrimary(context),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                  ),
                  child: Text(
                    riskLabel,
                    style: MausamTypography.microOf(context).copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${distanceKm.toStringAsFixed(1)} km · $totalMin min ETA ($baseMin min + $delayMin min delay)',
                    overflow: TextOverflow.ellipsis,
                    style: MausamTypography.microOf(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: MausamColors.txtPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  totalMin <= 78 ? '✓ Under 78m SLA' : '⚠ Exceeds 78m SLA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: totalMin <= 78 ? MausamColors.safe : MausamColors.highRisk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bottleneck,
              style: MausamTypography.microOf(context).copyWith(
                color: isSelected ? MausamColors.txtPrimary(context) : MausamColors.txtMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 04: ENVIRONMENTAL CONTEXT & DELIVERY WINDOW
  // ===========================================================================
  Widget _buildEnvironmentalContext(BuildContext context) {
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
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.cloudSun, size: 16, color: MausamColors.info),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Corridor Environmental Telemetry',
                        overflow: TextOverflow.ellipsis,
                        style: MausamTypography.labelBoldOf(context).copyWith(
                          fontSize: 13,
                          color: MausamColors.txtPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: 'LIVE SENSORS',
                color: MausamColors.safe,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weather telemetry badges
          Row(
            children: [
              Expanded(
                child: _buildEnvBadge(
                  context,
                  icon: LucideIcons.thermometer,
                  label: 'Ambient Temp',
                  value: '${_ambientTempC.toStringAsFixed(1)}°C',
                  subtext: _ambientTempC >= 38.0 ? 'Extreme Heat' : (_ambientTempC >= 35.0 ? 'High Solar Load' : 'Moderate Heat'),
                  color: _ambientTempC >= 38.0 ? MausamColors.highRisk : MausamColors.watch,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnvBadge(
                  context,
                  icon: LucideIcons.droplets,
                  label: 'Humidity',
                  value: '${_humidityPct.toInt()}%',
                  subtext: _humidityPct < 45.0 ? 'Rapid Evaporation' : 'Normal Evap',
                  color: MausamColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnvBadge(
                  context,
                  icon: LucideIcons.cloudRain,
                  label: 'Precipitation',
                  value: _selectedRouteId.contains('route_a') ? '68%' : '12%',
                  subtext: _selectedRouteId.contains('route_a') ? 'Rain Cloud Ahead' : 'Clear Sky',
                  color: _selectedRouteId.contains('route_a') ? MausamColors.watch : MausamColors.safe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Time-based Delivery Exposure Window Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MausamColors.surfSecondary(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(color: MausamColors.brdSubtle(context)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.clock, size: 16, color: MausamColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Window Exposure',
                        style: MausamTypography.microOf(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: MausamColors.txtPrimary(context),
                        ),
                      ),
                      Text(
                        'Dispatch $_dispatchTime · Diurnal solar heat active across transit window',
                        style: MausamTypography.microOf(context),
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

  Widget _buildEnvBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
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
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: MausamTypography.microOf(context).copyWith(fontSize: 10),
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
              color: MausamColors.txtPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: MausamTypography.microOf(context).copyWith(fontSize: 9.5),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 05: RISK CALCULATION & OPERATIONAL DECISION (THE CORE ENGINE)
  // ===========================================================================
  Widget _buildRiskSection(
    BuildContext context,
    DeliveryRiskAssessment? assessment,
    bool isCalculating,
  ) {
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
            children: [
              _buildStepNumber('04'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RMC Risk Engine Assessment',
                      style: MausamTypography.labelBoldOf(context).copyWith(
                        fontSize: 14,
                        color: MausamColors.txtPrimary(context),
                      ),
                    ),
                    Text(
                      'Multi-factor evaluation: Heat, Travel SLA, and Slump Retention',
                      style: MausamTypography.microOf(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Calculate Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: isCalculating ? null : _handleCalculateRisk,
              icon: isCalculating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.activity, size: 16),
              label: Text(
                isCalculating ? 'Executing Risk Engine Pipeline...' : 'Calculate Delivery Risk',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MausamColors.info,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results Presentation
          if (assessment != null) ...[
            _buildRiskResultCard(context, assessment),
            const SizedBox(height: 16),
            _buildDispatchActionSection(context, assessment),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MausamColors.surfSecondary(context),
                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                border: Border.all(color: MausamColors.brdSubtle(context)),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.sparkles, size: 24, color: MausamColors.txtMuted(context)),
                  const SizedBox(height: 8),
                  Text(
                    'Ready for Operational Assessment',
                    style: MausamTypography.labelBoldOf(context).copyWith(
                      color: MausamColors.txtSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Calculate Delivery Risk" to evaluate temperature exposure, route traffic delays, and slump retention SLAs.',
                    textAlign: TextAlign.center,
                    style: MausamTypography.microOf(context),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskResultCard(BuildContext context, DeliveryRiskAssessment assessment) {
    Color overallColor = MausamColors.safe;
    if (assessment.riskLevel == RiskLevel.critical) {
      overallColor = MausamColors.critical;
    } else if (assessment.riskLevel == RiskLevel.highRisk) {
      overallColor = MausamColors.highRisk;
    } else if (assessment.riskLevel == RiskLevel.watch) {
      overallColor = MausamColors.watch;
    }

    Color colorForLevel(RiskLevel lvl) {
      switch (lvl) {
        case RiskLevel.critical:
          return MausamColors.critical;
        case RiskLevel.highRisk:
          return MausamColors.highRisk;
        case RiskLevel.watch:
          return MausamColors.watch;
        case RiskLevel.safe:
          return MausamColors.safe;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: overallColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        border: Border.all(color: overallColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Overall Risk Banner & Worst Material Factor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: overallColor,
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                ),
                child: Text(
                  assessment.overallRisk,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                'Composite Score: ${assessment.compositeRiskScore.toStringAsFixed(1)} / 100',
                style: MausamTypography.microOf(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: overallColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            assessment.statusLabel,
            style: MausamTypography.labelBoldOf(context).copyWith(
              fontSize: 13.5,
              color: MausamColors.txtPrimary(context),
            ),
          ),
          if (assessment.worstMaterialFactor != 'None') ...[
            const SizedBox(height: 2),
            Text(
              'Governing Failure Mode: ${assessment.worstMaterialFactor}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: overallColor,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 2. Delivery Exposure Window Telemetry
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(color: MausamColors.brd(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWindowTelemetryCol(
                  context,
                  title: 'Planned Dispatch',
                  val: _dispatchTime,
                ),
                _buildWindowTelemetryCol(
                  context,
                  title: 'Transit Duration',
                  val: '${assessment.predictedTransitMinutes.toInt()} min',
                  sub: assessment.predictedTransitMinutes <= 78 ? 'Within SLA (78m)' : 'SLA Breached',
                  isAlert: assessment.predictedTransitMinutes > 78,
                ),
                _buildWindowTelemetryCol(
                  context,
                  title: 'Expected Arrival',
                  val: assessment.expectedArrivalTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // KEY FACTORS (Section 21 canonical summary)
          Text(
            'KEY FACTORS',
            style: MausamTypography.microOf(context).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: MausamColors.txtSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(color: MausamColors.brd(context)),
            ),
            child: Row(
              children: [
                _buildKeyFactorCol(
                  context,
                  label: 'Transit',
                  value: '${assessment.predictedTransitMinutes.toInt()} min',
                  isAlert: assessment.predictedTransitMinutes > 78,
                ),
                _buildKeyFactorCol(
                  context,
                  label: 'SLA',
                  value: '78 min',
                  isAlert: false,
                ),
                _buildKeyFactorCol(
                  context,
                  label: 'Slump',
                  value: '${assessment.slumpRetentionPct.toStringAsFixed(0)}%',
                  isAlert: assessment.slumpRetentionPct < 92.0,
                ),
                _buildKeyFactorCol(
                  context,
                  label: 'Temp',
                  value: '${_ambientTempC.toStringAsFixed(0)}°C',
                  isAlert: _ambientTempC >= 38.0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Three Core Risk Dimensions (Decomposition)
          Text(
            'Contributing Risk Dimensions',
            style: MausamTypography.microOf(context).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _buildRiskDimensionRow(
            context,
            name: 'Heat Risk',
            score: assessment.heatRisk,
            level: assessment.heatRiskLevel,
            color: colorForLevel(assessment.heatRiskLevel),
          ),
          const SizedBox(height: 6),
          _buildRiskDimensionRow(
            context,
            name: 'Travel Risk',
            score: assessment.travelRisk,
            level: assessment.travelRiskLevel,
            color: colorForLevel(assessment.travelRiskLevel),
          ),
          const SizedBox(height: 6),
          _buildRiskDimensionRow(
            context,
            name: 'Delivery Risk',
            score: assessment.deliveryRisk,
            level: assessment.deliveryRiskLevel,
            color: colorForLevel(assessment.deliveryRiskLevel),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: MausamColors.brdSubtle(context)),
          const SizedBox(height: 12),

          // 4. Slump & Financial Telemetry Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCell(
                  context,
                  label: 'Predicted slump',
                  value: '${assessment.predictedSlumpMm.toStringAsFixed(1)} mm',
                  subtext: 'Target: ${_targetSlumpMm.toInt()} mm',
                  isAlert: assessment.predictedSlumpMm < _targetSlumpMm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCell(
                  context,
                  label: 'Slump retention',
                  value: '${assessment.slumpRetentionPct.toStringAsFixed(1)}%',
                  subtext: 'SLA threshold: 92%',
                  isAlert: assessment.slumpRetentionPct < 92.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCell(
                  context,
                  label: 'Loss exposure',
                  value: assessment.financialLossExposure,
                  subtext: 'Rejection value',
                  isAlert: assessment.overallRisk == 'HIGH' || assessment.overallRisk == 'CRITICAL',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Grounded Explainability Drivers (The "WHY")
          Text(
            'Contributing Risk Drivers & Exposure Telemetry:',
            style: MausamTypography.microOf(context).copyWith(
              fontWeight: FontWeight.w700,
              color: MausamColors.txtPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          ...assessment.groundedDrivers.map(
            (driver) => Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: overallColor, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      driver,
                      style: MausamTypography.microOf(context).copyWith(
                        fontSize: 11,
                        color: MausamColors.txtSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 6. Operational Recommendation Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(color: MausamColors.brd(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: MausamColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operational Recommendation',
                        style: MausamTypography.microOf(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: MausamColors.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assessment.recommendationText,
                        style: MausamTypography.bodyMediumOf(context).copyWith(fontSize: 11.5),
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

  Widget _buildKeyFactorCol(
    BuildContext context, {
    required String label,
    required String value,
    required bool isAlert,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MausamTypography.microOf(context).copyWith(
              fontSize: 10,
              color: MausamColors.txtMuted(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: MausamTypography.tabularOf(context).copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: isAlert ? MausamColors.highRisk : MausamColors.txtPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowTelemetryCol(
    BuildContext context, {
    required String title,
    required String val,
    String? sub,
    bool isAlert = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MausamTypography.microOf(context).copyWith(fontSize: 9.5),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            val,
            overflow: TextOverflow.ellipsis,
            style: MausamTypography.tabularOf(context).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: isAlert ? MausamColors.highRisk : MausamColors.txtPrimary(context),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(
              sub,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isAlert ? MausamColors.highRisk : MausamColors.safe,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskDimensionRow(
    BuildContext context, {
    required String name,
    required double score,
    required RiskLevel level,
    required Color color,
  }) {
    String levelName = 'SAFE';
    if (level == RiskLevel.critical) levelName = 'CRITICAL';
    if (level == RiskLevel.highRisk) levelName = 'HIGH';
    if (level == RiskLevel.watch) levelName = 'WATCH';

    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            name,
            style: MausamTypography.microOf(context).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          width: 60,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
          ),
          child: Text(
            levelName,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              backgroundColor: MausamColors.surfSecondary(context),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '${score.toInt()}',
            textAlign: TextAlign.right,
            style: MausamTypography.tabularOf(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MausamColors.txtPrimary(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCell(
    BuildContext context, {
    required String label,
    required String value,
    required String subtext,
    required bool isAlert,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MausamTypography.microOf(context).copyWith(fontSize: 9.5),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: MausamTypography.tabularOf(context).copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: isAlert ? MausamColors.highRisk : MausamColors.safe,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 1),
        Text(
          subtext,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 9,
            color: isAlert ? MausamColors.highRisk : MausamColors.txtMuted(context),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 06: ACTION & MITIGATION CONTROLS
  // ===========================================================================
  Widget _buildDispatchActionSection(BuildContext context, DeliveryRiskAssessment assessment) {
    final isNotSafe = assessment.riskLevel != RiskLevel.safe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Context-aware Mitigations
        if (isNotSafe) ...[
          // Mitigation 1: Switch Route if Route A
          if (_selectedRouteId != 'route_b') ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedRouteId = 'route_b';
                    _customTransitMinutes = 58.0;
                    _customDelayMinutes = 2.0;
                  });
                  _updateWeatherFromCanonical();
                  _syncDraft();
                  _handleCalculateRisk();
                },
                icon: const Icon(LucideIcons.gitPullRequest, size: 15, color: MausamColors.safe),
                label: const Text(
                  'Apply Route B Bypass (-11m transit) & Recalculate',
                  style: TextStyle(fontWeight: FontWeight.w700, color: MausamColors.safe, fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MausamColors.safe, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Mitigation 2: Add Retarder Admixture if not present
          if (_selectedRetarder == 'None') ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedRetarder = '0.4% by wt';
                  });
                  _syncDraft();
                  _handleCalculateRisk();
                },
                icon: const Icon(LucideIcons.flaskConical, size: 15, color: MausamColors.info),
                label: const Text(
                  'Add 0.4% Retarder Admixture (+25m window) & Recalculate',
                  style: TextStyle(fontWeight: FontWeight.w700, color: MausamColors.info, fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MausamColors.info, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Mitigation 3: Reschedule to cooler window if peak heat
          if (_dispatchTime == '14:00') ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _dispatchTime = '17:30';
                    _dispatchTimeController.text = '17:30';
                  });
                  _syncDraft();
                  _handleCalculateRisk();
                },
                icon: const Icon(LucideIcons.calendarClock, size: 15, color: MausamColors.watch),
                label: const Text(
                  'Reschedule to 17:30 (Cooler Window) & Recalculate',
                  style: TextStyle(fontWeight: FontWeight.w700, color: MausamColors.watch, fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MausamColors.watch, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],

        // Primary Dispatch / Override Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _handleConfirmDispatch,
            icon: Icon(isNotSafe ? LucideIcons.shieldAlert : LucideIcons.send, size: 16),
            label: Text(
              isNotSafe ? 'Confirm Dispatch (Override Operational Warning)' : 'Confirm Dispatch & Monitor Live',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isNotSafe ? MausamColors.watch : MausamColors.safe,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons)),
            ),
          ),
        ),
        if (isNotSafe) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => _showOverrideDialog(assessment),
              icon: Icon(LucideIcons.fileSignature, size: 13, color: MausamColors.txtMuted(context)),
              label: Text(
                'Log Formal Plant Manager Risk Justification Note',
                style: MausamTypography.microOf(context).copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepNumber(String num) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MausamColors.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: MausamColors.accent, width: 1.2),
      ),
      child: Text(
        num,
        style: TextStyle(
          color: MausamColors.accent,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
