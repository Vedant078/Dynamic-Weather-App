import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';

class SimulationSheet extends StatelessWidget {
  final int currentStep;
  final String narrative;
  final ValueChanged<int> onStepSelected;
  final VoidCallback onReset;

  const SimulationSheet({
    super.key,
    required this.currentStep,
    required this.narrative,
    required this.onStepSelected,
    required this.onReset,
  });

  static void show(
    BuildContext context, {
    required int currentStep,
    required String narrative,
    required ValueChanged<int> onStepSelected,
    required VoidCallback onReset,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SimulationSheet(
        currentStep: currentStep,
        narrative: narrative,
        onStepSelected: (s) {
          onStepSelected(s);
          Navigator.pop(ctx);
        },
        onReset: () {
          onReset();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      {'num': 0, 'title': 'Nominal Transit', 'desc': 'Route A moving normally, safe slump'},
      {'num': 1, 'title': 'Traffic Delay', 'desc': 'Nana Chiloda bottleneck building'},
      {'num': 2, 'title': 'Risk Escalation', 'desc': 'Heat + rain surge; transit > 78m limit'},
      {'num': 3, 'title': 'Route B Reroute', 'desc': 'Airport Bypass applied; risk mitigated'},
      {'num': 4, 'title': 'Site Arrival', 'desc': 'Delivery verified, ₹1.68L loss avoided'},
    ];

    final isDark = MausamColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MausamSpacing.radiusBottomSheets),
        ),
        boxShadow: MausamSpacing.shadow(context),
        border: Border.all(color: MausamColors.brd(context)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: MausamColors.brd(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: MausamColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                      ),
                      child: const Icon(LucideIcons.playCircle, size: 16, color: MausamColors.info),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demo Simulation Scenarios',
                          style: MausamTypography.headingOf(context).copyWith(fontSize: 16),
                        ),
                        Text(
                          'SIH Presentation & State Machine Controller',
                          style: MausamTypography.microOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(LucideIcons.rotateCcw, size: 13),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: MausamColors.txtSecondary(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Narrative Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? MausamColors.surfaceSecondaryDark : MausamColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                border: Border.all(color: MausamColors.brdSubtle(context)),
              ),
              child: Text(
                narrative,
                style: MausamTypography.bodyOf(context).copyWith(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scenario step cards
            Text(
              'Select Scenario Step',
              style: MausamTypography.microOf(context).copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            ...steps.map((st) {
              final stepNum = st['num'] as int;
              final isCurrent = stepNum == currentStep;
              Color accentColor = MausamColors.info;
              if (stepNum == 1) accentColor = MausamColors.watch;
              if (stepNum == 2) accentColor = MausamColors.highRisk;
              if (stepNum == 3 || stepNum == 4) accentColor = MausamColors.safe;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: InkWell(
                  onTap: () => onStepSelected(stepNum),
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? accentColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                      border: Border.all(
                        color: isCurrent ? accentColor : MausamColors.brdSubtle(context),
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCurrent ? accentColor : MausamColors.surfSecondary(context),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$stepNum',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : MausamColors.txtSecondary(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                st['title'] as String,
                                style: MausamTypography.labelBoldOf(context).copyWith(
                                  color: isCurrent ? accentColor : MausamColors.txtPrimary(context),
                                ),
                              ),
                              Text(
                                st['desc'] as String,
                                style: MausamTypography.microOf(context),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Icon(LucideIcons.check, size: 16, color: accentColor),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
