import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/persona.dart';
import 'freshness_indicator.dart';

class MausamHeader extends StatelessWidget implements PreferredSizeWidget {
  final PersonaModel currentPersona;
  final List<PersonaModel> allPersonas;
  final ValueChanged<String> onPersonaChanged;
  final DateTime lastUpdated;
  final int atRiskCount;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onDemoTap;
  final VoidCallback? onThemeToggle;
  final bool isDarkMode;
  final int simulationStep;

  const MausamHeader({
    super.key,
    required this.currentPersona,
    required this.allPersonas,
    required this.onPersonaChanged,
    required this.lastUpdated,
    this.atRiskCount = 0,
    this.onAlertsTap,
    this.onDemoTap,
    this.onThemeToggle,
    this.isDarkMode = false,
    this.simulationStep = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        border: Border(
          bottom: BorderSide(
            color: MausamColors.brd(context),
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Clean Product Title & Operational Corridor Context
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MAUSAM',
                        style: MausamTypography.headingOf(context).copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      FreshnessIndicator(lastUpdated: lastUpdated),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ahmedabad Central Corridor',
                    style: MausamTypography.microOf(context).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Right: Clean Controls (Theme, Persona, Alerts) per Section 6
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme Toggle (Light / Dark)
                if (onThemeToggle != null) ...[
                  InkWell(
                    onTap: onThemeToggle,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: MausamColors.surfSecondary(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: MausamColors.brd(context)),
                      ),
                      child: Icon(
                        isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                        size: 14,
                        color: MausamColors.txtSecondary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Persona Switcher Pill
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: MausamColors.surfSecondary(context),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                    border: Border.all(color: MausamColors.brd(context)),
                  ),
                  child: PopupMenuButton<String>(
                    initialValue: currentPersona.id,
                    onSelected: onPersonaChanged,
                    color: MausamColors.surf(context),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                      side: BorderSide(color: MausamColors.brd(context)),
                    ),
                    itemBuilder: (ctx) {
                      return allPersonas.map((p) {
                        final isSel = p.id == currentPersona.id;
                        return PopupMenuItem<String>(
                          value: p.id,
                          child: Row(
                            children: [
                              Text(
                                p.name,
                                style: MausamTypography.labelOf(ctx).copyWith(
                                  color: isSel ? MausamColors.info : MausamColors.txtPrimary(ctx),
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              if (p.id == 'rmc') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: MausamColors.infoSubtle,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text('RMC', style: TextStyle(fontSize: 8.5, color: MausamColors.info, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentPersona.id == 'rmc' ? 'RMC' : currentPersona.name.split(' ').first,
                          style: MausamTypography.labelBoldOf(context).copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(LucideIcons.chevronDown, size: 11, color: MausamColors.txtSecondary(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Notification Bell with Urgent Attention Dot
                InkWell(
                  onTap: onAlertsTap,
                  borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: MausamColors.surfSecondary(context),
                      borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                      border: Border.all(color: MausamColors.brd(context)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(LucideIcons.bell, size: 15, color: MausamColors.txtSecondary(context)),
                        if (atRiskCount > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: MausamColors.highRisk,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
