import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../core/theme/mausam_icons.dart';
import '../../core/theme/mausam_motif.dart';
import '../../models/persona.dart';

/// Workspace & Persona Selection Screen (design/skills.md & prompt Section 19)
/// Allows user to choose their environmental intelligence domain with RMC Logistics
/// as the flagship core operational engine.
class PersonaSelectionScreen extends StatelessWidget {
  final List<PersonaModel> personas;
  final ValueChanged<String> onSelectPersona;
  final VoidCallback? onBack;

  const PersonaSelectionScreen({
    super.key,
    required this.personas,
    required this.onSelectPersona,
    this.onBack,
  });

  IconData _getPersonaIcon(String id) {
    switch (id) {
      case 'rmc':
        return MausamIcons.personaRmc;
      case 'health':
        return MausamIcons.personaHealth;
      case 'fitness':
        return MausamIcons.personaFitness;
      case 'beach':
        return MausamIcons.personaBeach;
      case 'traveler':
        return MausamIcons.personaTraveler;
      case 'family':
        return MausamIcons.personaFamily;
      case 'agriculture':
        return MausamIcons.personaAgriculture;
      default:
        return MausamIcons.weather;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rmcPersona = personas.firstWhere((p) => p.id == 'rmc', orElse: () => personas.first);
    final consumerPersonas = personas.where((p) => p.id != 'rmc').toList();
    final isDark = MausamColors.isDark(context);

    return Scaffold(
      backgroundColor: MausamColors.bg(context),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (onBack != null)
                        InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                const Icon(MausamIcons.back, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: MausamTypography.bodyMediumOf(context).copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      Row(
                        children: [
                          Text(
                            'MAUSAM',
                            style: MausamTypography.brandOf(context).copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Headline & Context
                  Text(
                    'Select intelligence workspace',
                    style: MausamTypography.headlineOf(context).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose the operational domain tailored to your environmental exposure.',
                    style: MausamTypography.bodyOf(context).copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // PRIMARY RMC FLAGSHIP EXPERIENCE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Primary operational engine',
                          style: MausamTypography.labelBoldOf(context).copyWith(
                            color: MausamColors.atmospherePrimary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MausamColors.atmospherePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(MausamSpacing.radiusPills),
                        ),
                        child: Text(
                          'FLAGSHIP',
                          style: MausamTypography.microOf(context).copyWith(
                            color: MausamColors.atmospherePrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // RMC Card with subtle isobar visual motif
                  InkWell(
                    onTap: () => onSelectPersona('rmc'),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusLargeSurfaces),
                    child: Container(
                      decoration: BoxDecoration(
                        color: MausamColors.surf(context),
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusLargeSurfaces),
                        border: Border.all(
                          color: MausamColors.atmospherePrimary.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        boxShadow: MausamSpacing.shadow(context),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusLargeSurfaces),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: MausamAtmosphericMotif(
                                height: 160,
                                opacity: isDark ? 0.08 : 0.05,
                                showWaypoints: true,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(MausamSpacing.standard),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: MausamColors.atmospherePrimary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                                        ),
                                        child: const Icon(
                                          MausamIcons.truck,
                                          size: 20,
                                          color: MausamColors.atmospherePrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rmcPersona.name,
                                              style: MausamTypography.titleOf(context).copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              rmcPersona.tagline,
                                              style: MausamTypography.microOf(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    rmcPersona.description,
                                    style: MausamTypography.bodySmallOf(context).copyWith(fontSize: 12.5),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: rmcPersona.primaryMetrics.map((m) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: MausamColors.surfSecondary(context),
                                          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                                          border: Border.all(color: MausamColors.brdSubtle(context)),
                                        ),
                                        child: Text(
                                          m,
                                          style: MausamTypography.microOf(context).copyWith(
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      onPressed: () => onSelectPersona('rmc'),
                                      icon: const Icon(MausamIcons.next, size: 15),
                                      label: const Text('Launch RMC Command Center'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MausamColors.atmospherePrimary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECONDARY CONSUMER PERSONAS
                  Text(
                    'Multi-persona environmental profiles',
                    style: MausamTypography.labelBoldOf(context).copyWith(
                      color: MausamColors.txtSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...consumerPersonas.map((persona) {
                    final icon = _getPersonaIcon(persona.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: MausamColors.surf(context),
                        borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
                        border: Border.all(color: MausamColors.brd(context)),
                        boxShadow: MausamSpacing.shadow(context),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () => onSelectPersona(persona.id),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: MausamColors.surfSecondary(context),
                              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                            ),
                            child: Icon(icon, size: 16, color: MausamColors.txtPrimary(context)),
                          ),
                          title: Text(
                            persona.name,
                            style: MausamTypography.labelBoldOf(context).copyWith(fontSize: 13),
                          ),
                          subtitle: Text(
                            persona.tagline,
                            style: MausamTypography.microOf(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            MausamIcons.chevronRight,
                            size: 14,
                            color: MausamColors.borderBrightLight,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
