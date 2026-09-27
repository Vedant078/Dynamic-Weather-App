import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_icons.dart';
import '../../models/persona.dart';
import '../../models/workspace_definition.dart';

/// Dedicated RBAC Role Selection Screen (PRD.md Section 4 & Corrective Rework)
/// Separates AUTHENTICATION from RBAC ROLE from PERSONA EXPERIENCE.
/// Answers: "How are you using Mausam? / What authorized role are you entering?"
class RbacRoleSelectionScreen extends StatelessWidget {
  final List<PersonaModel> personas;
  final ValueChanged<String> onSelectRole;
  final VoidCallback onSignOut;
  final String? userEmail;
  final String? userName;
  final List<String>? authorizedRoleIds;
  final WorkspaceOperationalSummary? operationalSummary;

  const RbacRoleSelectionScreen({
    super.key,
    required this.personas,
    required this.onSelectRole,
    required this.onSignOut,
    this.userEmail,
    this.userName,
    this.authorizedRoleIds,
    this.operationalSummary,
  });

  IconData _getRoleIcon(String id) {
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

  String _getKeyCapability(String id) {
    switch (id) {
      case 'health':
        return 'AQI • Heat • Pollen';
      case 'fitness':
        return 'Best Running Hours • Heat Alerts • Wind';
      case 'beach':
        return 'Tide • Wave Height • Water Temp';
      case 'traveler':
        return 'Corridor Weather • Travel Alerts • Traction';
      case 'family':
        return 'School Commute • Rain Advisory • Family Safety';
      case 'agriculture':
        return 'Soil Moisture • Frost • Crop Guidance';
      default:
        return 'Environmental Intelligence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);
    final isWide = MediaQuery.of(context).size.width >= 768;

    // Check authorization: if authorizedRoleIds specified, verify role access
    bool isAuthorized(String roleId) {
      if (authorizedRoleIds == null || authorizedRoleIds!.isEmpty) return true;
      final lower = roleId.toLowerCase();
      return authorizedRoleIds!.any((a) {
        final al = a.toLowerCase();
        if (al == lower) return true;
        if ((al == 'rmc' || al == 'rmc_logistics_manager') && (lower == 'rmc' || lower == 'rmc_logistics_manager')) {
          return true;
        }
        return false;
      });
    }

    // Flagship: RMC
    final rmcRole = personas.firstWhere((p) => p.id == 'rmc', orElse: () => personas.first);
    final hasRmcAuth = isAuthorized('rmc');

    // Other Workspaces: All 6 non-RMC personas are ALWAYS discoverable
    final otherWorkspaces = personas.where((p) => p.id != 'rmc').toList();

    final bgColor = isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF111820) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27323D) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF3F6F8) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF9BA8B5) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Identity Bar
            _buildTopBar(context, isDark, borderColor, textColor, textMuted),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32.0 : 20.0,
                  vertical: 24.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section with welcome context
                        _buildHeader(textColor, textMuted),
                        const SizedBox(height: 20),

                        // Section 1: Flagship Operational Workspace (RMC)
                        _buildFlagshipRoleCard(
                          context,
                          rmcRole,
                          isDark,
                          surfaceColor,
                          borderColor,
                          textColor,
                          textMuted,
                          isWide,
                          hasRmcAuth,
                        ),
                        const SizedBox(height: 32),

                        // Section 2: Explore Other Workspaces (All 6 PRD Personas)
                        Row(
                          children: [
                            Text(
                              'EXPLORE OTHER WORKSPACES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: textMuted,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Divider(color: borderColor, height: 1)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Other Workspaces Grid (3-columns desktop, 1-column mobile)
                        _buildWorkspacesGrid(
                          context,
                          otherWorkspaces,
                          isDark,
                          surfaceColor,
                          borderColor,
                          textColor,
                          textMuted,
                          isWide,
                          isAuthorized,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    bool isDark,
    Color borderColor,
    Color textColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111820) : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Mark
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MAUSAM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C2631) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    'RBAC',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: User Identity & Sign Out
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (userEmail != null && MediaQuery.of(context).size.width >= 600) ...[
                  Flexible(
                    child: Text(
                      userEmail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                InkWell(
                  onTap: onSignOut,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, size: 14, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color textMuted) {
    final displayName = userName != null && userName!.trim().isNotEmpty
        ? userName!.trim().split(' ').first
        : (userEmail != null && userEmail!.contains('@') ? userEmail!.split('@').first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayName != null) ...[
          Text(
            'Welcome, $displayName',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          'How are you using Mausam?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select your authorized workspace. Mausam adapts environmental intelligence and decision support to your workflow.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildFlagshipRoleCard(
    BuildContext context,
    PersonaModel rmcRole,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color textMuted,
    bool isWide,
    bool isAuthorized,
  ) {
    final activeCount = operationalSummary?.activeDeliveries ?? 0;
    final hasLiveTelemetry = operationalSummary?.hasLiveTelemetry ?? false;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF0284C7).withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flagship Banner Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.1),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  const Text(
                    'FLAGSHIP OPERATIONAL WORKSPACE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0284C7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  // Section 13: Only show LIVE TELEMETRY ACTIVE if genuinely supported by real active deliveries
                  if (hasLiveTelemetry) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
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
                          const SizedBox(width: 5),
                          const Text(
                            'LIVE TELEMETRY ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Card Body (Proportionate ~1/3 page height)
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Identity, Description & 3 Concise Capabilities
                        Expanded(
                          flex: 6,
                          child: _buildFlagshipDetails(rmcRole, textColor, textMuted),
                        ),
                        const SizedBox(width: 28),
                        // Right: Dynamic Scoped Operational Summary & Enter Action
                        Expanded(
                          flex: 4,
                          child: _buildFlagshipAction(context, rmcRole, isDark, textColor, textMuted, activeCount),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFlagshipDetails(rmcRole, textColor, textMuted),
                        const SizedBox(height: 18),
                        _buildFlagshipAction(context, rmcRole, isDark, textColor, textMuted, activeCount),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagshipDetails(
    PersonaModel rmcRole,
    Color textColor,
    Color textMuted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(MausamIcons.personaRmc, size: 22, color: Color(0xFF0284C7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RMC Logistics Manager',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ready-Mix Concrete Operations & Transit Loss Prevention',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Monitor transit conditions, concrete quality risk, hydration kinetics, and dynamic delivery routing decisions.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // Key Capabilities Badges (Section 11: 3 Concise Capabilities)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildCapabilityPill('Dynamic Slump Risk', const Color(0xFF0284C7)),
            _buildCapabilityPill('Route Intelligence', const Color(0xFF059669)),
            _buildCapabilityPill('Transit Loss Prevention', const Color(0xFF6366F1)),
          ],
        ),
      ],
    );
  }

  Widget _buildFlagshipAction(
    BuildContext context,
    PersonaModel rmcRole,
    bool isDark,
    Color textColor,
    Color textMuted,
    int activeCount,
  ) {
    final attentionCount = operationalSummary?.attentionCount ?? 0;
    final hasActive = activeCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E27) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF27323D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OPERATIONAL STATUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: hasActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Real Data Scoped Status (Section 2, 7 & 23: NO fake Batch RMC-204, NO fake ETA)
          if (hasActive) ...[
            Text(
              '$activeCount active ${activeCount == 1 ? 'delivery' : 'deliveries'}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              attentionCount > 0
                  ? '$attentionCount requires attention'
                  : 'All transits within safe tolerance',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: attentionCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
              ),
            ),
          ] else ...[
            Text(
              'No active deliveries',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Create and monitor your first RMC delivery.',
              style: TextStyle(
                fontSize: 11.5,
                color: textMuted,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Primary Launch Action
          ElevatedButton(
            onPressed: () => onSelectRole('rmc'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Launch RMC Command Center',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildWorkspacesGrid(
    BuildContext context,
    List<PersonaModel> otherWorkspaces,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color textMuted,
    bool isWide,
    bool Function(String) isAuthorized,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isWide ? 3 : 1;
        const spacing = 14.0;
        final totalWidth = constraints.maxWidth;
        final cardWidth = (totalWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: otherWorkspaces.map((role) {
            final authorized = isAuthorized(role.id);
            return SizedBox(
              width: cardWidth,
              child: _buildWorkspaceCard(
                context,
                role,
                isDark,
                surfaceColor,
                borderColor,
                textColor,
                textMuted,
                authorized,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWorkspaceCard(
    BuildContext context,
    PersonaModel role,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color textMuted,
    bool isAuthorized,
  ) {
    final keyCap = _getKeyCapability(role.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectRole(role.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C2631) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRoleIcon(role.id),
                      size: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      role.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // One-line Tagline / Description
              Text(
                role.tagline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // Key Capability Pill + Enter Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        keyCap,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 15, color: textMuted),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
