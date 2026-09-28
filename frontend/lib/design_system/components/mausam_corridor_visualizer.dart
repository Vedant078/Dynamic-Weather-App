import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_typography.dart';
import '../../core/theme/mausam_icons.dart';

/// Custom Environmental Corridor Visualizer for MAUSAM Hero / Landing
/// Visualizes the core product thesis:
/// ENVIRONMENT (Microclimate Heat + Congestion) → INTELLIGENCE (Slump Kinetics) → DECISION
/// Shows an active transit corridor (Plant Alpha → GIFT City via SP Ring Road)
/// with real-time temperature zones, route polyline, vehicle marker, and telemetry annotations.
class MausamCorridorVisualizer extends StatefulWidget {
  final bool isCompact;

  const MausamCorridorVisualizer({
    super.key,
    this.isCompact = false,
  });

  @override
  State<MausamCorridorVisualizer> createState() => _MausamCorridorVisualizerState();
}

class _MausamCorridorVisualizerState extends State<MausamCorridorVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTesting) {
      _pulseController.repeat();
    } else {
      _pulseController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? MausamColors.borderDark : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Technical Telemetry Header Bar
            _buildHeader(context, isDark),

            // 2. Custom Painted Environmental Corridor Canvas
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(double.infinity, 160),
                  painter: _CorridorCanvasPainter(
                    pulseValue: _pulseController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),

            // 3. Corridor Microclimate Zone Indicators
            _buildCorridorZoneLegend(context, isDark),

            // 4. Scannable Real-Time Telemetry Summary
            _buildTelemetrySummary(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E27) : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? MausamColors.borderSubtleDark : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SP Ring Road • Corridor Trajectory',
                    style: MausamTypography.microOf(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: MausamColors.txtPrimary(context),
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(MausamIcons.alert, size: 10, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  'Thermal Watch: 40.8°C',
                  style: MausamTypography.micro.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorZoneLegend(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111820) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? MausamColors.borderSubtleDark : const Color(0xFFF1F5F9),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildZoneIndicator(
            context,
            dotColor: const Color(0xFF0284C7),
            title: 'Plant A (Km 0)',
            desc: '31.4°C Nominal',
          ),
          const Icon(MausamIcons.chevronRight, size: 12, color: Color(0xFF94A3B8)),
          _buildZoneIndicator(
            context,
            dotColor: const Color(0xFFD97706),
            title: 'Heat Corridor (Km 14)',
            desc: '40.8°C Peak Solar',
          ),
          const Icon(MausamIcons.chevronRight, size: 12, color: Color(0xFF94A3B8)),
          _buildZoneIndicator(
            context,
            dotColor: const Color(0xFF059669),
            title: 'GIFT Site (Km 28)',
            desc: 'ETA 21m • Safe Pour',
          ),
        ],
      ),
    );
  }

  Widget _buildZoneIndicator(
    BuildContext context, {
    required Color dotColor,
    required String title,
    required String desc,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: MausamTypography.microOf(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              desc,
              style: MausamTypography.microOf(context).copyWith(
                fontSize: 9.0,
                color: MausamColors.txtMuted(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetrySummary(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E27) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? MausamColors.borderDark : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              context,
              label: 'Concrete Temp',
              value: '34.8°C',
              sub: '↑ 1.4° in 12m',
              icon: MausamIcons.temperature,
              alertColor: const Color(0xFFD97706),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: isDark ? MausamColors.borderSubtleDark : const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: _buildMetricTile(
              context,
              label: 'Slump Retention',
              value: '91.2%',
              sub: 'Nominal 90% SLA',
              icon: MausamIcons.slump,
              alertColor: const Color(0xFF0284C7),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: isDark ? MausamColors.borderSubtleDark : const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: _buildMetricTile(
              context,
              label: 'Protected Batch',
              value: 'Loss Avoided',
              sub: 'Dynamic Prevention',
              icon: MausamIcons.currencyRupee,
              alertColor: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color alertColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10.5, color: alertColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: MausamTypography.microOf(context).copyWith(
                  fontSize: 9.5,
                  color: MausamColors.txtMuted(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: MausamTypography.labelBoldOf(context).copyWith(
            fontSize: 13,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          sub,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 8.5,
            color: MausamColors.txtMuted(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Custom Canvas Painter rendering:
/// 1. Isobar pressure contour curves
/// 2. Thermal zone background gradient wash
/// 3. Curved route trajectory polyline
/// 4. Vehicle marker with animated sonar pulse
/// 5. Telemetry callout flag: "RMC-204 • In Transit"
class _CorridorCanvasPainter extends CustomPainter {
  final double pulseValue;
  final bool isDark;

  _CorridorCanvasPainter({
    required this.pulseValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle Isobar Atmospheric Background Lines
    final isobarPaint = Paint()
      ..color = isDark
          ? const Color(0xFF38BDF8).withValues(alpha: 0.08)
          : const Color(0xFF0284C7).withValues(alpha: 0.07)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = h * 0.2 + (i * 28.0);
      path.moveTo(0, yOffset);
      path.cubicTo(
        w * 0.25, yOffset - 18,
        w * 0.65, yOffset + 22,
        w, yOffset - 8,
      );
      canvas.drawPath(path, isobarPaint);
    }

    // 2. Thermal Heat Corridor Zone (Center Amber Wash)
    final thermalRect = Rect.fromLTWH(w * 0.35, 0, w * 0.40, h);
    final thermalPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFD97706).withValues(alpha: isDark ? 0.12 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(thermalRect);
    canvas.drawRect(thermalRect, thermalPaint);

    // 3. Route Trajectory Geometry
    final startPoint = Offset(w * 0.08, h * 0.72);
    final vehiclePoint = Offset(w * 0.52, h * 0.46);
    final destPoint = Offset(w * 0.92, h * 0.26);

    // Traveled Route (Solid Cyan/Atmosphere line)
    final traveledPath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        w * 0.24, h * 0.68,
        w * 0.38, h * 0.48,
        vehiclePoint.dx, vehiclePoint.dy,
      );

    final traveledPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(traveledPath, traveledPaint);

    // Projected Route (Dashed or Muted line)
    final projectedPath = Path()
      ..moveTo(vehiclePoint.dx, vehiclePoint.dy)
      ..cubicTo(
        w * 0.68, h * 0.44,
        w * 0.80, h * 0.30,
        destPoint.dx, destPoint.dy,
      );

    final projectedPaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(projectedPath, projectedPaint);

    // 4. Origin & Destination Waypoints
    _drawWaypoint(canvas, startPoint, 'PLANT A', const Color(0xFF0284C7));
    _drawWaypoint(canvas, destPoint, 'GIFT-42', const Color(0xFF059669));

    // 5. Vehicle Sonar Radar Pulse & Marker
    final pulseRadius = 12.0 + (pulseValue * 16.0);
    final pulseOpacity = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.4;
    final pulsePaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(vehiclePoint, pulseRadius, pulsePaint);

    // Vehicle Core Circle
    final corePaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(vehiclePoint, 6.0, corePaint);
    final innerWhite = Paint()..color = Colors.white;
    canvas.drawCircle(vehiclePoint, 2.5, innerWhite);

    // 6. Floating Technical Annotation Flag for Vehicle
    final flagOffset = Offset(vehiclePoint.dx - 48, vehiclePoint.dy - 38);
    final flagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(flagOffset.dx, flagOffset.dy, 98, 24),
      const Radius.circular(5.0),
    );

    final flagBgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;
    final flagBorderPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(flagRect, flagBgPaint);
    canvas.drawRRect(flagRect, flagBorderPaint);

    // Connector Line from flag to vehicle
    final connectorPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(vehiclePoint.dx, flagOffset.dy + 24),
      Offset(vehiclePoint.dx, vehiclePoint.dy - 6),
      connectorPaint,
    );

    // Text inside annotation flag
    final textPainter = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'RMC-204  ',
            style: TextStyle(
              fontSize: 9.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: 0.2,
            ),
          ),
          TextSpan(
            text: 'WATCH',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(flagOffset.dx + 8, flagOffset.dy + 6));
  }

  void _drawWaypoint(Canvas canvas, Offset point, String label, Color color) {
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(point, 7.0, ringPaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(point, 3.5, dotPaint);

    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(point.dx - (labelPainter.width / 2), point.dy + 9));
  }

  @override
  bool shouldRepaint(covariant _CorridorCanvasPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.isDark != isDark;
  }
}
