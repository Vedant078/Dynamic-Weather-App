import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/route_option.dart';
import 'status_pill.dart';

class RouteComparisonView extends StatelessWidget {
  final List<RouteOptionModel> routes;
  final String activeRouteId;
  final ValueChanged<String> onSelectRoute;

  const RouteComparisonView({
    super.key,
    required this.routes,
    required this.activeRouteId,
    required this.onSelectRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Candidate route comparison',
              style: MausamTypography.labelBoldOf(context).copyWith(
                fontSize: 13,
                color: MausamColors.txtPrimary(context),
              ),
            ),
            const StatusPill(
              label: 'WEATHER-WEIGHTED',
              color: MausamColors.info,
              icon: LucideIcons.cloudLightning,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...routes.map((route) {
          final isSelected = route.routeId == activeRouteId;
          final isRecommended = route.isRecommended;

          return Container(
            margin: const EdgeInsets.only(bottom: MausamSpacing.compact),
            padding: const EdgeInsets.all(MausamSpacing.standard),
            decoration: BoxDecoration(
              color: isSelected
                  ? (MausamColors.isDark(context) ? MausamColors.surfaceElevatedDark : Colors.white)
                  : MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
              border: Border.all(
                color: isSelected
                    ? MausamColors.info
                    : (isRecommended ? MausamColors.safe.withValues(alpha: 0.35) : MausamColors.brd(context)),
                width: isSelected || isRecommended ? 1.5 : 1.0,
              ),
              boxShadow: isSelected ? MausamSpacing.shadow(context) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        route.routeName,
                        style: MausamTypography.labelBoldOf(context).copyWith(
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (isRecommended)
                      const StatusPill(
                        label: 'RECOMMENDED',
                        color: MausamColors.safe,
                        icon: LucideIcons.check,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStat(context, 'ETA', '${route.etaMinutes.toInt()} min'),
                    const SizedBox(width: 16),
                    _buildStat(context, 'Distance', '${route.distanceKm} km'),
                    const SizedBox(width: 16),
                    _buildStat(
                      context,
                      'Delivery risk',
                      route.deliveryRisk.toInt().toString(),
                      color: route.deliveryRisk > 60 ? MausamColors.highRisk : MausamColors.safe,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  route.tradeOffExplanation,
                  style: MausamTypography.bodyOf(context).copyWith(
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                if (!isSelected)
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => onSelectRoute(route.routeId),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isRecommended ? MausamColors.safe : MausamColors.brd(context)),
                        foregroundColor: isRecommended ? MausamColors.safe : MausamColors.txtPrimary(context),
                      ),
                      child: Text(
                        isRecommended ? 'Apply recommended route' : 'Select this route',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 14, color: MausamColors.info),
                      const SizedBox(width: 5),
                      Text(
                        'Currently active route',
                        style: MausamTypography.microOf(context).copyWith(
                          color: MausamColors.info,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MausamTypography.microOf(context).copyWith(
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: MausamTypography.tabularOf(context).copyWith(
            fontSize: 14.5,
            color: color ?? MausamColors.txtPrimary(context),
          ),
        ),
      ],
    );
  }
}
