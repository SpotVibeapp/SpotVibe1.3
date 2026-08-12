import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../theme/theme.dart';

// ── Data models ───────────────────────────────────────────────────────────────

/// Date preset options matching the reference filter spec.
const List<({String value, String label, IconData icon})> kDatePresets = [
  (value: 'all',          label: 'All dates',    icon: Icons.calendar_today_outlined),
  (value: 'today',        label: 'Today',         icon: Icons.today_outlined),
  (value: 'tomorrow',     label: 'Tomorrow',      icon: Icons.calendar_month_outlined),
  (value: 'this_weekend', label: 'This weekend',  icon: Icons.weekend_outlined),
  (value: 'this_week',    label: 'This week',     icon: Icons.date_range_outlined),
  (value: 'custom',       label: 'Custom range',  icon: Icons.tune_outlined),
];

/// Price tier options.
const List<({String value, String label})> kPriceOptions = [
  (value: 'all',      label: 'Any price'),
  (value: 'free',     label: 'Free'),
  (value: 'under_20', label: 'Under \$20'),
  (value: 'under_50', label: 'Under \$50'),
];

/// Time-of-day slot options.
const List<({String value, String label, IconData icon})> kTimeSlots = [
  (value: 'all',       label: 'Any time',   icon: Icons.access_time_outlined),
  (value: 'morning',   label: 'Morning',    icon: Icons.wb_sunny_outlined),
  (value: 'afternoon', label: 'Afternoon',  icon: Icons.wb_cloudy_outlined),
  (value: 'evening',   label: 'Evening',    icon: Icons.brightness_3_outlined),
  (value: 'night',     label: 'Night',      icon: Icons.nightlight_outlined),
];

// ── FilterSheet ───────────────────────────────────────────────────────────────

class FilterSheet extends StatefulWidget {
  final String initialDatePreset;
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;
  final String initialPrice;
  final String? initialCostType;
  final String initialTimeOfDay;
  final String initialLocation;
  final Set<EventSource> initialSources;
  final double initialRadius;

  final void Function({
    String datePreset,
    DateTime? dateFrom,
    DateTime? dateTo,
    String priceFilter,
    String? costType,
    String timeOfDay,
    String locationQuery,
    Set<EventSource> sources,
    double radius,
  }) onApply;
  final VoidCallback onClear;

  const FilterSheet({
    super.key,
    this.initialDatePreset = 'all',
    this.initialDateFrom,
    this.initialDateTo,
    this.initialPrice = 'all',
    this.initialCostType,
    this.initialTimeOfDay = 'all',
    this.initialLocation = '',
    this.initialSources = const {},
    this.initialRadius = 25.0,
    required this.onApply,
    required this.onClear,
  });

  static Future<void> show(
    BuildContext context, {
    String initialDatePreset = 'all',
    DateTime? initialDateFrom,
    DateTime? initialDateTo,
    String initialPrice = 'all',
    String? initialCostType,
    String initialTimeOfDay = 'all',
    String initialLocation = '',
    Set<EventSource> initialSources = const {},
    double initialRadius = 25.0,
    required void Function({
      String datePreset,
      DateTime? dateFrom,
      DateTime? dateTo,
      String priceFilter,
      String? costType,
      String timeOfDay,
      String locationQuery,
      Set<EventSource> sources,
      double radius,
    }) onApply,
    required VoidCallback onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        initialDatePreset: initialDatePreset,
        initialDateFrom: initialDateFrom,
        initialDateTo: initialDateTo,
        initialPrice: initialPrice,
        initialCostType: initialCostType,
        initialTimeOfDay: initialTimeOfDay,
        initialLocation: initialLocation,
        initialSources: initialSources,
        initialRadius: initialRadius,
        onApply: onApply,
        onClear: onClear,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String _datePreset;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  late String _price;
  late String _timeOfDay;
  late TextEditingController _locationController;
  late Set<EventSource> _selectedSources;
  late double _radius;

  static const double _minRadius = 5.0;
  static const double _maxRadius = 100.0;

  @override
  void initState() {
    super.initState();
    _datePreset = widget.initialDatePreset;
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
    _price = widget.initialPrice;
    _timeOfDay = widget.initialTimeOfDay;
    _locationController = TextEditingController(text: widget.initialLocation);
    _selectedSources = Set.from(widget.initialSources);
    _radius = widget.initialRadius.clamp(_minRadius, _maxRadius);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_dateFrom ?? now) : (_dateTo ?? now);
    final first = isFrom ? now : (_dateFrom ?? now);
    final result = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (result == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = result;
        if (_dateTo != null && _dateTo!.isBefore(result)) _dateTo = null;
      } else {
        _dateTo = result;
      }
    });
  }

  String _fmt(DateTime? dt) =>
      dt == null ? 'Any date' : DateFormat('MMM d, yyyy').format(dt);

  String get _radiusLabel =>
      _radius >= _maxRadius ? 'Any distance' : '${_radius.round()} mi';

  bool get _hasAnyFilter =>
      _datePreset != 'all' ||
      _dateFrom != null ||
      _dateTo != null ||
      _price != 'all' ||
      _timeOfDay != 'all' ||
      _locationController.text.isNotEmpty ||
      _selectedSources.isNotEmpty ||
      _radius != 25.0;

  void _clearAll() {
    setState(() {
      _datePreset = 'all';
      _dateFrom = null;
      _dateTo = null;
      _price = 'all';
      _timeOfDay = 'all';
      _locationController.clear();
      _selectedSources.clear();
      _radius = 25.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: Column(
            children: [
              // ── Handle + header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd, AppTheme.spacingSm, AppTheme.spacingMd, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text('Filter Events', style: text.titleLarge),
                        const Spacer(),
                        if (_hasAnyFilter)
                          TextButton(
                            onPressed: _clearAll,
                            child: Text(
                              'Clear all',
                              style: text.labelMedium?.copyWith(color: colors.primary),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: AppTheme.spacingLg),

              // ── Scrollable body ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: bottomPadding + AppTheme.spacingXl,
                  ),
                  children: [
                    // ── Date section ─────────────────────────────────────
                    _SectionHeader(label: 'Date', text: text),
                    _HorizontalChipRow(
                      children: kDatePresets.map((p) {
                        final selected = _datePreset == p.value;
                        return _FilterChip(
                          label: p.label,
                          icon: p.icon,
                          isSelected: selected,
                          onTap: () => setState(() {
                            _datePreset = p.value;
                            if (p.value != 'custom') {
                              _dateFrom = null;
                              _dateTo = null;
                            }
                          }),
                          colors: colors,
                          text: text,
                        );
                      }).toList(),
                    ),

                    // Custom date range pickers (shown only when custom is selected)
                    if (_datePreset == 'custom') ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DateButton(
                                label: 'From',
                                value: _fmt(_dateFrom),
                                isSet: _dateFrom != null,
                                onTap: () => _pickDate(isFrom: true),
                                colors: colors,
                                text: text,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: _DateButton(
                                label: 'To',
                                value: _fmt(_dateTo),
                                isSet: _dateTo != null,
                                onTap: () => _pickDate(isFrom: false),
                                colors: colors,
                                text: text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Price section ────────────────────────────────────
                    _SectionHeader(label: 'Price', text: text),
                    _HorizontalChipRow(
                      children: kPriceOptions.map((p) {
                        final selected = _price == p.value;
                        return _FilterChip(
                          label: p.label,
                          isSelected: selected,
                          onTap: () => setState(() => _price = p.value),
                          colors: colors,
                          text: text,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Time of Day section ──────────────────────────────
                    _SectionHeader(label: 'Time of Day', text: text),
                    _HorizontalChipRow(
                      children: kTimeSlots.map((t) {
                        final selected = _timeOfDay == t.value;
                        return _FilterChip(
                          label: t.label,
                          icon: t.icon,
                          isSelected: selected,
                          onTap: () => setState(() => _timeOfDay = t.value),
                          colors: colors,
                          text: text,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Distance slider ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: Row(
                        children: [
                          Text('Distance', style: text.titleSmall),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              key: ValueKey(_radiusLabel),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSm, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                              ),
                              child: Text(
                                _radiusLabel,
                                style: text.labelSmall?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: colors.primary,
                              inactiveTrackColor: colors.surfaceContainerHighest,
                              thumbColor: colors.primary,
                              overlayColor: colors.primary.withValues(alpha: 0.12),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            ),
                            child: Slider(
                              value: _radius,
                              min: _minRadius,
                              max: _maxRadius,
                              divisions: 19,
                              onChanged: (v) => setState(() => _radius = v),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('5 mi', style: text.labelSmall),
                                Text('Any', style: text.labelSmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Location text field ──────────────────────────────
                    _SectionHeader(label: 'Location', text: text),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Brooklyn, Manhattan...',
                          prefixIcon: Icon(Icons.location_on_outlined,
                              color: colors.onSurfaceVariant),
                          suffixIcon: _locationController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      size: AppTheme.iconSm,
                                      color: colors.onSurfaceVariant),
                                  onPressed: () =>
                                      setState(() => _locationController.clear()),
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Event Sources ────────────────────────────────────
                    _SectionHeader(label: 'Event Sources', text: text),
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd),
                        children: EventSource.values.map((src) {
                          final selected = _selectedSources.contains(src);
                          return Padding(
                            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedSources.remove(src);
                                } else {
                                  _selectedSources.add(src);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: AppTheme.spacingXs),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? src.brandColor.withValues(alpha: 0.15)
                                      : colors.surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusXl),
                                  border: Border.all(
                                    color: selected
                                        ? src.brandColor
                                        : colors.outlineVariant.withValues(alpha: 0.3),
                                    width: selected
                                        ? AppTheme.borderSelected
                                        : AppTheme.borderDefault,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(src.icon,
                                        size: AppTheme.iconSm,
                                        color: selected
                                            ? src.brandColor
                                            : colors.onSurfaceVariant),
                                    const SizedBox(width: AppTheme.spacingXs),
                                    Text(
                                      src.displayName,
                                      style: text.labelSmall?.copyWith(
                                        color: selected
                                            ? src.brandColor
                                            : colors.onSurfaceVariant,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // ── Apply button ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onApply(
                            datePreset: _datePreset,
                            dateFrom: _datePreset == 'custom' ? _dateFrom : null,
                            dateTo: _datePreset == 'custom' ? _dateTo : null,
                            priceFilter: _price,
                            costType: null,
                            timeOfDay: _timeOfDay,
                            locationQuery: _locationController.text.trim(),
                            sources: Set.from(_selectedSources),
                            radius: _radius,
                          );
                        },
                        child: const Text('Show Results'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final TextTheme text;

  const _SectionHeader({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingSm),
      child: Text(label, style: text.titleSmall),
    );
  }
}

class _HorizontalChipRow extends StatelessWidget {
  final List<Widget> children;

  const _HorizontalChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        children: children
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                  child: c,
                ))
            .toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;
  final TextTheme text;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? AppTheme.borderSelected : AppTheme.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppTheme.iconSm,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppTheme.spacingXs),
            ],
            Text(
              label,
              style: text.labelMedium?.copyWith(
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSet;
  final VoidCallback onTap;
  final ColorScheme colors;
  final TextTheme text;

  const _DateButton({
    required this.label,
    required this.value,
    required this.isSet,
    required this.onTap,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm + 2,
        ),
        decoration: BoxDecoration(
          color: isSet ? colors.primaryContainer : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSet ? colors.primary : colors.outlineVariant,
            width: isSet ? AppTheme.borderSelected : AppTheme.borderDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.labelSmall?.copyWith(
                color: isSet ? colors.primary : appColors.subtleText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: text.bodySmall?.copyWith(
                color: isSet ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
