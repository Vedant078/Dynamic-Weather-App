import 'package:flutter/material.dart';
import '../models/persona.dart';
import '../models/batch.dart';
import '../models/route_option.dart';
import '../models/delivery_outcome.dart';
import '../models/delivery_order_draft.dart';
import '../models/workspace_definition.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
import '../services/risk_engine_service.dart';
import '../services/weather_service.dart';
import '../services/route_service.dart';
import '../services/location_service.dart';
import '../models/current_weather.dart';

class MausamState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final RiskEngineService _riskEngine = RiskEngineService();
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  String _selectedPersonaId = 'rmc';
  List<PersonaModel> _personas = MockDataService.personas;
  
  List<BatchModel> _batches = [];
  late BatchModel _selectedBatch;
  final List<RouteOptionModel> _routes = List.from(MockDataService.routesForBatch204);
  final List<DeliveryOutcomeModel> _outcomes = [];
  
  int _simulationStep = 0;
  String _simulationNarrative = 'Truck in transit on Route A. Concrete hydration and temperature within safe baseline envelope.';
  DateTime _lastUpdated = DateTime.now();
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.light;

  // Hero Dynamic Weather & Location State (Section 3, 4, 15)
  LocationData _currentLocation = LocationService.defaultLocation;
  CurrentWeather? _heroWeather;
  bool _isLoadingHeroWeather = false;
  String? _heroWeatherError;

  // Delivery Creation & Risk Pipeline State
  bool _isCreatingDelivery = false;
  bool _isCalculatingRisk = false;
  DeliveryOrderDraft? _currentDraft;
  DeliveryRiskAssessment? _currentDraftRisk;

  // Screen Routing & Auth Flow ('landing' -> 'auth' -> 'persona' -> 'app')
  String _currentScreen = 'landing';
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  String? _userOrganization;
  List<String> _userRoleIds = [];
  bool _isAuthenticating = false;
  String? _authError;

  MausamState() {
    _selectedBatch = MockDataService.primaryBatch204;
    _heroWeather = CurrentWeather.deterministic(
      locationName: _currentLocation.cityName,
      regionName: _currentLocation.regionName,
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
    );
    _init();
    initHeroLocationAndWeather();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get selectedPersonaId => _selectedPersonaId;
  PersonaModel get currentPersona => _personas.firstWhere((p) => p.id == _selectedPersonaId, orElse: () => _personas.first);
  List<PersonaModel> get personas => _personas;
  List<WorkspaceDefinition> get workspaces => _personas.map((p) => WorkspaceDefinition.fromPersona(p)).toList();

  WorkspaceOperationalSummary get rmcOperationalSummary {
    final active = _batches.where((b) => b.status != 'DELIVERED' && b.status != 'REJECTED').length;
    final attention = _batches.where((b) => b.riskLevel == RiskLevel.highRisk || b.riskLevel == RiskLevel.critical).length;
    return WorkspaceOperationalSummary(
      activeDeliveries: active,
      attentionCount: attention,
      hasLiveTelemetry: active > 0,
    );
  }

  List<BatchModel> get batches => _batches;
  BatchModel get selectedBatch => _selectedBatch;
  List<RouteOptionModel> get routes => _routes;
  List<DeliveryOutcomeModel> get outcomes => _outcomes;
  int get simulationStep => _simulationStep;
  String get simulationNarrative => _simulationNarrative;
  DateTime get lastUpdated => _lastUpdated;
  bool get isLoading => _isLoading;

  bool get isCreatingDelivery => _isCreatingDelivery;
  bool get isCalculatingRisk => _isCalculatingRisk;
  DeliveryRiskAssessment? get currentDraftRisk => _currentDraftRisk;
  RiskEngineService get riskEngine => _riskEngine;
  WeatherService get weatherService => _weatherService;
  LocationService get locationService => _locationService;

  LocationData get currentLocation => _currentLocation;
  CurrentWeather? get heroWeather => _heroWeather;
  bool get isLoadingHeroWeather => _isLoadingHeroWeather;
  String? get heroWeatherError => _heroWeatherError;

  String get currentScreen => _currentScreen;
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userOrganization => _userOrganization;
  List<String> get userRoleIds => _userRoleIds;
  bool get isAuthenticating => _isAuthenticating;
  String? get authError => _authError;

  Future<void> initHeroLocationAndWeather() async {
    _isLoadingHeroWeather = true;
    _heroWeatherError = null;
    notifyListeners();

    try {
      final detected = await _locationService.detectLocation();
      _currentLocation = detected;
      final weather = await _weatherService.getCurrentWeather(location: _currentLocation);
      _heroWeather = weather;
    } catch (_) {
      _heroWeatherError = 'Unable to load local conditions';
      _heroWeather = CurrentWeather.deterministic(
        locationName: _currentLocation.cityName,
        regionName: _currentLocation.regionName,
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
      );
    } finally {
      _isLoadingHeroWeather = false;
      notifyListeners();
    }
  }

  Future<void> changeLocation(LocationData newLocation) async {
    _currentLocation = newLocation;
    _isLoadingHeroWeather = true;
    _heroWeatherError = null;
    notifyListeners();

    try {
      final weather = await _weatherService.getCurrentWeather(location: _currentLocation);
      _heroWeather = weather;
    } catch (_) {
      _heroWeatherError = 'Unable to load local conditions';
      _heroWeather = CurrentWeather.deterministic(
        locationName: _currentLocation.cityName,
        regionName: _currentLocation.regionName,
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
      );
    } finally {
      _isLoadingHeroWeather = false;
      notifyListeners();
    }
  }

  Future<void> refreshHeroWeather() async {
    _isLoadingHeroWeather = true;
    _heroWeatherError = null;
    notifyListeners();

    try {
      final weather = await _weatherService.getCurrentWeather(
        location: _currentLocation,
        forceRefresh: true,
      );
      _heroWeather = weather;
    } catch (_) {
      _heroWeatherError = 'Unable to load local conditions';
    } finally {
      _isLoadingHeroWeather = false;
      notifyListeners();
    }
  }

  void navigateTo(String screen) {
    _currentScreen = screen == 'persona' ? 'rbac' : screen;
    if (screen == 'app' || screen == 'rbac' || screen == 'persona') {
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isAuthenticating = true;
    _authError = null;
    _isAuthenticated = true;
    _userEmail = email;
    _userName = email.contains('@') ? email.split('@').first : email;
    _currentScreen = 'rbac';
    notifyListeners();

    try {
      final res = await _apiService.login(email: email, password: password);
      final user = res['user'] as Map<String, dynamic>?;
      _userEmail = user?['email'] as String? ?? email;
      _userName = user?['name'] as String? ?? 'Operations Lead';
      _userOrganization = user?['organization'] as String?;
      final rolesList = user?['roles'] as List<dynamic>?;
      _userRoleIds = rolesList?.map((r) => (r is Map ? r['id'] : r).toString()).toList() ?? ['rmc'];
      _batches = [];
      await loadBatches();
      return true;
    } catch (e) {
      _authError = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _currentScreen = 'auth';
      notifyListeners();
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? organization,
  }) async {
    _isAuthenticating = true;
    _authError = null;
    _isAuthenticated = true;
    _userName = name;
    _userEmail = email;
    _currentScreen = 'rbac';
    notifyListeners();

    try {
      final res = await _apiService.register(
        name: name,
        email: email,
        password: password,
        organization: organization,
      );
      final user = res['user'] as Map<String, dynamic>?;
      _userEmail = user?['email'] as String? ?? email;
      _userName = user?['name'] as String? ?? name;
      _userOrganization = user?['organization'] as String?;
      final rolesList = user?['roles'] as List<dynamic>?;
      _userRoleIds = rolesList?.map((r) => (r is Map ? r['id'] : r).toString()).toList() ?? ['rmc'];
      _batches = [];
      await loadBatches();
      return true;
    } catch (e) {
      _authError = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _currentScreen = 'auth';
      notifyListeners();
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _apiService.logout();
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _userOrganization = null;
    _userRoleIds = [];
    _batches = [];
    _outcomes.clear();
    _themeMode = ThemeMode.light;
    _currentScreen = 'landing';
    notifyListeners();
  }

  Future<void> continueWithGoogle() async {
    // Authenticate using development demo account with backend
    await signIn(email: 'rmc.demo@mausam.local', password: 'RmcManager2026!');
  }

  void selectRoleAndLaunch(String roleId) {
    setPersona(roleId);
    if (roleId == 'rmc') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _isAuthenticated = true;
    _currentScreen = 'app';
    notifyListeners();
  }

  void selectPersonaAndLaunch(String personaId) {
    selectRoleAndLaunch(personaId);
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetchedPersonas = await _apiService.getPersonas();
      if (fetchedPersonas.isNotEmpty) _personas = fetchedPersonas;

      // Verify and restore authenticated session if token exists
      final me = await _apiService.getMe();
      if (me != null) {
        _isAuthenticated = true;
        _userEmail = me['email'] as String?;
        _userName = me['name'] as String?;
        _userOrganization = me['organization'] as String?;
        final rolesList = me['roles'] as List<dynamic>?;
        _userRoleIds = rolesList?.map((r) => (r is Map ? r['id'] : r).toString()).toList() ?? ['rmc'];
        _currentScreen = 'rbac';
      }

      await loadBatches();
    } catch (_) {}
    _isLoading = false;
    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  Future<void> loadBatches() async {
    try {
      final fetchedBatches = await _apiService.getDeliveries();
      _batches = fetchedBatches;
      if (_batches.isNotEmpty) {
        _selectedBatch = _batches.first;
      }
      notifyListeners();
    } catch (_) {}
  }

  void setPersona(String personaId) {
    if (_selectedPersonaId != personaId) {
      _selectedPersonaId = personaId;
      notifyListeners();
    }
  }

  void selectBatch(String batchId) {
    final found = _batches.firstWhere((b) => b.batchId == batchId, orElse: () => _selectedBatch);
    _selectedBatch = found;
    notifyListeners();
  }

  // Simulation Step Progression (Golden Demo Scenario)
  void setSimulationStep(int step) {
    _simulationStep = step.clamp(0, 4);
    _lastUpdated = DateTime.now();

    if (_simulationStep == 0) {
      // Step 0: Nominal transit, SAFE
      _selectedBatch = _selectedBatch.copyWith(
        elapsedMinutes: 22.0,
        etaMinutes: 32.0,
        distanceRemainingKm: 16.4,
        ambientTempC: 35.0,
        concreteTempC: 32.4,
        currentSlumpMm: 106.0,
        slumpRetentionRatio: 0.964,
        heatRisk: 34.0,
        travelRisk: 28.0,
        deliveryRisk: 32.0,
        compositeRisk: 31.4,
        riskLevel: RiskLevel.safe,
        status: 'IN_TRANSIT',
        primaryDriver: 'Transit on schedule within safe slump envelope',
        riskFactors: [
          'Ambient temperature 35.0°C within tolerance',
          'Slump retention currently 96.4%',
          'Route A moving normally',
        ],
        recommendedAction: null,
        activeRouteId: 'route-a',
      );
      _simulationNarrative = 'Truck in transit on Route A. Concrete hydration and temperature within safe baseline envelope.';
    } else if (_simulationStep == 1) {
      // Step 1: Traffic building, WATCH
      _selectedBatch = _selectedBatch.copyWith(
        elapsedMinutes: 34.0,
        etaMinutes: 36.0,
        distanceRemainingKm: 11.2,
        ambientTempC: 37.8,
        concreteTempC: 33.6,
        currentSlumpMm: 103.5,
        slumpRetentionRatio: 0.941,
        heatRisk: 58.0,
        travelRisk: 52.0,
        deliveryRisk: 54.0,
        compositeRisk: 54.6,
        riskLevel: RiskLevel.watch,
        status: 'IN_TRANSIT',
        primaryDriver: 'Traffic congestion building on SP Ring Road corridor',
        riskFactors: [
          '+7 min traffic delay near Nana Chiloda',
          'Concrete temperature rose to 33.6°C',
          'Slump retention 94.1% (nearing 92% threshold)',
        ],
        recommendedAction: null,
        activeRouteId: 'route-a',
      );
      _simulationNarrative = 'Traffic congestion building near Nana Chiloda. Transit time extending; monitoring slump retention.';
    } else if (_simulationStep == 2) {
      // Step 2: Heat surge + Delay + Rain cell -> HIGH RISK
      _selectedBatch = _selectedBatch.copyWith(
        elapsedMinutes: 46.0,
        etaMinutes: 36.0, // Total transit = 82 min > 78 min!
        distanceRemainingKm: 7.8,
        ambientTempC: 40.2,
        concreteTempC: 34.8,
        currentSlumpMm: 98.0,
        slumpRetentionRatio: 0.891, // < 92%!
        heatRisk: 78.0,
        travelRisk: 82.0,
        deliveryRisk: 84.0,
        compositeRisk: 81.6,
        riskLevel: RiskLevel.highRisk,
        status: 'AT_RISK',
        primaryDriver: 'Transit delay & severe hydration slump loss',
        riskFactors: [
          '+14 min traffic delay on Route A corridor',
          '+2.4°C concrete temperature increase (now 34.8°C)',
          '68% rain probability along route segment',
          '-10.9% slump retention deficit (current: 89.1%)',
          'Projected transit (82 min) exceeds 78 min safe window',
        ],
        recommendedAction: 'CALCULATE_NEW_ROUTE',
        activeRouteId: 'route-a',
      );
      _simulationNarrative = 'CRITICAL RISK THRESHOLD BREACH: Projected transit (82 min) exceeds 78 min limit. Slump retention dropped to 89.1%. Action required!';
    } else if (_simulationStep == 3) {
      // Step 3: Route B Applied -> SAFE
      _selectedBatch = _selectedBatch.copyWith(
        elapsedMinutes: 50.0,
        etaMinutes: 16.0, // Total transit = 66 min <= 78 min!
        distanceRemainingKm: 9.4,
        ambientTempC: 36.2,
        concreteTempC: 34.2,
        currentSlumpMm: 102.0,
        slumpRetentionRatio: 0.927,
        heatRisk: 42.0,
        travelRisk: 30.0,
        deliveryRisk: 36.0,
        compositeRisk: 36.0,
        riskLevel: RiskLevel.safe,
        status: 'REROUTED',
        primaryDriver: 'Airport Bypass Expressway applied; bottleneck avoided',
        riskFactors: [
          'Alternative Route B active (-9 min transit saving)',
          'Slump retention stabilized at 92.7%',
          'Clear expressway segment ahead',
        ],
        recommendedAction: null,
        activeRouteId: 'route-b',
      );
      _simulationNarrative = 'Operator accepted Route B recommendation. Truck diverted to Airport Bypass. Transit normalized, slump retention protected.';
    } else if (_simulationStep == 4) {
      // Step 4: Site Arrival & Verified Delivery
      _selectedBatch = _selectedBatch.copyWith(
        elapsedMinutes: 66.0,
        etaMinutes: 0.0,
        distanceRemainingKm: 0.0,
        ambientTempC: 36.0,
        concreteTempC: 34.0,
        currentSlumpMm: 101.5,
        slumpRetentionRatio: 0.923,
        heatRisk: 32.0,
        travelRisk: 18.0,
        deliveryRisk: 24.0,
        compositeRisk: 24.6,
        riskLevel: RiskLevel.safe,
        status: 'DELIVERED',
        primaryDriver: 'Verified on-site delivery completed on specification',
        riskFactors: [
          'Site slump confirmed at 101.5 mm (Target: 105 mm)',
          'Transit completed in 66 min (within 78 min limit)',
          'Avoided batch loss: ₹1.68 Lakhs',
        ],
        recommendedAction: null,
        activeRouteId: 'route-b',
      );
      _simulationNarrative = 'Batch arrived at Project Site 07. Slump verified at 101.5 mm. Delivery accepted. Avoided financial loss of ₹1.68 Lakhs recorded.';
    }

    // Update in batches list
    final idx = _batches.indexWhere((b) => b.batchId == _selectedBatch.batchId);
    if (idx != -1) {
      _batches[idx] = _selectedBatch;
    }

    _apiService.stepSimulation(_simulationStep);
    notifyListeners();
  }

  void nextSimulationStep() {
    setSimulationStep(_simulationStep + 1);
  }

  void resetSimulation() {
    setSimulationStep(0);
  }

  // Mitigation Actions
  Future<void> applyAlternativeRoute() async {
    await _apiService.executeMitigation(
      batchId: _selectedBatch.batchId,
      action: 'CALCULATE_NEW_ROUTE',
    );
    setSimulationStep(3);
  }

  Future<void> addRetarderAdmixture() async {
    await _apiService.executeMitigation(
      batchId: _selectedBatch.batchId,
      action: 'ADD_RETARDER',
    );
    _selectedBatch = _selectedBatch.copyWith(
      status: 'RETARDER_ADDED',
      slumpRetentionRatio: (_selectedBatch.slumpRetentionRatio + 0.04).clamp(0.0, 0.98),
      deliveryRisk: (_selectedBatch.deliveryRisk - 25.0).clamp(20.0, 100.0),
      riskLevel: RiskLevel.watch,
      primaryDriver: 'Hydration retarded via chemical admixture (+30m window)',
    );
    notifyListeners();
  }

  Future<void> confirmOverride() async {
    await _apiService.executeMitigation(
      batchId: _selectedBatch.batchId,
      action: 'OVERRIDE_PROCEED',
      confirmed: true,
    );
    _selectedBatch = _selectedBatch.copyWith(
      riskFactors: List.from(_selectedBatch.riskFactors)..add('OPERATOR OVERRIDE LOGGED AT DISPATCH'),
    );
    notifyListeners();
  }

  // Delivery Order Creation Workflow
  DeliveryOrderDraft get currentDraft {
    if (_currentDraft != null) return _currentDraft!;
    final nextNumber = 200 + _batches.length + 1;
    final initialWeather = _weatherService.getDeliveryWindowWeather(
      location: 'Ahmedabad Central Corridor',
      dispatchTime: '14:00',
      transitMinutes: 78.0,
    );
    return DeliveryOrderDraft(
      batchCode: 'RMC-$nextNumber',
      plantId: 'plant-001',
      plantName: 'Ahmedabad Plant 01',
      projectId: 'project-007',
      projectName: 'Gift City Tower B',
      concreteGrade: 'M35',
      volumeM3: 6.0,
      initialSlumpMm: 120.0,
      targetSlumpMm: 100.0,
      slumpRetentionRequirementPct: 92.0,
      concreteTempC: 33.5,
      ambientTempC: initialWeather.ambientTempC,
      humidityPct: initialWeather.humidityPct,
      admixtureRetarder: 'None',
      selectedRouteId: 'route_a',
      dispatchTime: '14:00',
    );
  }

  void startCreateDelivery() {
    final nextNumber = 200 + _batches.length + 1;
    final initialWeather = _weatherService.getDeliveryWindowWeather(
      location: 'Ahmedabad Central Corridor',
      dispatchTime: '14:00',
      transitMinutes: 78.0,
    );
    _currentDraft = DeliveryOrderDraft(
      batchCode: 'RMC-$nextNumber',
      plantId: 'plant-001',
      plantName: 'Ahmedabad Plant 01',
      projectId: 'project-007',
      projectName: 'Gift City Tower B',
      concreteGrade: 'M35',
      volumeM3: 6.0,
      initialSlumpMm: 120.0,
      targetSlumpMm: 100.0,
      slumpRetentionRequirementPct: 92.0,
      concreteTempC: 33.5,
      ambientTempC: initialWeather.ambientTempC,
      humidityPct: initialWeather.humidityPct,
      admixtureRetarder: 'None',
      selectedRouteId: 'route_a',
      dispatchTime: '14:00',
    );
    _currentDraftRisk = null;
    _isCreatingDelivery = true;
    notifyListeners();
  }

  void cancelCreateDelivery() {
    if (!_isCreatingDelivery) return;
    _isCreatingDelivery = false;
    _currentDraft = null;
    _currentDraftRisk = null;
    notifyListeners();
  }

  void updateDeliveryDraft(DeliveryOrderDraft draft) {
    _currentDraft = draft;
    notifyListeners();
  }

  Future<DeliveryRiskAssessment> calculateDeliveryRisk([DeliveryOrderDraft? draft]) async {
    final targetDraft = draft ?? currentDraft;
    _isCalculatingRisk = true;
    _currentDraft = targetDraft;
    notifyListeners();

    try {
      final route = RouteService.getRoute(
        originName: targetDraft.plantName,
        destinationName: targetDraft.projectName,
        preferredRouteId: targetDraft.selectedRouteId,
      );

      // Execute authoritative RMC risk calculation on FastAPI Backend (PRD Section 1)
      final backendRisk = await _apiService.calculateRisk({
        'batch_id': targetDraft.batchCode,
        'plant_name': targetDraft.plantName,
        'project_name': targetDraft.projectName,
        'concrete_grade': targetDraft.concreteGrade,
        'volume_m3': targetDraft.volumeM3,
        'initial_slump_mm': targetDraft.initialSlumpMm,
        'target_slump_mm': targetDraft.targetSlumpMm,
        'ambient_temp_c': targetDraft.ambientTempC,
        'concrete_temp_c': targetDraft.concreteTempC,
        'relative_humidity': targetDraft.humidityPct,
        'traffic_index': route.trafficIndex,
        'planned_transit_minutes': route.etaMinutes,
        'dispatch_time': targetDraft.dispatchTime,
        'admixture_retarder': targetDraft.admixtureRetarder,
      });

      if (backendRisk != null) {
        final riskAssessment = DeliveryRiskAssessment.fromJson(backendRisk);
        _currentDraftRisk = riskAssessment;
        _isCalculatingRisk = false;
        notifyListeners();
        return riskAssessment;
      }

      // Fallback to local risk engine if backend is offline
      final risk = await _riskEngine.calculateRisk(targetDraft);
      _currentDraftRisk = risk;
      _isCalculatingRisk = false;
      notifyListeners();
      return risk;
    } catch (e) {
      final route = _riskEngine.getRouteById(targetDraft.selectedRouteId);
      final errorAssessment = DeliveryRiskAssessment(
        predictedSlumpMm: 0.0,
        slumpRetentionRatio: 0.0,
        heatRisk: 50.0,
        travelRisk: 75.0,
        deliveryRisk: 75.0,
        compositeRisk: 70.0,
        riskLevel: RiskLevel.highRisk,
        isApproved: false,
        statusLabel: 'DATA INSUFFICIENT / RISK UNAVAILABLE',
        primaryDriver: 'Risk calculation error or missing telemetry: $e',
        contributingFactors: ['Telemetry service unreachable or incomplete input', '$e'],
        recommendedAction: 'RESCHEDULE_BATCH',
        estimatedLossExposure: targetDraft.volumeM3 * 28000.0,
        predictedTransitMinutes: 0.0,
        etaDelayMinutes: 0.0,
        selectedRouteName: route.routeName,
        heatRiskLevel: RiskLevel.highRisk,
        travelRiskLevel: RiskLevel.highRisk,
        deliveryRiskLevel: RiskLevel.highRisk,
        expectedArrivalTime: '--:--',
        slaStatus: 'DATA_INSUFFICIENT',
        worstMaterialFactor: 'Telemetry unavailable',
        isDataInsufficient: true,
      );
      _currentDraftRisk = errorAssessment;
      _isCalculatingRisk = false;
      notifyListeners();
      return errorAssessment;
    }
  }


  Future<BatchModel> confirmAndDispatchDelivery([
    DeliveryOrderDraft? draft,
    DeliveryRiskAssessment? risk,
  ]) async {
    final targetDraft = draft ?? currentDraft;
    final targetRisk = risk ?? _currentDraftRisk ?? await calculateDeliveryRisk(targetDraft);
    final routeAssessment = RouteService.getRoute(
      originName: targetDraft.plantName,
      destinationName: targetDraft.projectName,
      preferredRouteId: targetDraft.selectedRouteId,
    );

    final double etaMin = targetRisk.predictedTransitMinutes > 0
        ? targetRisk.predictedTransitMinutes
        : routeAssessment.etaMinutes;

    // Real PostgreSQL Delivery Persistence
    final backendResult = await _apiService.createDelivery({
      'batch_code': targetDraft.batchCode,
      'plant_id': targetDraft.plantId,
      'plant_name': targetDraft.plantName,
      'project_id': targetDraft.projectId,
      'project_name': targetDraft.projectName,
      'concrete_grade': targetDraft.concreteGrade,
      'volume_m3': targetDraft.volumeM3,
      'target_slump_mm': targetDraft.targetSlumpMm,
      'initial_slump_mm': targetDraft.initialSlumpMm,
      'dispatch_time': targetDraft.dispatchTime,
      'admixture_retarder': targetDraft.admixtureRetarder,
      'planned_transit_minutes': etaMin,
    });

    final batchId = backendResult?['batch_id'] as String? ??
        backendResult?['id'] as String? ??
        'batch-${targetDraft.batchCode.toLowerCase()}';

    final newBatch = BatchModel(
      batchId: batchId,
      batchCode: targetDraft.batchCode,
      plantId: targetDraft.plantId,
      plantName: targetDraft.plantName,
      projectId: targetDraft.projectId,
      projectName: targetDraft.projectName,
      concreteGrade: targetDraft.concreteGrade,
      volumeM3: targetDraft.volumeM3,
      targetSlumpMm: targetDraft.targetSlumpMm,
      initialSlumpMm: targetDraft.initialSlumpMm,
      currentSlumpMm: targetRisk.predictedSlumpMm > 0 ? targetRisk.predictedSlumpMm : targetDraft.initialSlumpMm,
      slumpRetentionRatio: targetRisk.slumpRetentionRatio > 0 ? targetRisk.slumpRetentionRatio : 1.0,
      concreteTempC: targetDraft.concreteTempC,
      ambientTempC: targetDraft.ambientTempC,
      elapsedMinutes: 0.0,
      etaMinutes: etaMin,
      originalEtaMinutes: etaMin,
      distanceRemainingKm: routeAssessment.distanceKm,
      totalDistanceKm: routeAssessment.distanceKm,
      trafficIndex: targetRisk.travelRisk > 50 ? 0.65 : routeAssessment.trafficIndex,
      precipitationProb: routeAssessment.precipitationProb,
      status: 'DISPATCHED',
      riskLevel: targetRisk.riskLevel,
      heatRisk: targetRisk.heatRisk,
      travelRisk: targetRisk.travelRisk,
      deliveryRisk: targetRisk.deliveryRisk,
      compositeRisk: targetRisk.compositeRisk,
      primaryDriver: targetRisk.primaryDriver,
      riskFactors: targetRisk.contributingFactors,
      recommendedAction: targetRisk.recommendedAction,
      activeRouteId: targetDraft.selectedRouteId,
      retarderDose: targetDraft.admixtureRetarder == 'None' ? null : targetDraft.admixtureRetarder,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Prepend to active deliveries list
    _batches.insert(0, newBatch);
    _selectedBatch = newBatch;
    _isCreatingDelivery = false;
    _currentDraft = null;
    _currentDraftRisk = null;
    _lastUpdated = DateTime.now();

    notifyListeners();
    return newBatch;
  }

  Future<void> submitOutcome({
    required String outcome,
    required double siteSlumpMm,
    required double transitMinutes,
    required double concreteTempC,
    String? rejectionReason,
  }) async {
    final result = await _apiService.recordOutcome(
      batchId: _selectedBatch.batchId,
      outcome: outcome,
      siteSlumpMm: siteSlumpMm,
      transitMinutes: transitMinutes,
      concreteTempC: concreteTempC,
      rejectionReason: rejectionReason,
    );
    _outcomes.insert(0, result);

    // Update the selected batch with completed delivery status
    _selectedBatch = _selectedBatch.copyWith(
      status: outcome == 'rejected' ? 'REJECTED' : 'DELIVERED',
      currentSlumpMm: siteSlumpMm,
      slumpRetentionRatio: (siteSlumpMm / _selectedBatch.initialSlumpMm).clamp(0.0, 1.0),
      concreteTempC: concreteTempC,
      elapsedMinutes: transitMinutes,
      etaMinutes: 0.0,
      distanceRemainingKm: 0.0,
      riskLevel: outcome == 'rejected' ? RiskLevel.critical : RiskLevel.safe,
      primaryDriver: outcome == 'rejected'
          ? 'Batch rejected at site: ${rejectionReason ?? "Slump out of specification"}'
          : 'Verified on-site delivery completed on specification',
    );

    final idx = _batches.indexWhere((b) => b.batchId == _selectedBatch.batchId);
    if (idx != -1) {
      _batches[idx] = _selectedBatch;
    }

    setSimulationStep(4);
  }
}
