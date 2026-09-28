import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';
import '../../core/theme/mausam_icons.dart';
import '../../core/theme/mausam_spacing.dart';
import '../../core/theme/mausam_typography.dart';
import '../../models/area.dart';
import '../../services/area_service.dart';

/// Searchable Hierarchical Area Dropdown Component (Section 1, 2, 3, 4, 14, 15)
/// Implements two-level selection (STATE -> CITY -> AREA/LOCALITY) and direct search.
/// On desktop: renders an elevated, centered modal dialog.
/// On mobile: renders a responsive bottom sheet.
/// Options are strictly sorted in alphabetical order at every level.
/// Real coordinates are kept in the data layer and resolved to exact leaf positions.
class SearchableAreaDropdown extends StatelessWidget {
  final String label;
  final String? pickerTitle;
  final String hint;
  final Area? selectedArea;
  final ValueChanged<Area?> onChanged;
  final IconData? icon;
  final List<Area>? availableAreas;
  final bool isRequired;

  const SearchableAreaDropdown({
    super.key,
    required this.label,
    this.pickerTitle,
    required this.hint,
    required this.selectedArea,
    required this.onChanged,
    this.icon,
    this.availableAreas,
    this.isRequired = false,
  });

  String get _resolvedTitle {
    if (pickerTitle != null && pickerTitle!.isNotEmpty) {
      return pickerTitle!;
    }
    final upper = label.toUpperCase();
    if (upper.contains('ORIGIN') || upper.contains('PLANT')) {
      return 'Select Origin Area';
    }
    if (upper.contains('DEST') || upper.contains('PROJECT') || upper.contains('SITE')) {
      return 'Select Destination Area';
    }
    return 'Select Location Area';
  }

  void _showAreaPicker(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final title = _resolvedTitle;
    final areas = availableAreas ?? AreaService.getAvailableAreas();

    if (isDesktop) {
      showDialog<Area>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 580,
              ),
              child: _AreaPickerContent(
                title: title,
                hint: hint,
                selectedArea: selectedArea,
                areas: areas,
                isDialog: true,
                onSelected: (area) {
                  Navigator.of(ctx).pop(area);
                  onChanged(area);
                },
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet<Area>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            child: _AreaPickerContent(
              title: title,
              hint: hint,
              selectedArea: selectedArea,
              areas: areas,
              isDialog: false,
              onSelected: (area) {
                Navigator.of(ctx).pop(area);
                onChanged(area);
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);
    final hasSelection = selectedArea != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: Key('searchable_dropdown_label_$label'),
          onTap: () => _showAreaPicker(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: MausamTypography.microOf(context).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: MausamColors.txtSecondary(context),
                    ),
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      color: MausamColors.highRisk,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          key: Key('searchable_dropdown_field_$label'),
          onTap: () => _showAreaPicker(context),
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141D26) : Colors.white,
              borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
              border: Border.all(
                color: hasSelection
                    ? MausamColors.accent.withValues(alpha: 0.5)
                    : MausamColors.brd(context),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon ?? (hasSelection && selectedArea!.isLocality ? MausamIcons.mapPin : MausamIcons.plant),
                  size: 16,
                  color: hasSelection ? MausamColors.accent : MausamColors.txtMuted(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasSelection ? selectedArea!.qualifiedName : hint,
                    style: MausamTypography.bodyMediumOf(context).copyWith(
                      fontSize: 13.5,
                      fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w400,
                      color: hasSelection
                          ? MausamColors.txtPrimary(context)
                          : MausamColors.txtMuted(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSelection)
                  InkWell(
                    key: Key('clear_selection_$label'),
                    onTap: () => onChanged(null),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        MausamIcons.close,
                        size: 14,
                        color: MausamColors.txtMuted(context),
                      ),
                    ),
                  )
                else
                  Icon(
                    MausamIcons.chevronDown,
                    size: 16,
                    color: MausamColors.txtMuted(context),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AreaPickerContent extends StatefulWidget {
  final String title;
  final String hint;
  final Area? selectedArea;
  final List<Area> areas;
  final bool isDialog;
  final ValueChanged<Area> onSelected;

  const _AreaPickerContent({
    required this.title,
    required this.hint,
    required this.selectedArea,
    required this.areas,
    required this.isDialog,
    required this.onSelected,
  });

  @override
  State<_AreaPickerContent> createState() => _AreaPickerContentState();
}

class _AreaPickerContentState extends State<_AreaPickerContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  Area? _drilledCity;
  late List<Area> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = [];
    // If an area was already selected, pre-drill to its parent city for easy context
    if (widget.selectedArea != null && widget.selectedArea!.parentLocationId != null) {
      _drilledCity = AreaService.getAreaById(widget.selectedArea!.parentLocationId!);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = AreaService.searchAreas(clean);
      }
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'CITY':
        return MausamIcons.plant;
      case 'INDUSTRIAL_AREA':
        return MausamIcons.plant;
      case 'BUSINESS_DISTRICT':
        return MausamIcons.trendUp;
      case 'PROJECT_AREA':
        return MausamIcons.project;
      case 'LOCALITY':
      default:
        return MausamIcons.mapPin;
    }
  }

  Color _getBadgeColor(BuildContext context, String type) {
    final isDark = MausamColors.isDark(context);
    switch (type.toUpperCase()) {
      case 'CITY':
        return MausamColors.accent;
      case 'INDUSTRIAL_AREA':
        return Colors.orangeAccent;
      case 'BUSINESS_DISTRICT':
        return Colors.tealAccent.shade400;
      case 'PROJECT_AREA':
        return Colors.purpleAccent;
      case 'LOCALITY':
      default:
        return isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);
    final isSearching = _searchCtrl.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141D26) : Colors.white,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(16)
            : const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: MausamColors.brd(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle (Mobile bottom sheet only)
            if (!widget.isDialog)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                    color: MausamColors.brd(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // Header (Section 1, 2, 14)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
              child: Row(
                children: [
                  if (!isSearching && _drilledCity != null)
                    IconButton(
                      key: const Key('back_to_cities_button'),
                      icon: const Icon(MausamIcons.back, size: 18),
                      tooltip: 'Back to all cities',
                      padding: const EdgeInsets.only(right: 8),
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _drilledCity = null),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSearching
                              ? 'Search Locations'
                              : (_drilledCity != null
                                  ? 'Select Area in ${_drilledCity!.name}'
                                  : widget.title),
                          overflow: TextOverflow.ellipsis,
                          style: MausamTypography.labelBoldOf(context).copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: MausamColors.txtPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSearching
                              ? 'Cities and operational localities matching search'
                              : (_drilledCity != null
                                  ? 'Alphabetically sorted localities in ${_drilledCity!.name}'
                                  : 'Select city to view localities, or search directly'),
                          overflow: TextOverflow.ellipsis,
                          style: MausamTypography.microOf(context).copyWith(
                            color: MausamColors.txtSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('area_picker_close'),
                    icon: const Icon(MausamIcons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Search Field (Section 3 & 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('area_search_input'),
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _onSearch,
                style: MausamTypography.bodyMediumOf(context).copyWith(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search city or locality (e.g. Naroda, Bopal, Surat)...',
                  hintStyle: MausamTypography.bodyMediumOf(context).copyWith(
                    color: MausamColors.txtMuted(context),
                    fontSize: 13.0,
                  ),
                  prefixIcon: const Icon(MausamIcons.search, size: 16),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(MausamIcons.close, size: 14),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                    borderSide: BorderSide(color: MausamColors.brd(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                    borderSide: BorderSide(color: MausamColors.brd(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                    borderSide: const BorderSide(color: MausamColors.accent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 1, color: MausamColors.brdSubtle(context)),

            // Body: Search Results OR Hierarchical Navigation
            Flexible(
              child: isSearching
                  ? _buildSearchResults(context, isDark)
                  : (_drilledCity != null
                      ? _buildLocalitiesList(context, isDark, _drilledCity!)
                      : _buildCitiesList(context, isDark)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. DIRECT SEARCH RESULTS
  // ---------------------------------------------------------------------------
  Widget _buildSearchResults(BuildContext context, bool isDark) {
    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MausamIcons.mapPin, size: 28, color: MausamColors.txtMuted(context)),
            const SizedBox(height: 8),
            Text(
              'No matching locations found',
              style: MausamTypography.labelBoldOf(context).copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching for Naroda, Bopal, SG Highway, Infocity, Surat...',
              style: MausamTypography.microOf(context).copyWith(
                color: MausamColors.txtSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _searchResults.length,
      separatorBuilder: (context, _) => Divider(
        height: 1,
        indent: 52,
        color: MausamColors.brdSubtle(context),
      ),
      itemBuilder: (context, index) {
        final area = _searchResults[index];
        final isSelected = widget.selectedArea?.id == area.id ||
            (widget.selectedArea?.name.toLowerCase() == area.name.toLowerCase() &&
                widget.selectedArea?.city.toLowerCase() == area.city.toLowerCase());

        return _buildAreaTile(
          context: context,
          isDark: isDark,
          area: area,
          isSelected: isSelected,
          showParentCity: !area.isCity,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. LEVEL 1: CITIES LIST (Strictly Sorted Alphabetically)
  // ---------------------------------------------------------------------------
  Widget _buildCitiesList(BuildContext context, bool isDark) {
    final cities = AreaService.getCities();

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: cities.length,
      separatorBuilder: (context, _) => Divider(
        height: 1,
        indent: 52,
        color: MausamColors.brdSubtle(context),
      ),
      itemBuilder: (context, index) {
        final city = cities[index];
        final localities = AreaService.getLocalitiesForCity(city.name);
        final isSelected = widget.selectedArea?.id == city.id ||
            (widget.selectedArea?.city.toLowerCase() == city.name.toLowerCase() && widget.selectedArea?.isCity == true);

        return ListTile(
          key: Key('city_item_${city.id}'),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? MausamColors.accent.withValues(alpha: 0.15)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            ),
            child: Icon(
              MausamIcons.plant,
              size: 16,
              color: isSelected ? MausamColors.accent : MausamColors.txtSecondary(context),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  city.name,
                  style: MausamTypography.bodyMediumOf(context).copyWith(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? MausamColors.accent : MausamColors.txtPrimary(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${localities.length} areas',
                  style: MausamTypography.microOf(context).copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: MausamColors.txtSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${city.state}, India · Tap to select areas',
            style: MausamTypography.microOf(context).copyWith(
              fontSize: 11,
              color: MausamColors.txtSecondary(context),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                key: Key('select_city_direct_${city.id}'),
                onTap: () => widget.onSelected(city),
                borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MausamColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                    border: Border.all(color: MausamColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Select City',
                    style: MausamTypography.microOf(context).copyWith(
                      color: MausamColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(MausamIcons.chevronRight, size: 16),
            ],
          ),
          onTap: () {
            setState(() {
              _drilledCity = city;
            });
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. LEVEL 2: LOCALITIES WITHIN SELECTED CITY (Strictly Sorted Alphabetically)
  // ---------------------------------------------------------------------------
  Widget _buildLocalitiesList(BuildContext context, bool isDark, Area city) {
    final localities = AreaService.getLocalitiesForCity(city.name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // City Centre option banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? const Color(0xFF17212D) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Localities in ${city.name} (${localities.length} available)',
                  style: MausamTypography.microOf(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: MausamColors.txtSecondary(context),
                  ),
                ),
              ),
              InkWell(
                key: Key('select_whole_city_${city.id}'),
                onTap: () => widget.onSelected(city),
                child: Text(
                  'Select ${city.name} as City',
                  style: MausamTypography.microOf(context).copyWith(
                    color: MausamColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: localities.length,
            separatorBuilder: (context, _) => Divider(
              height: 1,
              indent: 52,
              color: MausamColors.brdSubtle(context),
            ),
            itemBuilder: (context, index) {
              final locality = localities[index];
              final isSelected = widget.selectedArea?.id == locality.id ||
                  (widget.selectedArea?.name.toLowerCase() == locality.name.toLowerCase() &&
                      widget.selectedArea?.city.toLowerCase() == locality.city.toLowerCase());

              return _buildAreaTile(
                context: context,
                isDark: isDark,
                area: locality,
                isSelected: isSelected,
                showParentCity: true,
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: AREA / LOCALITY TILE (Clean, Accessible, Shows Context)
  // ---------------------------------------------------------------------------
  Widget _buildAreaTile({
    required BuildContext context,
    required bool isDark,
    required Area area,
    required bool isSelected,
    required bool showParentCity,
  }) {
    final badgeColor = _getBadgeColor(context, area.type);

    return ListTile(
      key: Key('area_item_${area.id}'),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? MausamColors.accent.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        ),
        child: Icon(
          _getIconForType(area.type),
          size: 15,
          color: isSelected ? MausamColors.accent : MausamColors.txtSecondary(context),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              area.name,
              style: MausamTypography.bodyMediumOf(context).copyWith(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? MausamColors.accent : MausamColors.txtPrimary(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Text(
              area.typeLabel,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        showParentCity ? '${area.city}, ${area.state}' : '${area.state}, India',
        style: MausamTypography.microOf(context).copyWith(
          fontSize: 11,
          color: MausamColors.txtSecondary(context),
        ),
      ),
      trailing: isSelected
          ? const Icon(MausamIcons.check, size: 16, color: MausamColors.accent)
          : null,
      onTap: () => widget.onSelected(area),
    );
  }
}
