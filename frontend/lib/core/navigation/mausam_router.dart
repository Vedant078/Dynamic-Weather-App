import 'package:flutter/material.dart';
import '../../features/landing/landing_hero_screen.dart';
import '../../features/auth/authentication_screen.dart';
import '../../features/rbac/rbac_role_selection_screen.dart';
import '../../design_system/components/mausam_scaffold.dart';
import '../../design_system/components/simulation_sheet.dart';
import '../../features/rmc/dashboard/rmc_command_center_screen.dart';
import '../../features/rmc/create_delivery/create_delivery_screen.dart';
import '../../features/rmc/batch_detail/batch_detail_screen.dart';
import '../../features/rmc/routes/route_intelligence_screen.dart';
import '../../features/rmc/outcome/delivery_outcome_screen.dart';
import '../../features/rmc/analytics/fleet_analytics_screen.dart';
import '../../features/weather/consumer_weather_screen.dart';
import '../../state/mausam_state.dart';

/// Typed route paths for MAUSAM Navigation Boundary
enum MausamRoutePath {
  landing('/'),
  auth('/auth'),
  rbac('/rbac'),
  app('/app');

  final String path;
  const MausamRoutePath(this.path);

  static MausamRoutePath fromUri(Uri uri) {
    // Check path or fragment (handles both path-based and hash-based routing in web)
    var pathStr = uri.path;
    if (pathStr.isEmpty || pathStr == '/') {
      if (uri.fragment.isNotEmpty) {
        pathStr = uri.fragment;
      }
    }
    if (!pathStr.startsWith('/')) {
      pathStr = '/$pathStr';
    }

    if (pathStr == '/auth' || pathStr == '/login' || pathStr == '/signin') {
      return MausamRoutePath.auth;
    }
    if (pathStr == '/rbac' || pathStr == '/persona' || pathStr == '/workspace' || pathStr == '/role') {
      return MausamRoutePath.rbac;
    }
    if (pathStr == '/app' || pathStr == '/rmc' || pathStr == '/dashboard') {
      return MausamRoutePath.app;
    }
    return MausamRoutePath.landing;
  }
}

/// Route Information Parser: translates URL <-> MausamRoutePath
class MausamRouteInformationParser extends RouteInformationParser<MausamRoutePath> {
  @override
  Future<MausamRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    return MausamRoutePath.fromUri(uri);
  }

  @override
  RouteInformation? restoreRouteInformation(MausamRoutePath configuration) {
    return RouteInformation(uri: Uri.parse(configuration.path));
  }
}

/// Router Delegate enforcing strict authentication navigation boundaries:
/// 1. Unauthenticated users always start at Landing/Hero.
/// 2. Hero -> Sign In (Browser back returns to Hero).
/// 3. Successful login replaces auth route and transitions to RBAC Role Selection.
/// 4. Authenticated users cannot pop back to Login (immune to browser/Android back).
/// 5. Direct access to /auth, /login, /signin while authenticated redirects to RBAC or App.
/// 6. Logout clears authenticated state and navigation history, returning to Hero.
class MausamRouterDelegate extends RouterDelegate<MausamRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<MausamRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;
  final MausamState state;
  int _navIndex = 0;

  MausamRouterDelegate({required this.state})
      : navigatorKey = GlobalKey<NavigatorState>() {
    state.addListener(notifyListeners);
  }

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  MausamRoutePath get currentConfiguration {
    if (!state.isAuthenticated) {
      if (state.currentScreen == 'auth') return MausamRoutePath.auth;
      return MausamRoutePath.landing;
    } else {
      if (state.currentScreen == 'app') return MausamRoutePath.app;
      return MausamRoutePath.rbac;
    }
  }

  bool _initialized = false;

  @override
  Future<void> setNewRoutePath(MausamRoutePath configuration) async {
    if (!_initialized) {
      _initialized = true;
      if (state.currentScreen == 'auth' || state.currentScreen == 'app' || state.currentScreen == 'rbac') {
        return;
      }
    }

    // Route Boundary Guard
    if (state.isAuthenticated) {
      // CASE D: Authenticated user attempting to access /auth, /login, or / is redirected
      if (configuration == MausamRoutePath.auth || configuration == MausamRoutePath.landing) {
        state.navigateTo(state.currentScreen == 'app' ? 'app' : 'rbac');
        return;
      }
      state.navigateTo(configuration == MausamRoutePath.app ? 'app' : 'rbac');
    } else {
      // Unauthenticated user:
      // Direct access to protected routes redirects to Hero (landing)
      if (configuration == MausamRoutePath.rbac || configuration == MausamRoutePath.app) {
        state.navigateTo('landing');
        return;
      }
      state.navigateTo(configuration == MausamRoutePath.auth ? 'auth' : 'landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = state.isAuthenticated;
    final currentScreen = state.currentScreen;

    return Navigator(
      key: navigatorKey,
      pages: [
        // ====================================================================
        // UNAUTHENTICATED STACK
        // ====================================================================
        if (!isAuthenticated) ...[
          // 1. Root: Landing / Hero page (always accessible when unauthenticated)
          MaterialPage(
            key: const ValueKey('landing_page'),
            child: LandingHeroScreen(
              state: state,
              onGetStarted: () => state.navigateTo('auth'),
              onSignIn: () => state.navigateTo('auth'),
              onSelectPersona: (personaId) {
                state.navigateTo('auth');
              },
            ),
          ),
          // 2. Auth page pushed on top of landing
          // (Ensures Browser Back / Android Back returns to Hero — Case A)
          if (currentScreen == 'auth')
            MaterialPage(
              key: const ValueKey('auth_page'),
              child: AuthenticationScreen(
                onBackToLanding: () => state.navigateTo('landing'),
                errorMessage: state.authError,
                isLoading: state.isAuthenticating,
                onSignIn: (email, password) {
                  state.signIn(email: email, password: password);
                },
                onSignUp: (name, email, password) {
                  state.signUp(name: name, email: email, password: password);
                },
                onGoogleSignIn: () {
                  state.continueWithGoogle();
                },
              ),
            ),
        ],

        // ====================================================================
        // AUTHENTICATED STACK (Login is completely omitted from the stack!)
        // ====================================================================
        if (isAuthenticated) ...[
          // 1. Root of authenticated flow: RBAC Role Selection Screen
          MaterialPage(
            key: const ValueKey('rbac_page'),
            child: PopScope(
              canPop: false, // Prevents Android back / browser back from exiting to Login!
              child: RbacRoleSelectionScreen(
                personas: state.personas,
                userEmail: state.userEmail,
                userName: state.userName,
                authorizedRoleIds: state.userRoleIds,
                operationalSummary: state.rmcOperationalSummary,
                onSignOut: () => state.signOut(),
                onSelectRole: (roleId) {
                  state.selectRoleAndLaunch(roleId);
                  _navIndex = 0;
                },
              ),
            ),
          ),
          // 2. Operational App sits on top of RBAC Role Selection
          // (Popping from App returns to RBAC Role Selection — Case C, NEVER Login!)
          if (currentScreen == 'app') ...[
            MaterialPage(
              key: const ValueKey('app_page'),
              child: PopScope(
                canPop: !state.isCreatingDelivery,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) {
                    state.navigateTo('rbac');
                  }
                },
                child: _buildAppScaffold(context),
              ),
            ),
            if (state.isCreatingDelivery)
              MaterialPage(
                key: const ValueKey('create_delivery_page'),
                child: PopScope(
                  canPop: true,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop && state.isCreatingDelivery) {
                      state.cancelCreateDelivery();
                    }
                  },
                  child: CreateDeliveryScreen(
                    state: state,
                    onDispatched: () {
                      _updateNav(1); // Navigate to live telemetry of dispatched batch
                    },
                  ),
                ),
              ),
          ],
        ],
      ],
      onDidRemovePage: (page) {
        if (page.key == const ValueKey('auth_page')) {
          state.navigateTo('landing');
        } else if (page.key == const ValueKey('app_page')) {
          state.navigateTo('rbac');
        } else if (page.key == const ValueKey('create_delivery_page')) {
          if (state.isCreatingDelivery) {
            state.cancelCreateDelivery();
          }
        }
      },
    );
  }

  Widget _buildAppScaffold(BuildContext context) {
    final isRmc = state.selectedPersonaId == 'rmc';

    Widget bodyWidget;
    if (isRmc) {
      switch (_navIndex) {
        case 0:
          bodyWidget = RmcCommandCenterScreen(
            state: state,
            onOpenBatchDetail: () => _updateNav(1),
            onOpenRoutes: () => _updateNav(2),
            onOpenOutcome: () => _updateNav(3),
          );
          break;
        case 1:
          bodyWidget = BatchDetailScreen(
            state: state,
            onNavigateToRoutes: () => _updateNav(2),
            onNavigateToOutcome: () => _updateNav(3),
          );
          break;
        case 2:
          bodyWidget = RouteIntelligenceScreen(state: state);
          break;
        case 3:
          bodyWidget = DeliveryOutcomeScreen(state: state);
          break;
        case 4:
          bodyWidget = FleetAnalyticsScreen(state: state);
          break;
        default:
          bodyWidget = RmcCommandCenterScreen(
            state: state,
            onOpenBatchDetail: () => _updateNav(1),
            onOpenRoutes: () => _updateNav(2),
            onOpenOutcome: () => _updateNav(3),
          );
      }
    } else {
      bodyWidget = ConsumerWeatherScreen(persona: state.currentPersona);
    }

    return MausamScaffold(
      body: bodyWidget,
      currentNavIndex: _navIndex,
      onNavChanged: (idx) => _updateNav(idx),
      currentPersona: state.currentPersona,
      allPersonas: state.personas,
      onPersonaChanged: (personaId) {
        if (personaId == 'selector') {
          state.navigateTo('rbac');
        } else {
          state.setPersona(personaId);
          _updateNav(0);
        }
      },
      lastUpdated: state.lastUpdated,
      atRiskCount: state.batches.where((b) => b.riskLevel.name == 'highRisk').length,
      onAlertsTap: () {
        _updateNav(isRmc ? 1 : 0);
      },
      isDarkMode: state.isDarkMode,
      onThemeToggle: state.toggleTheme,
      simulationStep: state.simulationStep,
      onDemoTap: () {
        SimulationSheet.show(
          context,
          currentStep: state.simulationStep,
          narrative: state.simulationNarrative,
          onStepSelected: state.setSimulationStep,
          onReset: state.resetSimulation,
        );
      },
    );
  }

  void _updateNav(int index) {
    _navIndex = index;
    notifyListeners();
  }
}
