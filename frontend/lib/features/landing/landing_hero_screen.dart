import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_icons.dart';
import '../../state/mausam_state.dart';
import 'components/hero_weather_card.dart';

/// Clean, reference-compliant Landing Hero Screen
/// Follows: design/references/landing_hero.md and design/skills.md
/// Communicates: Weather & Environmental Decision Intelligence for all operational contexts.
/// RMC Logistics is highlighted as the FLAGSHIP capability without dominating the entire platform identity.
/// Avoids: Generic AI gradients, glowing blobs, neon lines, excessive pills, cartoon art.
class LandingHeroScreen extends StatelessWidget {
  final MausamState state;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;
  final ValueChanged<String>? onSelectPersona;

  const LandingHeroScreen({
    super.key,
    required this.state,
    required this.onGetStarted,
    required this.onSignIn,
    this.onSelectPersona,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 860;

    // Atmospheric palette: refined sky to mist gradient in light mode; deep troposphere in dark mode
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F14), Color(0xFF111827), Color(0xFF0F172A)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F7FF), Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
          );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8FAFC),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Restrained Top Navigation Bar
              _buildTopNavigation(context, isDark, isWide),

              // 2. Main Scrollable Hero Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 36.0 : 20.0,
                    vertical: 12.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isWide ? 32 : 16),

                          // Hero Section (2 Columns on Desktop, Stacked on Mobile)
                          if (isWide)
                            _buildDesktopHero(context, isDark)
                          else
                            _buildMobileHero(context, isDark),

                          SizedBox(height: isWide ? 56 : 36),

                          // Multi-Context Editorial Showcase ("Built Around the Way You Use Weather")
                          _buildOperationalContextsSection(context, isDark),

                          const SizedBox(height: 48),

                          // Subtle Footer Brand Strip
                          _buildFooter(isDark),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context, bool isDark, bool isWide) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWide ? 32.0 : 16.0,
        vertical: 8.0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 22.0 : 14.0,
        vertical: 10.0,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161E27).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(
          color: isDark ? const Color(0xFF27323D) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Wordmark & Intelligence Identifier
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MAUSAM',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 1.5,
                  ),
                ),
                if (MediaQuery.of(context).size.width >= 480) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'INTELLIGENCE',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Center: Editorial Wayfinding Links (Desktop >= 920px)
          if (MediaQuery.of(context).size.width >= 920)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavText('Intelligence', isDark),
                const SizedBox(width: 24),
                _buildNavText('Operational Contexts', isDark),
                const SizedBox(width: 24),
                _buildNavText('Corridors', isDark),
              ],
            ),

          // Right: Sign In Button & Theme Toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: onSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                  foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 20 : 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: state.toggleTheme,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF27323D) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Icon(
                    state.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                    size: 14,
                    color: isDark ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDesktopHero(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Platform Value Headline & Single Action (54%)
        Expanded(
          flex: 54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeadline(isDark),
              const SizedBox(height: 32),
              _buildSingleExploreCta(context, isDark),
            ],
          ),
        ),
        const SizedBox(width: 44),

        // Right: Dynamic Reference-Compliant Current Weather Card (46%)
        Expanded(
          flex: 46,
          child: HeroWeatherCard(state: state, isDark: isDark),
        ),
      ],
    );
  }

  Widget _buildMobileHero(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeadline(isDark),
        const SizedBox(height: 24),
        _buildSingleExploreCta(context, isDark),
        const SizedBox(height: 32),
        HeroWeatherCard(state: state, isDark: isDark),
      ],
    );
  }

  Widget _buildHeadline(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform Signifier Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFFBAE6FD),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'ENVIRONMENTAL DECISION INTELLIGENCE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Platform-Level Declarative Headline
        Text(
          'Weather Intelligence\nfor Every Decision.',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF3F6F8) : const Color(0xFF0F172A),
            letterSpacing: -1.0,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 16),

        // Generalized Value Copy
        Text(
          'Transforming hyperlocal atmospheric conditions, microclimate radar, and environmental risk into actionable real-world decisions — across daily commutes, family safety, outdoor activity, and heavy industrial logistics.',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF9BA8B5) : const Color(0xFF475569),
            height: 1.55,
          ),
        ),
      ],
    );
  }

  /// Single Primary CTA: Explore Intelligence -> (Section 1)
  /// Removed redundant "Get Started" button as requested
  Widget _buildSingleExploreCta(BuildContext context, bool isDark) {
    final isWide = MediaQuery.of(context).size.width >= 860;
    return ElevatedButton(
      onPressed: onGetStarted,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999.0),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Explore Intelligence',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 16),
        ],
      ),
    );
  }

  Widget _buildOperationalContextsSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111820) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF27323D) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Kicker & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADAPTIVE PLATFORM CONTEXTS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Built Around the Way You Use Weather',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFF3F6F8) : const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '7 DOMAINS SUPPORTED',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Weather affects every decision differently. Mausam translates raw atmospheric observations into specific operational thresholds for each domain:',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? const Color(0xFF9BA8B5) : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // Responsive Context Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideGrid = constraints.maxWidth >= 720;
              final itemWidth = isWideGrid ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _ContextCard(
                    width: itemWidth,
                    icon: MausamIcons.personaHealth,
                    title: 'Health & Air Quality Safety',
                    description: 'Respiratory vulnerability alerts, particulate exposure tracking, and heat-stress advisories.',
                    isDark: isDark,
                  ),
                  _ContextCard(
                    width: itemWidth,
                    icon: Icons.alt_route_rounded,
                    title: 'Travelers & Highway Commuters',
                    description: 'Microclimate corridor delays, sudden rain bottlenecks, and highway waterlogging intelligence.',
                    isDark: isDark,
                  ),
                  _ContextCard(
                    width: itemWidth,
                    icon: MausamIcons.personaRmc,
                    title: 'Commercial & RMC Logistics',
                    description: 'Dynamic concrete slump kinetics, ambient hydration decay, and predictive retarder dosing.',
                    badge: 'FLAGSHIP ENGINE',
                    isDark: isDark,
                  ),
                  _ContextCard(
                    width: itemWidth,
                    icon: MausamIcons.personaFitness,
                    title: 'Outdoor Athletics & Fitness',
                    description: 'Safe training windows based on wet-bulb temperature, relative humidity, and solar UV index.',
                    isDark: isDark,
                  ),
                  _ContextCard(
                    width: itemWidth,
                    icon: MausamIcons.personaBeach,
                    title: 'Coastal & Marine Safety',
                    description: 'Tidal cycles, coastal squall detection, wave height telemetry, and marine recreation alerts.',
                    isDark: isDark,
                  ),
                  _ContextCard(
                    width: itemWidth,
                    icon: MausamIcons.personaAgriculture,
                    title: 'Agriculture & Cultivation',
                    description: 'Localized evapotranspiration, frost risk, soil microclimate moisture, and spraying timing.',
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'MAUSAM • Environmental Decision Intelligence Platform',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF667481) : const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'SIH Prototype',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF667481) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

/// Editorial context card for multi-persona platform representation
class _ContextCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final bool isDark;

  const _ContextCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E27) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF27323D) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF3F6F8) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9BA8B5) : const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

