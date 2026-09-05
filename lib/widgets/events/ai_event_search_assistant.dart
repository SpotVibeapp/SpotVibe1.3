import 'package:flutter/material.dart';

import '../../data/event_time.dart';
import '../../data/road_trip_destinations.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ai_event_search.dart';
import '../../models/event.dart';
import '../../services/ai_event_search_service.dart';
import '../../services/event_service.dart';
import '../../theme/theme.dart';

/// A prominent Home-screen entry point for conversational event discovery.
class AskSpotVibeCard extends StatelessWidget {
  final bool isSignedIn;
  final VoidCallback onTap;

  const AskSpotVibeCard({
    super.key,
    required this.isSignedIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        0,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      child: Semantics(
        button: true,
        label: l10n.askSpotVibe,
        child: Material(
          color: colors.primaryContainer.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.askSpotVibe,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSignedIn
                              ? l10n.askSpotVibeSubtitle
                              : l10n.askSpotVibeSignIn,
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSignedIn
                        ? Icons.arrow_forward_rounded
                        : Icons.lock_outline_rounded,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the signed-in Ask SpotVibe conversational search surface.
Future<void> showAiEventSearchAssistant(
  BuildContext context, {
  required EventService eventService,
  required String homeCity,
  required String homeState,
  required ValueChanged<Event> onOpenEvent,
  String initialQuery = '',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.58,
      maxChildSize: 0.96,
      expand: false,
      builder: (_, scrollController) => _AiEventSearchAssistant(
        scrollController: scrollController,
        eventService: eventService,
        homeCity: homeCity,
        homeState: homeState,
        initialQuery: initialQuery,
        onOpenEvent: (event) {
          Navigator.of(sheetContext).pop();
          onOpenEvent(event);
        },
      ),
    ),
  );
}

class _AiEventSearchAssistant extends StatefulWidget {
  final ScrollController scrollController;
  final EventService eventService;
  final String homeCity;
  final String homeState;
  final String initialQuery;
  final ValueChanged<Event> onOpenEvent;

  const _AiEventSearchAssistant({
    required this.scrollController,
    required this.eventService,
    required this.homeCity,
    required this.homeState,
    required this.initialQuery,
    required this.onOpenEvent,
  });

  @override
  State<_AiEventSearchAssistant> createState() =>
      _AiEventSearchAssistantState();
}

class _AiEventSearchAssistantState extends State<_AiEventSearchAssistant> {
  final _searchService = AiEventSearchService();
  late final TextEditingController _controller;
  bool _includeRoadTrips = false;
  bool _searching = false;
  String? _error;
  final List<_AssistantMessage> _messages = [];
  final _resultsKey = GlobalKey();
  List<_AssistantResultGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Reveals the first result group after a search completes. Waiting for the
  /// next frame ensures the newly added result widgets have a scroll position.
  void _revealSearchOutcome() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final target = _resultsKey.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          alignment: 0.06,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      if (!widget.scrollController.hasClients) return;
      await widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _search([String? suggestedQuery]) async {
    final query = (suggestedQuery ?? _controller.text).trim();
    final l10n = AppLocalizations.of(context)!;
    if (query.isEmpty) {
      setState(() => _error = l10n.aiSearchEmptyQuery);
      return;
    }
    if (_searching) return;

    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    setState(() {
      _searching = true;
      _error = null;
      _groups = const [];
      _messages.add(_AssistantMessage.user(query));
    });

    try {
      final plan = await _searchService.interpret(query);
      final groups = await _fetchRealResults(plan);
      if (!mounted) return;
      final found = groups.any((group) => group.events.isNotEmpty);
      setState(() {
        _groups = groups;
        _messages.add(
          _AssistantMessage.assistant(
            found ? l10n.aiSearchFoundRealResults : l10n.aiSearchNoResults,
          ),
        );
      });
      _revealSearchOutcome();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      _revealSearchOutcome();
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  List<_AssistantLocationTarget> _locationsFor(AiEventSearchPlan plan) {
    final requested = plan.requestedLocation;
    final primary = requested ??
        AiSearchLocation(city: widget.homeCity, state: widget.homeState);
    final targets = <_AssistantLocationTarget>[
      _AssistantLocationTarget(location: primary, isRoadTrip: false),
    ];

    // A city named directly in the query is searched on its own. Road-trip
    // expansion is reserved for an explicit opt-in from the person's home area.
    if (!_includeRoadTrips || requested != null) return targets;

    for (final destination in roadTripDestinationsFor(
      city: widget.homeCity,
      state: widget.homeState,
    )) {
      if (destination.normalizedKey == primary.normalizedKey) continue;
      targets.add(
        _AssistantLocationTarget(location: destination, isRoadTrip: true),
      );
    }
    return targets;
  }

  Future<List<_AssistantResultGroup>> _fetchRealResults(
    AiEventSearchPlan plan,
  ) async {
    final targets = _locationsFor(plan);
    final groups = await Future.wait(
      targets.map((target) async {
        var events = await _loadLocation(target.location, plan);
        if (events.isEmpty && plan.category != null) {
          // A category is useful AI context, but never let a category-label
          // mismatch hide real Ticketmaster or user-created listings.
          events = await _loadLocation(target.location, plan, ignoreCategory: true);
        }
        return _AssistantResultGroup(
          location: target.location,
          isRoadTrip: target.isRoadTrip,
          events: events.take(6).toList(growable: false),
        );
      }),
    );
    return groups;
  }

  Future<List<Event>> _loadLocation(
    AiSearchLocation location,
    AiEventSearchPlan plan, {
    bool ignoreCategory = false,
  }) {
    return widget.eventService.getUpcomingEvents(
      areaQuery: location.displayName,
      searchQuery: plan.specificSearchText,
      category: ignoreCategory ? null : plan.category,
      datePreset: plan.datePreset == 'all' ? null : plan.datePreset,
      searchRadius: 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          _AssistantHeader(
            title: l10n.askSpotVibe,
            onClose: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingLg,
              ),
              children: [
                _AssistantNotice(text: l10n.aiSearchRealResults),
                const SizedBox(height: AppTheme.spacingMd),
                _RoadTripToggle(
                  value: _includeRoadTrips,
                  onChanged: _searching
                      ? null
                      : (value) => setState(() => _includeRoadTrips = value),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  l10n.aiSearchTryPrompt,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  runSpacing: AppTheme.spacingSm,
                  children: [
                    _PromptChip(
                      label: l10n.aiSearchPromptMusic,
                      onTap: _searching ? null : () => _search(l10n.aiSearchPromptMusic),
                    ),
                    _PromptChip(
                      label: l10n.aiSearchPromptFamily,
                      onTap: _searching ? null : () => _search(l10n.aiSearchPromptFamily),
                    ),
                    _PromptChip(
                      label: l10n.aiSearchPromptFood,
                      onTap: _searching ? null : () => _search(l10n.aiSearchPromptFood),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                _AssistantBubble(
                  text: l10n.aiSearchIntro,
                  isUser: false,
                ),
                ..._messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                    child: _AssistantBubble(
                      text: message.text,
                      isUser: message.isUser,
                    ),
                  ),
                ),
                if (_searching) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  const LinearProgressIndicator(),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    l10n.aiSearchSearching,
                    style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  _AssistantError(text: _error!),
                ],
                if (_groups.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  KeyedSubtree(
                    key: _resultsKey,
                    child: Column(
                      children: [
                        for (final group in _groups)
                          _AssistantResultGroupView(
                            group: group,
                            onOpenEvent: widget.onOpenEvent,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: 420,
                        maxLines: 2,
                        minLines: 1,
                        enabled: !_searching,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: l10n.aiSearchHint,
                          counterText: '',
                          prefixIcon: const Icon(Icons.auto_awesome_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    FilledButton(
                      onPressed: _searching ? null : () => _search(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: _searching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _AssistantHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              title,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.close,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _AssistantNotice extends StatelessWidget {
  final String text;

  const _AssistantNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            color: colors.onSecondaryContainer,
            size: AppTheme.iconSm,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadTripToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _RoadTripToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.36)),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        secondary: Icon(Icons.directions_car_rounded, color: colors.primary),
        title: Text(l10n.aiSearchRoadTrips),
        subtitle: Text(l10n.aiSearchRoadTripsHint),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(Icons.auto_awesome_rounded, size: 15, color: colors.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _AssistantBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isUser ? colors.primaryContainer : colors.surfaceContainerLow;
    final foreground = isUser ? colors.onPrimaryContainer : colors.onSurface;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm + 2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class _AssistantError extends StatelessWidget {
  final String text;

  const _AssistantError({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantResultGroupView extends StatelessWidget {
  final _AssistantResultGroup group;
  final ValueChanged<Event> onOpenEvent;

  const _AssistantResultGroupView({
    required this.group,
    required this.onOpenEvent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final title = group.isRoadTrip
        ? l10n.aiSearchRoadTripResults(group.location.displayName)
        : l10n.aiSearchLocalResults(group.location.displayName);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Icon(
                    group.isRoadTrip
                        ? Icons.directions_car_rounded
                        : Icons.location_on_rounded,
                    color: group.isRoadTrip ? colors.tertiary : colors.primary,
                    size: AppTheme.iconSm,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Text(
                      title,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            if (group.events.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  0,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                ),
                child: Text(
                  l10n.aiSearchNoResultsHere,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              )
            else
              ...group.events.map(
                (event) => _AssistantEventTile(
                  event: event,
                  onTap: () => onOpenEvent(event),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssistantEventTile extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _AssistantEventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final time = event.isHappeningNow
        ? l10n.happeningNow
        : formatEventWhen(event.dateTime);
    final price = event.isFree ? l10n.free : event.costLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            AppTheme.spacingSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(Icons.event_rounded, color: colors.primary),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$time · ${event.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                price,
                style: text.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantMessage {
  final String text;
  final bool isUser;

  const _AssistantMessage._({required this.text, required this.isUser});

  factory _AssistantMessage.user(String text) =>
      _AssistantMessage._(text: text, isUser: true);

  factory _AssistantMessage.assistant(String text) =>
      _AssistantMessage._(text: text, isUser: false);
}

class _AssistantLocationTarget {
  final AiSearchLocation location;
  final bool isRoadTrip;

  const _AssistantLocationTarget({
    required this.location,
    required this.isRoadTrip,
  });
}

class _AssistantResultGroup {
  final AiSearchLocation location;
  final bool isRoadTrip;
  final List<Event> events;

  const _AssistantResultGroup({
    required this.location,
    required this.isRoadTrip,
    required this.events,
  });
}
