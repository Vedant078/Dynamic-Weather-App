import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/persona.dart';
import '../../models/batch.dart';
import '../../design_system/components/telemetry_metric.dart';
import '../../design_system/components/status_pill.dart';
import '../../services/weather_service.dart';

class ConsumerWeatherScreen extends StatelessWidget {
  final PersonaModel persona;
  final WeatherService _weatherService = WeatherService();

  ConsumerWeatherScreen({super.key, required this.persona});

  @override
  Widget build(BuildContext context) {
    final canonical = _weatherService.getDeterministicWeather(
      location: 'Ahmedabad Central Corridor',
      timeOfDay: '14:00',
    );
    final h14 = _weatherService.getDeterministicWeather(location: 'Ahmedabad Central Corridor', timeOfDay: '14:00');
    final h15 = _weatherService.getDeterministicWeather(location: 'Ahmedabad Central Corridor', timeOfDay: '15:00');
    final h16 = _weatherService.getDeterministicWeather(location: 'Ahmedabad Central Corridor', timeOfDay: '16:00');
    final h17 = _weatherService.getDeterministicWeather(location: 'Ahmedabad Central Corridor', timeOfDay: '17:00');
    final h18 = _weatherService.getDeterministicWeather(location: 'Ahmedabad Central Corridor', timeOfDay: '18:00');
    final h19 = _weatherService.getDeterministicWeather(location: 'Ahmedabad Central Corridor', timeOfDay: '19:00');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persona Identity Banner
          Container(
            padding: const EdgeInsets.all(MausamSpacing.standard),
            decoration: BoxDecoration(
              color: MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
              border: Border.all(color: MausamColors.brd(context)),
              boxShadow: MausamSpacing.shadow(context),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: MausamColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                  ),
                  child: const Icon(LucideIcons.cloudSun, size: 22, color: MausamColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        persona.name,
                        style: MausamTypography.headingOf(context).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        persona.tagline,
                        style: MausamTypography.microOf(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // CURRENT CONDITIONS SUMMARY CARD
          Container(
            padding: const EdgeInsets.all(MausamSpacing.standard),
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
                      'Ahmedabad, Gujarat',
                      style: MausamTypography.labelBoldOf(context).copyWith(
                        fontSize: 13,
                        color: MausamColors.txtPrimary(context),
                      ),
                    ),
                    const StatusPill(label: 'LIVE WEATHER', color: MausamColors.safe),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${canonical.ambientTempC.toStringAsFixed(1)}°C',
                      style: MausamTypography.tabularOf(context).copyWith(fontSize: 34),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feels like ${canonical.apparentTempC.toStringAsFixed(1)}°C',
                      style: MausamTypography.bodyOf(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${canonical.weatherCondition} · Wind ${canonical.windSpeedKmh.toInt()} km/h ${canonical.windDirection} · Humidity ${canonical.humidityPct.toInt()}%',
                  style: MausamTypography.bodyOf(context).copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // PERSONA SPECIFIC METRICS
          Text(
            '${persona.name} intelligence metrics',
            style: MausamTypography.labelBoldOf(context).copyWith(
              fontSize: 12.5,
              color: MausamColors.txtPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          _buildPersonaSpecificGrid(persona.id),

          const SizedBox(height: 14),

          // HOURLY FORECAST SCROLL
          Container(
            padding: const EdgeInsets.all(MausamSpacing.standard),
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
                  '8-hour environmental outlook',
                  style: MausamTypography.labelBoldOf(context).copyWith(
                    fontSize: 13,
                    color: MausamColors.txtPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHourlyCard(context, '14:00', '${h14.ambientTempC.toInt()}°', '${h14.precipitationProbabilityPct.toInt()}%', h14.ambientTempC >= 38 ? RiskLevel.watch : RiskLevel.safe),
                      _buildHourlyCard(context, '15:00', '${h15.ambientTempC.toInt()}°', '${h15.precipitationProbabilityPct.toInt()}%', h15.ambientTempC >= 38 ? RiskLevel.watch : RiskLevel.safe),
                      _buildHourlyCard(context, '16:00', '${h16.ambientTempC.toInt()}°', '${h16.precipitationProbabilityPct.toInt()}%', h16.precipitationProbabilityPct >= 50 ? RiskLevel.highRisk : RiskLevel.watch),
                      _buildHourlyCard(context, '17:00', '${h17.ambientTempC.toInt()}°', '${h17.precipitationProbabilityPct.toInt()}%', RiskLevel.watch),
                      _buildHourlyCard(context, '18:00', '${h18.ambientTempC.toInt()}°', '${h18.precipitationProbabilityPct.toInt()}%', RiskLevel.safe),
                      _buildHourlyCard(context, '19:00', '${h19.ambientTempC.toInt()}°', '${h19.precipitationProbabilityPct.toInt()}%', RiskLevel.safe),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPersonaSpecificGrid(String id) {
    if (id == 'health') {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.wind,
                  label: 'Air Quality (AQI)',
                  value: '142',
                  delta: 'Moderate',
                  isWarning: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.sun,
                  label: 'UV Index',
                  value: '8.4',
                  delta: 'Very High',
                  isWarning: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.flower2,
                  label: 'Pollen Count',
                  value: '4.1',
                  unit: '/10',
                  delta: 'Low',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.flame,
                  label: 'Heat Strain Risk',
                  value: 'Elevated',
                  delta: '12pm - 4pm',
                  isWarning: true,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (id == 'fitness') {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.timer,
                  label: 'Best Running Window',
                  value: '05:30 - 07:45',
                  delta: 'Coolest',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.thermometer,
                  label: 'Midday Heat Alert',
                  value: 'Caution',
                  delta: '>38°C Peak',
                  isWarning: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.wind,
                  label: 'Headwind Speed',
                  value: '16.2',
                  unit: 'km/h',
                  delta: 'Moderate',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.cloudRain,
                  label: 'Rain Probability',
                  value: '20',
                  unit: '%',
                  delta: 'Dry window',
                ),
              ),
            ],
          ),
        ],
      );
    } else if (id == 'beach') {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.waves,
                  label: 'Tide Schedule',
                  value: 'High 15:42',
                  delta: 'Rising',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.activity,
                  label: 'Wave Swell Height',
                  value: '1.4',
                  unit: 'm',
                  delta: 'Gentle',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.droplet,
                  label: 'Water Temperature',
                  value: '28.5',
                  unit: '°C',
                  delta: 'Warm',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.compass,
                  label: 'Offshore Rip Current',
                  value: 'Low',
                  delta: 'Safe bathing',
                ),
              ),
            ],
          ),
        ],
      );
    } else if (id == 'agriculture') {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.sprout,
                  label: 'Soil Moisture (10cm)',
                  value: '22',
                  unit: '%',
                  delta: 'Irrigation req.',
                  isWarning: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.snowflake,
                  label: 'Frost Probability',
                  value: '0',
                  unit: '%',
                  delta: 'Zero risk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.cloudRain,
                  label: 'Rainfall Forecast',
                  value: '2.5',
                  unit: 'mm',
                  delta: 'Light squall',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.sun,
                  label: 'Evapotranspiration',
                  value: '5.8',
                  unit: 'mm/day',
                  delta: 'High drying',
                ),
              ),
            ],
          ),
        ],
      );
    } else if (id == 'traveler') {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.navigation,
                  label: 'Corridor Visibility',
                  value: '9.2',
                  unit: 'km',
                  delta: 'Clear highway',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.clock,
                  label: 'Highway Delay Risk',
                  value: '+0',
                  unit: 'min',
                  delta: 'On schedule',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.car,
                  label: 'Wet Road / Traction',
                  value: 'Dry',
                  delta: 'Safe braking',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.plane,
                  label: 'Airport Weather Impact',
                  value: 'Normal',
                  delta: 'No delays logged',
                ),
              ),
            ],
          ),
        ],
      );
    } else if (id == 'family') {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.shieldCheck,
                  label: 'School Commute Safety',
                  value: 'Safe',
                  delta: 'Clear 07:30 - 08:45',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.sun,
                  label: 'Outdoor Play Window',
                  value: 'Caution',
                  delta: 'UV peak 14:00 - 16:30',
                  isWarning: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.umbrella,
                  label: 'Rain Advisory',
                  value: '0',
                  unit: '%',
                  delta: 'No umbrella required',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.wind,
                  label: 'Evening Air Quality',
                  value: '68',
                  unit: 'AQI',
                  delta: 'Good for park visit',
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.compass,
                  label: 'Regional Conditions',
                  value: 'Optimal',
                  delta: 'Stable climate',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TelemetryMetric(
                  icon: LucideIcons.clock,
                  label: 'Forecast Freshness',
                  value: 'Live',
                  delta: 'Updated 2m ago',
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildHourlyCard(BuildContext context, String hour, String temp, String rainProb, RiskLevel risk) {
    Color riskColor = MausamColors.safe;
    if (risk == RiskLevel.watch) riskColor = MausamColors.watch;
    if (risk == RiskLevel.highRisk) riskColor = MausamColors.highRisk;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MausamColors.surfSecondary(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        border: Border.all(color: MausamColors.brdSubtle(context)),
      ),
      child: Column(
        children: [
          Text(hour, style: MausamTypography.microOf(context)),
          const SizedBox(height: 4),
          Icon(
            risk == RiskLevel.highRisk ? LucideIcons.cloudRain : LucideIcons.sun,
            size: 16,
            color: riskColor,
          ),
          const SizedBox(height: 4),
          Text(temp, style: MausamTypography.tabularOf(context).copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            rainProb,
            style: MausamTypography.microOf(context).copyWith(
              color: risk == RiskLevel.highRisk ? MausamColors.highRisk : MausamColors.txtSecondary(context),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
