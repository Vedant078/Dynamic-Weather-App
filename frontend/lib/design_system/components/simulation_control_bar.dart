import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';

class SimulationControlBar extends StatelessWidget {
  final int currentStep;
  final String narrative;
  final ValueChanged<int> onStepSelected;
  final VoidCallback onReset;

  const SimulationControlBar({
    super.key,
    required this.currentStep,
    required this.narrative,
    required this.onStepSelected,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    const stepLabels = ['0: Nominal', '1: Traffic', '2: High Risk', '3: Route B', '4: Site'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MausamColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
        border: Border.all(color: MausamColors.info.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: MausamColors.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'DEMO SIMULATION ENGINE',
                        style: MausamTypography.micro.copyWith(
                          color: MausamColors.info,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onReset,
                child: Row(
                  children: [
                    const Icon(LucideIcons.rotateCcw, size: 11, color: MausamColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Reset',
                      style: MausamTypography.micro.copyWith(
                        color: MausamColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Step Selection Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(5, (index) {
                final isSelected = index == currentStep;
                Color stepColor = MausamColors.info;
                if (index == 2) stepColor = MausamColors.highRisk;
                if (index == 1) stepColor = MausamColors.watch;
                if (index == 3 || index == 4) stepColor = MausamColors.safe;

                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () => onStepSelected(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? stepColor.withValues(alpha: 0.2) : MausamColors.surface,
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                        border: Border.all(
                          color: isSelected ? stepColor : MausamColors.borderSubtle,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        stepLabels[index],
                        style: MausamTypography.micro.copyWith(
                          color: isSelected ? stepColor : MausamColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          // Narrative status banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: MausamColors.surface,
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
            ),
            child: Text(
              narrative,
              style: MausamTypography.micro.copyWith(
                color: MausamColors.textPrimary,
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
