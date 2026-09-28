import 'package:flutter/material.dart';
import 'core/theme/mausam_theme.dart';
import 'core/navigation/mausam_router.dart';
import 'state/mausam_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MausamApp());
}

class MausamApp extends StatefulWidget {
  final String? initialScreen;

  const MausamApp({
    super.key,
    this.initialScreen,
  });

  @override
  State<MausamApp> createState() => _MausamAppState();
}

class _MausamAppState extends State<MausamApp> {
  late final MausamState _state;
  late final MausamRouterDelegate _routerDelegate;
  late final MausamRouteInformationParser _routeInformationParser;

  @override
  void initState() {
    super.initState();
    _state = MausamState();
    if (widget.initialScreen == 'app') {
      _state.selectRoleAndLaunch('rmc');
    } else if (widget.initialScreen != null) {
      _state.navigateTo(widget.initialScreen!);
    }
    _routerDelegate = MausamRouterDelegate(state: _state);
    _routeInformationParser = MausamRouteInformationParser();
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'mausam_dynamic_weather',
          debugShowCheckedModeBanner: false,
          theme: MausamTheme.lightTheme,
          darkTheme: MausamTheme.darkTheme,
          themeMode: _state.themeMode,
          routerDelegate: _routerDelegate,
          routeInformationParser: _routeInformationParser,
        );
      },
    );
  }
}
