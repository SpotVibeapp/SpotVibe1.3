import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/pricing.dart';
import '../models/user_event.dart';
import '../providers/auth_provider.dart';
import '../providers/create_event_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_events_provider.dart';
import '../repositories/user_event_repository.dart';
import '../services/ai_moderation_service.dart';
import '../services/user_event_service.dart';
import '../theme/theme.dart';

export '../models/user_event.dart' show RecurringType;

class CreateEventScreen extends StatefulWidget {
  final UserCreatedEvent? editingEvent;
  const CreateEventScreen({super.key, this.editingEvent});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _costController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _chatLinkController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _selectedCategory = 'Music';
  bool _isPremiumListing = false;
  bool _purchaseConfirmed = false;
  String? _moderationError;

  // ── Creator Pro fields ────────────────────────────────────────────────────
  bool _isCreatorPro = false;
  RecurringType _recurringType = RecurringType.none;
  final _contactPhoneController = TextEditingController();
  final _contactWebsiteController = TextEditingController();
  final _contactSocialController = TextEditingController();
  final _brandColorController = TextEditingController();
  final _brandLogoController = TextEditingController();

  static const List<String> _categories = [
    'Music', 'Food & Drink', 'Arts', 'Sports', 'Tech', 'Community', 'Family', 'Health', 'Fun & Games', 'Other',
  ];

  bool get _isEditing => widget.editingEvent != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editingEvent;
    if (e != null) {
      _titleController.text = e.title;
      _descriptionController.text = e.description;
      _locationController.text = e.location;
      _addressController.text = e.address;
      _cityController.text = e.city;
      _stateController.text = e.state;
      _zipController.text = e.zipCode;
      if (e.cost != null) _costController.text = e.cost!.toStringAsFixed(2);
      _imageUrlController.text = e.imageUrl;
      _videoUrlController.text = e.videoUrl ?? '';
      _mapLinkController.text = e.mapLink ?? '';
      _chatLinkController.text = e.chatLink ?? '';
      _selectedDate = e.dateTime;
      _selectedTime = TimeOfDay(hour: e.dateTime.hour, minute: e.dateTime.minute);
      _selectedCategory = e.category;
      _isPremiumListing = e.isPremiumListing;
      _purchaseConfirmed = true; // editing — already paid/confirmed
      // Restore Creator Pro fields if event was created as Creator Pro
      _isCreatorPro = e.isCreatorPro;
      _recurringType = e.recurringType;
      _contactPhoneController.text = e.contactPhone ?? '';
      _contactWebsiteController.text = e.contactWebsite ?? '';
      _contactSocialController.text = e.contactSocial ?? '';
      _brandColorController.text = e.brandColor ?? '';
      _brandLogoController.text = e.brandLogoUrl ?? '';
    }
    // Pro subscribers get unlimited creation — pre-confirm for them after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sub = context.read<SubscriptionProvider>();
      if (sub.isSubscribed) {
        setState(() {
          _purchaseConfirmed = true;
          _isCreatorPro = true;
        });
      } else {
        setState(() => _purchaseConfirmed = true);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _costController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _mapLinkController.dispose();
    _chatLinkController.dispose();
    _contactPhoneController.dispose();
    _contactWebsiteController.dispose();
    _contactSocialController.dispose();
    _brandColorController.dispose();
    _brandLogoController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  double? get _parsedCost {
    final text = _costController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll('\$', ''));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _openPaywall() async {
    final result = await context.push<bool>('/paywall');
    if (result == true && mounted) {
      setState(() {
        _isCreatorPro = true;
        _purchaseConfirmed = true;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final subCheck = context.read<SubscriptionProvider>();
    if (!_isEditing && !subCheck.isSubscribed) {
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.id;
      if (uid != null) {
        final mine = await context.read<UserEventRepository>().getEventsForUser(uid);
        final active = countActiveUserEvents(mine.map((e) => e.dateTime));
        if (!canPostAnotherFreeEvent(active, isPremium: false)) {
          if (!mounted) return;
          final upgrade = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('One active event on Free'),
              content: const Text(
                'Free accounts can have one upcoming event at a time. '
                'Upgrade to Premium ($kPremiumMonthlyLabel) for unlimited and recurring events.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Go Premium')),
              ],
            ),
          );
          if (upgrade == true && mounted) await _openPaywall();
          return;
        }
      }
    }

    // ── AI content moderation ───────────────────────────────────────────────
    setState(() => _moderationError = null);
    final modService = context.read<AiModerationService>();
    final modResult = await modService.moderateFields([
      _titleController.text,
      _descriptionController.text,
    ]);
    if (!mounted) return;
    if (modResult.isRejected) {
      setState(() => _moderationError =
          '${modResult.category ?? 'Content'} policy violation: ${modResult.reason}');
      return;
    }
    if (modResult.isFlagged) {
      setState(() => _moderationError =
          '${modResult.category ?? 'Content'} warning: ${modResult.reason} Your event will still be submitted.');
    }
    // ────────────────────────────────────────────────────────────────────────

    final provider = context.read<CreateEventProvider>();
    final result = await provider.submit(
      title: _titleController.text,
      description: _descriptionController.text,
      dateTime: _combinedDateTime,
      location: _locationController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipController.text,
      cost: _parsedCost,
      imageUrl: _imageUrlController.text.trim(),
      videoUrl: _videoUrlController.text.trim().isEmpty ? null : _videoUrlController.text.trim(),
      category: _selectedCategory,
      mapLink: _mapLinkController.text.trim().isEmpty ? null : _mapLinkController.text.trim(),
      chatLink: _chatLinkController.text.trim().isEmpty ? null : _chatLinkController.text.trim(),
      isPremiumListing: _isPremiumListing,
      isCreatorPro: _isCreatorPro,
      recurringType: _isCreatorPro ? _recurringType : RecurringType.none,
      contactPhone: _isCreatorPro ? _contactPhoneController.text.trim() : null,
      contactWebsite: _isCreatorPro ? _contactWebsiteController.text.trim() : null,
      contactSocial: _isCreatorPro ? _contactSocialController.text.trim() : null,
      brandColor: _isCreatorPro ? _brandColorController.text.trim() : null,
      brandLogoUrl: _isCreatorPro ? _brandLogoController.text.trim() : null,
    );

    if (!mounted) return;

    if (result != null) {
      // Push to parent UserEventsProvider if available
      if (!_isEditing) {
        try {
          context.read<UserEventsProvider>().addEvent(result);
        } catch (_) {}
      } else {
        try {
          context.read<UserEventsProvider>().updateEvent(result);
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Event updated!' : 'Event created!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreateEventProvider>();
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
        actions: [
          if (provider.isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(onPressed: _submit, child: Text(_isEditing ? 'Save' : 'Publish')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            if (provider.errorMessage != null)
              _ErrorBanner(message: provider.errorMessage!, onDismiss: provider.clearError),
            if (_moderationError != null)
              _ErrorBanner(
                message: _moderationError!,
                onDismiss: () => setState(() => _moderationError = null),
              ),

            // Access selector (only for new events)
            if (!_isEditing) ...[
              _SectionHeader(title: 'Event Publishing'),
              _CreationAccessSelector(
                isSubscribed: sub.isSubscribed,
                onUpgrade: _openPaywall,
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            _SectionHeader(title: 'Event Details'),
            _FormField(
              controller: _titleController,
              label: 'Event Title',
              hint: 'e.g. Summer Night Market',
              icon: Icons.title_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Tell people what your event is about...',
              icon: Icons.description_rounded,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Category picker
            _CategoryDropdown(
              value: _selectedCategory,
              categories: _categories,
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            _SectionHeader(title: 'Date & Time'),
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Date',
                    value: '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            _SectionHeader(title: 'Location'),
            _FormField(
              controller: _locationController,
              label: 'Venue Name',
              hint: 'e.g. Riverside Park',
              icon: Icons.location_on_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Venue name is required' : null,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _addressController,
              label: 'Street Address',
              hint: '123 Main St',
              icon: Icons.home_rounded,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _FormField(controller: _cityController, label: 'City', hint: 'New York', icon: Icons.location_city_rounded),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _FormField(controller: _stateController, label: 'State', hint: 'NY', icon: Icons.map_rounded),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _FormField(controller: _zipController, label: 'ZIP', hint: '10001', icon: Icons.numbers_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _mapLinkController,
              label: 'Map Link (optional)',
              hint: 'https://maps.google.com/...',
              icon: Icons.map_outlined,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            _SectionHeader(title: 'Extras'),
            _FormField(
              controller: _costController,
              label: 'Ticket Price (leave blank for free)',
              hint: '0.00',
              icon: Icons.attach_money_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = double.tryParse(v.replaceAll('\$', ''));
                if (parsed == null || parsed < 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _imageUrlController,
              label: 'Event Image URL (optional)',
              hint: 'https://example.com/image.jpg',
              icon: Icons.image_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _videoUrlController,
              label: 'Event Video URL (optional)',
              hint: 'https://youtube.com/watch?v=... or .mp4 link',
              icon: Icons.videocam_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _chatLinkController,
              label: 'Community Chat Link (optional)',
              hint: 'https://discord.gg/... or WhatsApp, Telegram link',
              icon: Icons.forum_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Creator Pro Section ─────────────────────────────────────────
            _CreatorProSection(
              isCreatorPro: _isCreatorPro,
              recurringType: _recurringType,
              contactPhoneController: _contactPhoneController,
              contactWebsiteController: _contactWebsiteController,
              contactSocialController: _contactSocialController,
              brandColorController: _brandColorController,
              brandLogoController: _brandLogoController,
              onUpgrade: _openPaywall,
              onRecurringChanged: (v) => setState(() => _recurringType = v),
            ),

            const SizedBox(height: AppTheme.spacingXl),
            FilledButton.icon(
              onPressed: provider.isSubmitting ? null : _submit,
              icon: const Icon(Icons.publish_rounded),
              label: Text(_isEditing
                  ? 'Save Changes'
                  : sub.isSubscribed
                      ? 'Publish Event — Premium'
                      : 'Publish Event — Free'),
            ),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

// ── Creator Pro Section ────────────────────────────────────────────────────────

class _CreatorProSection extends StatelessWidget {
  final bool isCreatorPro;
  final RecurringType recurringType;
  final TextEditingController contactPhoneController;
  final TextEditingController contactWebsiteController;
  final TextEditingController contactSocialController;
  final TextEditingController brandColorController;
  final TextEditingController brandLogoController;
  final VoidCallback onUpgrade;
  final ValueChanged<RecurringType> onRecurringChanged;

  const _CreatorProSection({
    required this.isCreatorPro,
    required this.recurringType,
    required this.contactPhoneController,
    required this.contactWebsiteController,
    required this.contactSocialController,
    required this.brandColorController,
    required this.brandLogoController,
    required this.onUpgrade,
    required this.onRecurringChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;

    if (!isCreatorPro) {
      // Upgrade prompt card
      return GestureDetector(
        onTap: onUpgrade,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [appColors.creatorTeal.withValues(alpha: 0.08), appColors.creatorTealLight.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: appColors.creatorTeal.withValues(alpha: 0.35), width: AppTheme.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [appColors.creatorTeal, appColors.creatorTealLight]),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: AppTheme.iconMd),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Creator Pro', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: AppTheme.spacingXs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: appColors.creatorTeal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          ),
                          child: Text(
                            '\$15/mo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: appColors.creatorTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Recurring events · analytics · custom branding · contact button',
                      style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: appColors.creatorTeal),
            ],
          ),
        ),
      );
    }

    // Unlocked Creator Pro fields
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [appColors.creatorTeal, appColors.creatorTealLight]),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: AppTheme.iconSm),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                'Premium features unlocked',
                style: text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Recurring picker
        _SectionHeader(title: 'Recurring Schedule'),
        _RecurringPicker(value: recurringType, onChanged: onRecurringChanged, appColors: appColors, colors: colors, text: text),
        const SizedBox(height: AppTheme.spacingLg),

        // Contact info
        _SectionHeader(title: 'Contact Info'),
        _FormField(controller: contactPhoneController, label: 'Phone (optional)', hint: '+1 555-000-0000', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
        const SizedBox(height: AppTheme.spacingMd),
        _FormField(controller: contactWebsiteController, label: 'Website (optional)', hint: 'https://yoursite.com', icon: Icons.language_rounded, keyboardType: TextInputType.url),
        const SizedBox(height: AppTheme.spacingMd),
        _FormField(controller: contactSocialController, label: 'Social Handle (optional)', hint: '@yourhandle or full URL', icon: Icons.alternate_email_rounded),
        const SizedBox(height: AppTheme.spacingLg),

        // Custom branding
        _SectionHeader(title: 'Custom Branding'),
        _FormField(controller: brandColorController, label: 'Brand Accent Color', hint: '#FF5733', icon: Icons.palette_rounded),
        const SizedBox(height: AppTheme.spacingMd),
        _FormField(controller: brandLogoController, label: 'Brand Logo URL (optional)', hint: 'https://yoursite.com/logo.png', icon: Icons.image_rounded, keyboardType: TextInputType.url),
      ],
    );
  }
}

class _RecurringPicker extends StatelessWidget {
  final RecurringType value;
  final ValueChanged<RecurringType> onChanged;
  final AppColorsExtension appColors;
  final ColorScheme colors;
  final TextTheme text;

  const _RecurringPicker({
    required this.value,
    required this.onChanged,
    required this.appColors,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RecurringOption(
          label: 'One-time',
          icon: Icons.event_rounded,
          type: RecurringType.none,
          selected: value == RecurringType.none,
          onTap: () => onChanged(RecurringType.none),
          appColors: appColors,
          colors: colors,
          text: text,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        _RecurringOption(
          label: 'Weekly',
          icon: Icons.repeat_rounded,
          type: RecurringType.weekly,
          selected: value == RecurringType.weekly,
          onTap: () => onChanged(RecurringType.weekly),
          appColors: appColors,
          colors: colors,
          text: text,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        _RecurringOption(
          label: 'Monthly',
          icon: Icons.calendar_month_rounded,
          type: RecurringType.monthly,
          selected: value == RecurringType.monthly,
          onTap: () => onChanged(RecurringType.monthly),
          appColors: appColors,
          colors: colors,
          text: text,
        ),
      ],
    );
  }
}

class _RecurringOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final RecurringType type;
  final bool selected;
  final VoidCallback onTap;
  final AppColorsExtension appColors;
  final ColorScheme colors;
  final TextTheme text;

  const _RecurringOption({
    required this.label,
    required this.icon,
    required this.type,
    required this.selected,
    required this.onTap,
    required this.appColors,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: selected ? appColors.creatorTeal.withValues(alpha: 0.12) : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? appColors.creatorTeal : colors.outlineVariant.withValues(alpha: 0.3),
              width: selected ? AppTheme.borderSelected : AppTheme.borderDefault,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: AppTheme.iconSm + 4, color: selected ? appColors.creatorTeal : colors.onSurfaceVariant),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: selected ? appColors.creatorTeal : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(title, style: text.titleSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: AppTheme.iconSm, color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.value, required this.categories, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_rounded, size: AppTheme.iconSm, color: colors.onSurfaceVariant),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTimeTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppTheme.iconSm, color: colors.primary),
                const SizedBox(width: AppTheme.spacingXs),
                Expanded(
                  child: Text(
                    label,
                    style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CreationAccessSelector extends StatelessWidget {
  final bool isSubscribed;
  final VoidCallback onUpgrade;

  const _CreationAccessSelector({
    required this.isSubscribed,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (isSubscribed) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: appColors.proGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: appColors.proGold, width: AppTheme.borderSelected),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: appColors.proGold, size: AppTheme.iconMd),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium — unlimited events',
                    style: text.titleSmall?.copyWith(color: appColors.proGold),
                  ),
                  Text(
                    'Recurring events, analytics, branding, and claims are included.',
                    style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle_rounded, color: appColors.proGold, size: AppTheme.iconMd),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Free plan', style: text.titleSmall),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'One upcoming one-time event at a time. Basic page (title, description, photo, location, time) in the public feed.',
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          OutlinedButton.icon(
            onPressed: onUpgrade,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('Upgrade to Premium — \$15/month'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                  ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: colors.onErrorContainer),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
