import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';

class FreshnessIndicator extends StatelessWidget {
  final DateTime lastUpdated;
  final bool isLive;

  const FreshnessIndicator({
    super.key,
    required this.lastUpdated,
    this.isLive = true,
  });

  @override
  Widget build(BuildContext context) {
    final diffSeconds = DateTime.now().difference(lastUpdated).inSeconds;
    final isStale = diffSeconds > 90;

    final dotColor = isStale ? MausamColors.watch : MausamColors.safe;
    final text = isStale ? 'STALE' : 'LIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
        border: Border.all(color: dotColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: MausamTypography.micro.copyWith(
              color: dotColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
