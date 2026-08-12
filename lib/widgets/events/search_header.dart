import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class SearchHeader extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onAreaSearch;
  final VoidCallback onProfileTap;
  final bool isLoggedIn;
  final String? avatarUrl;
  // External controller lets parent widgets (like the area strip) clear the field
  final TextEditingController? areaController;
  /// Called when the user taps the "Near me" GPS button — parent resolves GPS.
  final VoidCallback? onUseMyLocation;
  /// When true the GPS pin button shows in active/filled state.
  final bool isUsingMyLocation;
  /// Returns autocomplete suggestions for a given query string.
  final List<String> Function(String query)? onSuggestionsRequest;

  const SearchHeader({
    super.key,
    required this.onSearch,
    required this.onAreaSearch,
    required this.onProfileTap,
    required this.isLoggedIn,
    this.avatarUrl,
    this.areaController,
    this.onUseMyLocation,
    this.isUsingMyLocation = false,
    this.onSuggestionsRequest,
  });

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  final _keywordController = TextEditingController();
  final _keywordFocus = FocusNode();
  final _layerLink = LayerLink();
  // Use externally-provided controller or own internal one
  late final TextEditingController _areaController;
  late final bool _ownsAreaController;

  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _ownsAreaController = widget.areaController == null;
    _areaController = widget.areaController ?? TextEditingController();
    _keywordController.addListener(_rebuild);
    _areaController.addListener(_rebuild);
    _keywordFocus.addListener(_onFocusChange);
  }

  void _rebuild() => setState(() {});

  void _onFocusChange() {
    if (!_keywordFocus.hasFocus) {
      _hideOverlay();
    }
  }

  void _updateSuggestions(String query) {
    if (widget.onSuggestionsRequest == null || query.trim().isEmpty) {
      _hideOverlay();
      return;
    }
    final results = widget.onSuggestionsRequest!(query);
    if (results.isEmpty) {
      _hideOverlay();
      return;
    }
    _suggestions = results;
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(String suggestion) {
    _keywordController.text = suggestion;
    _keywordController.selection =
        TextSelection.collapsed(offset: suggestion.length);
    widget.onSearch(suggestion);
    _hideOverlay();
    _keywordFocus.unfocus();
  }

  Widget _buildOverlay() {
    return Positioned(
      width: 0,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 44),
        child: _AutocompleteDropdown(
          suggestions: _suggestions,
          onSelect: _selectSuggestion,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    _keywordController.removeListener(_rebuild);
    _areaController.removeListener(_rebuild);
    _keywordFocus.removeListener(_onFocusChange);
    _keywordController.dispose();
    _keywordFocus.dispose();
    if (_ownsAreaController) _areaController.dispose();
    super.dispose();
  }

  void clearArea() {
    _areaController.clear();
    widget.onAreaSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final hasArea = _areaController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Keyword Search with Autocomplete ───────────────────────
                CompositedTransformTarget(
                  link: _layerLink,
                  child: TextField(
                    controller: _keywordController,
                    focusNode: _keywordFocus,
                    onChanged: (v) {
                      widget.onSearch(v);
                      _updateSuggestions(v);
                    },
                    onSubmitted: (_) => _hideOverlay(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search events, artists, venues...',
                      prefixIcon: Icon(Icons.search_rounded, color: colors.onSurfaceVariant),
                      suffixIcon: _keywordController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  size: AppTheme.iconSm, color: colors.onSurfaceVariant),
                              onPressed: () {
                                _keywordController.clear();
                                widget.onSearch('');
                                _hideOverlay();
                              },
                            )
                          : null,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                // ── Area Search ────────────────────────────────────────────
                TextField(
                  controller: _areaController,
                  onSubmitted: widget.onAreaSearch,
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                    widget.onAreaSearch(_areaController.text);
                  },
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Zip code, city, or state...',
                    prefixIcon: Icon(
                      hasArea ? Icons.location_on_rounded : Icons.my_location_rounded,
                      color: hasArea ? colors.primary : colors.onSurfaceVariant,
                      size: AppTheme.iconSm + 2,
                    ),
                    suffixIcon: hasArea
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                size: AppTheme.iconSm, color: colors.onSurfaceVariant),
                            onPressed: clearArea,
                          )
                        : (widget.onUseMyLocation != null
                            ? Tooltip(
                                message: widget.isUsingMyLocation
                                    ? 'Using your location'
                                    : 'Use my location',
                                child: IconButton(
                                  icon: Icon(
                                    widget.isUsingMyLocation
                                        ? Icons.near_me_rounded
                                        : Icons.near_me_outlined,
                                    size: AppTheme.iconSm,
                                    color: widget.isUsingMyLocation
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                                  onPressed: widget.onUseMyLocation,
                                ),
                              )
                            : null),
                    isDense: true,
                    filled: true,
                    fillColor: hasArea
                        ? colors.primaryContainer.withValues(alpha: 0.22)
                        : widget.isUsingMyLocation
                            ? colors.primaryContainer.withValues(alpha: 0.15)
                            : colors.surfaceContainerHighest.withValues(alpha: 0.45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide(
                        color: hasArea
                            ? colors.primary.withValues(alpha: 0.55)
                            : colors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide(
                        color: hasArea || widget.isUsingMyLocation
                            ? colors.primary.withValues(alpha: 0.45)
                            : colors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide:
                          BorderSide(color: colors.primary, width: AppTheme.borderSelected),
                    ),
                    hintStyle: text.bodySmall?.copyWith(color: appColors.subtleText),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // ── Profile / Login Avatar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colors.primaryContainer,
                child: widget.isLoggedIn
                    ? ClipOval(
                        child: Image.network(
                          widget.avatarUrl ?? '',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.person, color: colors.onPrimaryContainer),
                        ),
                      )
                    : Icon(Icons.person_outline_rounded, color: colors.onPrimaryContainer),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Autocomplete dropdown overlay ─────────────────────────────────────────────

class _AutocompleteDropdown extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  const _AutocompleteDropdown({
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      color: colors.surface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (_, index) {
              final s = suggestions[index];
              return InkWell(
                onTap: () => onSelect(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm + 2,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: AppTheme.iconSm, color: colors.onSurfaceVariant),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          s,
                          style: text.bodyMedium?.copyWith(color: colors.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.north_west_rounded,
                          size: AppTheme.iconSm - 2, color: colors.onSurfaceVariant),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
