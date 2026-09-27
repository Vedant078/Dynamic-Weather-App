import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/current_weather.dart';
import '../../../services/location_service.dart';
import '../../../state/mausam_state.dart';

/// Dynamic, reference-compliant Current Weather Card for the Hero Page
/// (Strictly follows the visual reference in the attached template & Section 5, 6, 7, 8, 9, 10)
class HeroWeatherCard extends StatefulWidget {
  final MausamState state;
  final bool isDark;

  const HeroWeatherCard({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  State<HeroWeatherCard> createState() => _HeroWeatherCardState();
}

class _HeroWeatherCardState extends State<HeroWeatherCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final weather = widget.state.heroWeather;
    final isLoading = widget.state.isLoadingHeroWeather && weather == null;
    final error = widget.state.heroWeatherError;

    // Atmospheric lavender canvas backdrop matching the design reference
    final containerBg = widget.isDark
        ? const Color(0xFF1A1F33)
        : const Color(0xFFC7CBE8);

    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF131B26) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF27323D) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : const Color(0xFF0F172A).withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? _buildLoadingSkeleton(context)
                : (error != null && weather == null)
                    ? _buildErrorState(context, error)
                    : _buildWeatherContent(context, weather!),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTENT VIEW: Follows the exact reference template
  // ===========================================================================
  Widget _buildWeatherContent(BuildContext context, CurrentWeather weather) {
    return Column(
      key: ValueKey('${weather.locationName}_${weather.temperature}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Section: Scenic Atmospheric Sky & Landmark Art with Temp & Condition
        SizedBox(
          height: 195,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Custom vector landscape (Sun/Moon, Stars/Birds, Opera House/Skyline, Boat, Water)
              CustomPaint(
                painter: _HeroWeatherIllustrationPainter(
                  isDark: widget.isDark,
                  isSunny: weather.condition.toLowerCase().contains('sun') ||
                      weather.condition.toLowerCase().contains('clear'),
                  isDay: weather.isDay,
                ),
              ),

              // Temperature and Condition Text Overlay (Top Right of Scene)
              Positioned(
                top: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${weather.temperature.round()}°C',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: !weather.isDay
                            ? Colors.white
                            : (widget.isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B)),
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          !weather.isDay
                              ? (weather.condition.toLowerCase().contains('cloud')
                                  ? LucideIcons.cloudMoon
                                  : LucideIcons.moon)
                              : (weather.condition.toLowerCase().contains('cloud')
                                  ? LucideIcons.cloudSun
                                  : LucideIcons.sun),
                          size: 13,
                          color: !weather.isDay
                              ? const Color(0xFFBAE6FD)
                              : (widget.isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          weather.condition,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: !weather.isDay
                                ? const Color(0xFFF1F5F9)
                                : (widget.isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Middle Section: Location Name and Formatted Date/Time
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weather.locationName,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (widget.state.currentLocation.isDetected) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEAR YOU',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                weather.formattedDateTime,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. 5-Day Forecast Row (Mon, Tue, Wed, Thu, Fri with Icons and Temps)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weather.forecastDays.take(5).map((day) {
              return _buildForecastDayColumn(day);
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // 4. "More details" interactive expander with chevron
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isExpanded ? 'Less details' : 'More details',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 13,
                  color: widget.isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),

        // 5. Expandable Secondary Operational Telemetry & Location Switcher
        if (_isExpanded) ...[
          Divider(
            height: 1,
            color: widget.isDark ? const Color(0xFF27323D) : const Color(0xFFE2E8F0),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Secondary Metrics Grid
                Row(
                  children: [
                    _buildSubMetric(
                      'Feels like',
                      '${weather.feelsLike.round()}°C',
                      LucideIcons.thermometer,
                    ),
                    const SizedBox(width: 8),
                    _buildSubMetric(
                      'Humidity',
                      '${weather.humidity.round()}%',
                      LucideIcons.droplets,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSubMetric(
                      'Wind speed',
                      '${weather.windSpeedKmh.round()} km/h',
                      LucideIcons.wind,
                    ),
                    const SizedBox(width: 8),
                    _buildSubMetric(
                      'Precipitation',
                      '${weather.precipitationProbability.round()}%',
                      LucideIcons.cloudRain,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Location Presets Switcher (Ahmedabad, Mumbai, Delhi, Bengaluru, Pune, Sydney)
                Text(
                  'Switch Location:',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Auto-detect button
                    InkWell(
                      onTap: () => widget.state.initHeroLocationAndWeather(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.locate, size: 10, color: Color(0xFF0284C7)),
                            SizedBox(width: 4),
                            Text(
                              'Auto-Detect',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Presets
                    ...LocationService.supportedPresets.map((loc) {
                      final isSelected = loc.cityName.toLowerCase() == weather.locationName.toLowerCase();
                      return InkWell(
                        onTap: () => widget.state.changeLocation(loc),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A))
                                : (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            loc.cityName,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? (widget.isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : (widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 10),
                // Source attribution
                Text(
                  weather.source,
                  style: TextStyle(
                    fontSize: 9,
                    color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildForecastDayColumn(ForecastDay day) {
    IconData icon = LucideIcons.cloud;
    Color iconColor = const Color(0xFF64748B);

    final cond = day.condition.toLowerCase();
    if (cond.contains('sun') || cond.contains('clear')) {
      icon = LucideIcons.sun;
      iconColor = const Color(0xFFF59E0B);
    } else if (cond.contains('rain') || cond.contains('drizzle')) {
      icon = LucideIcons.cloudRain;
      iconColor = const Color(0xFF0284C7);
    } else if (cond.contains('wind') || cond.contains('breeze')) {
      icon = LucideIcons.wind;
      iconColor = const Color(0xFF0EA5E9);
    } else if (cond.contains('partly')) {
      icon = LucideIcons.cloudSun;
      iconColor = const Color(0xFF38BDF8);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day.dayName,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(height: 6),
        Text(
          '${day.maxTempC.round()}°',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildSubMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF0284C7)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LOADING SKELETON: Consistent footprint to prevent UI layout jumps
  // ===========================================================================
  Widget _buildLoadingSkeleton(BuildContext context) {
    return Container(
      key: const ValueKey('loading_skeleton'),
      height: 310,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Detecting your location...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resolving meteorological conditions',
            style: TextStyle(
              fontSize: 11.5,
              color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ERROR STATE: Clean fallback without fabricated data
  // ===========================================================================
  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      key: const ValueKey('error_state'),
      height: 310,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.cloudOff, size: 36, color: Color(0xFFE11D48)),
          const SizedBox(height: 14),
          Text(
            'Weather unavailable',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => widget.state.refreshHeroWeather(),
            icon: const Icon(LucideIcons.refreshCw, size: 12),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VECTOR ILLUSTRATION PAINTER: Reproduces the artwork from the reference image
// Glowing Yellow Sun + Highlight Crescent + Birds + Sail Landmark + Boat + Ripples
// =============================================================================
class _HeroWeatherIllustrationPainter extends CustomPainter {
  final bool isDark;
  final bool isSunny;
  final bool isDay;

  _HeroWeatherIllustrationPainter({
    required this.isDark,
    required this.isSunny,
    required this.isDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient Background (Light daylight vs deep twilight nocturnal sky)
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDay
            ? (isDark
                ? [
                    const Color(0xFF16253B),
                    const Color(0xFF1E344F),
                    const Color(0xFF1C2A3A),
                  ]
                : [
                    const Color(0xFFC7E7FA),
                    const Color(0xFFDFF0FA),
                    const Color(0xFFD2E8F6),
                  ])
            : [
                const Color(0xFF0D1B2A),
                const Color(0xFF1B263B),
                const Color(0xFF25344D),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    if (isDay) {
      // 2. Radiant Glowing Sun with Crescent Reflection (Top Left)
      final sunCenter = Offset(w * 0.26, h * 0.28);
      final sunRadius = w * 0.11;

      // Outer soft glow halo
      final glowPaint = Paint()
        ..color = (isSunny ? const Color(0xFFFDE047) : const Color(0xFFCBD5E1))
            .withValues(alpha: isDark ? 0.25 : 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(sunCenter, sunRadius + 6, glowPaint);

      // Main sun body
      final sunBodyPaint = Paint()
        ..shader = RadialGradient(
          colors: isSunny
              ? [
                  const Color(0xFFFFFBEB),
                  const Color(0xFFFDE047),
                  const Color(0xFFF59E0B),
                ]
              : [
                  const Color(0xFFF1F5F9),
                  const Color(0xFFE2E8F0),
                  const Color(0xFF94A3B8),
                ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
      canvas.drawCircle(sunCenter, sunRadius, sunBodyPaint);

      // Crescent highlight curve inside sun (as seen in reference)
      final crescentPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      final crescentRect = Rect.fromCircle(center: sunCenter, radius: sunRadius * 0.72);
      canvas.drawArc(crescentRect, -math.pi * 0.75, math.pi * 0.5, false, crescentPaint);

      // 3. Subtle Birds in Flight (Left Sky)
      final birdPaint = Paint()
        ..color = (isDark ? const Color(0xFF64748B) : const Color(0xFF475569))
            .withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      _drawBird(canvas, Offset(w * 0.22, h * 0.40), 9, birdPaint);
      _drawBird(canvas, Offset(w * 0.25, h * 0.45), 7, birdPaint);
      _drawBird(canvas, Offset(w * 0.21, h * 0.48), 6, birdPaint);
    } else {
      // 2. Radiant Glowing Crescent Moon (Top Left)
      final moonCenter = Offset(w * 0.26, h * 0.28);
      final moonRadius = w * 0.105;

      // Soft silvery outer glow halo
      final moonGlow = Paint()
        ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(moonCenter, moonRadius + 6, moonGlow);

      // Draw graceful crescent moon shape
      final outerMoon = Path()..addOval(Rect.fromCircle(center: moonCenter, radius: moonRadius));
      final innerCutout = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(moonCenter.dx + moonRadius * 0.42, moonCenter.dy - moonRadius * 0.18),
          radius: moonRadius * 0.88,
        ));
      final crescentMoon = Path.combine(PathOperation.difference, outerMoon, innerCutout);

      final moonPaint = Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFF1F5F9),
            Color(0xFFCBD5E1),
          ],
        ).createShader(Rect.fromCircle(center: moonCenter, radius: moonRadius));
      canvas.drawPath(crescentMoon, moonPaint);

      // 3. Subtle Sparkling Stars in Night Sky
      _drawStar(canvas, Offset(w * 0.14, h * 0.18), 1.8);
      _drawStar(canvas, Offset(w * 0.22, h * 0.44), 1.3);
      _drawStar(canvas, Offset(w * 0.38, h * 0.20), 2.0);
      _drawStar(canvas, Offset(w * 0.45, h * 0.38), 1.2);
      _drawStar(canvas, Offset(w * 0.12, h * 0.40), 1.5);
    }

    // 4. Water Horizon & Base (Lower third)
    final waterY = h * 0.68;
    final waterPaint = Paint()
      ..color = isDay
          ? (isDark ? const Color(0xFF1B3A57) : const Color(0xFF7DD3FC).withValues(alpha: 0.7))
          : const Color(0xFF0F1E2E);
    canvas.drawRect(Rect.fromLTWH(0, waterY, w, h - waterY), waterPaint);

    // Water ripple line
    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDay ? (isDark ? 0.2 : 0.45) : 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.12, waterY + 6), Offset(w * 0.35, waterY + 6), ripplePaint);
    canvas.drawLine(Offset(w * 0.55, waterY + 8), Offset(w * 0.72, waterY + 8), ripplePaint);

    // 5. Stylized Sail Landmark (Opera House style architectural silhouettes)
    final landmarkCenter = Offset(w * 0.48, waterY);
    _drawLandmarkSails(canvas, landmarkCenter, w * 0.28, isDark);

    // 6. Little Nautical Boat with Flag (Right of Landmark on Water)
    _drawLittleBoat(canvas, Offset(w * 0.78, waterY + 12), isDark);

    // 7. Soft Rolling Mist/Clouds at the bottom framing the illustration
    final mistPaint = Paint()
      ..color = (isDark ? const Color(0xFF131B26) : Colors.white).withValues(alpha: 0.85);

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 14)
      ..quadraticBezierTo(w * 0.25, h - 26, w * 0.5, h - 12)
      ..quadraticBezierTo(w * 0.75, h - 28, w, h - 14)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, mistPaint);
  }

  void _drawBird(Canvas canvas, Offset pos, double size, Paint paint) {
    final path = Path()
      ..moveTo(pos.dx - size, pos.dy)
      ..quadraticBezierTo(pos.dx - size / 2, pos.dy - size * 0.4, pos.dx, pos.dy)
      ..quadraticBezierTo(pos.dx + size / 2, pos.dy - size * 0.4, pos.dx + size, pos.dy);
    canvas.drawPath(path, paint);
  }

  void _drawLandmarkSails(Canvas canvas, Offset base, double width, bool isDark) {
    final sailFill = Paint()
      ..color = isDark ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    final sailShadow = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final sailBorder = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Platform foundation
    final baseRect = Rect.fromLTWH(base.dx - width * 0.65, base.dy - 6, width * 1.3, 8);
    canvas.drawRect(
      baseRect,
      Paint()..color = isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8),
    );

    // Sail 1 (Leftmost large curve)
    final sail1 = Path()
      ..moveTo(base.dx - width * 0.50, base.dy - 6)
      ..cubicTo(
        base.dx - width * 0.40, base.dy - 48,
        base.dx - width * 0.15, base.dy - 42,
        base.dx - width * 0.10, base.dy - 6,
      )
      ..close();
    canvas.drawPath(sail1, sailShadow);
    canvas.drawPath(sail1, sailBorder);

    // Sail 2 (Central prominent sail)
    final sail2 = Path()
      ..moveTo(base.dx - width * 0.25, base.dy - 6)
      ..cubicTo(
        base.dx - width * 0.10, base.dy - 56,
        base.dx + width * 0.18, base.dy - 50,
        base.dx + width * 0.22, base.dy - 6,
      )
      ..close();
    canvas.drawPath(sail2, sailFill);
    canvas.drawPath(sail2, sailBorder);

    // Sail 3 (Rightmost sail)
    final sail3 = Path()
      ..moveTo(base.dx + width * 0.05, base.dy - 6)
      ..cubicTo(
        base.dx + width * 0.20, base.dy - 40,
        base.dx + width * 0.45, base.dy - 34,
        base.dx + width * 0.50, base.dy - 6,
      )
      ..close();
    canvas.drawPath(sail3, sailFill);
    canvas.drawPath(sail3, sailBorder);
  }

  void _drawLittleBoat(Canvas canvas, Offset pos, bool isDark) {
    // Red Hull
    final hullPaint = Paint()..color = const Color(0xFFEF4444);
    final hullPath = Path()
      ..moveTo(pos.dx - 12, pos.dy)
      ..lineTo(pos.dx + 12, pos.dy)
      ..lineTo(pos.dx + 8, pos.dy + 4)
      ..lineTo(pos.dx - 8, pos.dy + 4)
      ..close();
    canvas.drawPath(hullPath, hullPaint);

    // Cabin
    final cabinPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(pos.dx - 4, pos.dy - 6, 8, 6), cabinPaint);

    // Mast
    final mastPaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF334155)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(pos.dx + 2, pos.dy - 12), Offset(pos.dx + 2, pos.dy), mastPaint);
  }

  void _drawStar(Canvas canvas, Offset pos, double size) {
    canvas.drawCircle(pos, size, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(pos, size * 2.2, Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _HeroWeatherIllustrationPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.isSunny != isSunny ||
        oldDelegate.isDay != isDay;
  }
}
