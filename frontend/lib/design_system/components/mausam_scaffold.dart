import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/persona.dart';
import 'mausam_header.dart';

class MausamScaffold extends StatelessWidget {
  final Widget body;
  final int currentNavIndex;
  final ValueChanged<int> onNavChanged;
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
  final Widget? floatingActionButton;

  const MausamScaffold({
    super.key,
    required this.body,
    required this.currentNavIndex,
    required this.onNavChanged,
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
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MausamColors.bg(context),
      body: Center(
        // Responsive operational workspace: expansive on desktop (1160px), adaptive on tablet (760px), natural on mobile
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width >= 960
                ? 1160
                : (MediaQuery.of(context).size.width >= 600 ? 760 : double.infinity),
          ),
          child: Column(
            children: [
              MausamHeader(
                currentPersona: currentPersona,
                allPersonas: allPersonas,
                onPersonaChanged: onPersonaChanged,
                lastUpdated: lastUpdated,
                atRiskCount: atRiskCount,
                onAlertsTap: onAlertsTap,
                onDemoTap: onDemoTap,
                onThemeToggle: onThemeToggle,
                isDarkMode: isDarkMode,
                simulationStep: simulationStep,
              ),
              Expanded(child: body),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton ??
          (onDemoTap != null
              ? FloatingActionButton.extended(
                  onPressed: onDemoTap,
                  backgroundColor: MausamColors.surf(context),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                    side: BorderSide(color: MausamColors.brd(context)),
                  ),
                  icon: const Icon(LucideIcons.playCircle, size: 14, color: MausamColors.info),
                  label: Text(
                    'Demo $simulationStep/4',
                    style: MausamTypography.labelBoldOf(context).copyWith(
                      color: MausamColors.txtPrimary(context),
                      fontSize: 11.5,
                    ),
                  ),
                )
              : null),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isRmc = currentPersona.id == 'rmc';

    return Container(
      decoration: BoxDecoration(
        color: MausamColors.surf(context),
        border: Border(
          top: BorderSide(color: MausamColors.brd(context), width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isRmc
                ? [
                    _buildNavItem(context, 0, LucideIcons.layoutDashboard, 'Overview'),
                    _buildNavItem(context, 1, LucideIcons.truck, 'Deliveries', badgeCount: atRiskCount),
                    _buildNavItem(context, 2, LucideIcons.navigation2, 'Routes'),
                    _buildNavItem(context, 3, LucideIcons.clipboardCheck, 'Outcome'),
                    _buildNavItem(context, 4, LucideIcons.barChart3, 'Analytics'),
                  ]
                : [
                    _buildNavItem(context, 0, LucideIcons.cloudSun, 'Weather'),
                    _buildNavItem(context, 1, LucideIcons.compass, 'Advisory'),
                    _buildNavItem(context, 2, LucideIcons.map, 'Radar'),
                    _buildNavItem(context, 3, LucideIcons.bell, 'Alerts'),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = currentNavIndex == index;
    final color = isSelected ? MausamColors.info : MausamColors.txtMuted(context);

    return Expanded(
      child: InkWell(
        onTap: () => onNavChanged(index),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 19, color: color),
                  if (badgeCount > 0 && index == 1)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: MausamColors.highRisk,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: MausamTypography.microOf(context).copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
