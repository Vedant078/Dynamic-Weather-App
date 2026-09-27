import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';

class WeatherExposureCard extends StatelessWidget {
  final double ambientTempC;
  final double relativeHumidity;
  final double windSpeedKmh;
  final double precipitationProb;
  final bool isHighHeat;

  const WeatherExposureCard({
    super.key,
    required this.ambientTempC,
    required this.relativeHumidity,
    required this.windSpeedKmh,
    required this.precipitationProb,
    this.isHighHeat = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MausamSpacing.standard),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(
          color: isHighHeat ? MausamColors.watch.withValues(alpha: 0.35) : MausamColors.brd(context),
        ),
        boxShadow: MausamSpacing.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Corridor weather exposure',
                style: MausamTypography.labelBoldOf(context).copyWith(
                  fontSize: 13,
                  color: MausamColors.txtPrimary(context),
                ),
              ),
              if (isHighHeat)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: MausamColors.watch.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                  ),
                  child: Text(
                    'Heat advisory',
                    style: MausamTypography.microOf(context).copyWith(
                      color: MausamColors.watch,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeatherItem(
                context,
                LucideIcons.thermometer,
                'Ambient',
                '${ambientTempC.toStringAsFixed(1)}°C',
                isAlert: ambientTempC > 38.0,
              ),
              _buildWeatherItem(
                context,
                LucideIcons.droplets,
                'Humidity',
                '${relativeHumidity.toInt()}%',
              ),
              _buildWeatherItem(
                context,
                LucideIcons.wind,
                'Wind',
                '${windSpeedKmh.toInt()} km/h',
              ),
              _buildWeatherItem(
                context,
                LucideIcons.cloudRain,
                'Rain prob.',
                '${precipitationProb.toInt()}%',
                isAlert: precipitationProb > 40.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherItem(BuildContext context, IconData icon, String label, String value, {bool isAlert = false}) {
    final color = isAlert ? MausamColors.highRisk : MausamColors.txtPrimary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: isAlert ? MausamColors.highRisk : MausamColors.info),
        const SizedBox(height: 4),
        Text(
          value,
          style: MausamTypography.tabularOf(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
