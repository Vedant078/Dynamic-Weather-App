import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/batch.dart';

class AlertItemData {
  final String title;
  final String description;
  final String timestamp;
  final RiskLevel severity;
  final IconData icon;

  const AlertItemData({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.severity,
    required this.icon,
  });
}

class AlertFeed extends StatelessWidget {
  final List<AlertItemData> alerts;

  const AlertFeed({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(color: MausamColors.brd(context)),
        boxShadow: MausamSpacing.shadow(context),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent alerts',
                style: MausamTypography.labelBoldOf(context).copyWith(
                  fontSize: 13,
                  color: MausamColors.txtPrimary(context),
                ),
              ),
              Text(
                '${alerts.length} active',
                style: MausamTypography.microOf(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.asMap().entries.map((entry) {
            final idx = entry.key;
            final alert = entry.value;

            Color accentColor;
            switch (alert.severity) {
              case RiskLevel.safe:
                accentColor = MausamColors.safe;
                break;
              case RiskLevel.watch:
                accentColor = MausamColors.watch;
                break;
              case RiskLevel.highRisk:
              case RiskLevel.critical:
                accentColor = MausamColors.highRisk;
                break;
            }

            final isLast = idx == alerts.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(alert.icon, size: 13, color: accentColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    style: MausamTypography.labelBoldOf(context).copyWith(
                                      fontSize: 12.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  alert.timestamp,
                                  style: MausamTypography.microOf(context).copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.description,
                              style: MausamTypography.bodyOf(context).copyWith(
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(height: 14, color: MausamColors.brdSubtle(context)),
              ],
            );
          }),
        ],
      ),
    );
  }
}
