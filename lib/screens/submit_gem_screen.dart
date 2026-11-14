import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/gem.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/event_service.dart';
import '../services/gem_service.dart';
import '../services/location_service.dart';
import '../services/media_upload_service.dart';
import '../platform/local_media.dart';
import '../theme/theme.dart';

/// Lets a signed-in user submit or edit a Hidden Gem. The form forks:
/// share a spot you love (free: name, category, short summary, location)
/// or promote a business (Premium: photos, description, contact, offer).
///
/// Pass [gem] to edit an existing gem instead of creating a new one. Only the
/// original creator (or an admin) reaches this route in edit mode.
class SubmitGemScreen extends StatefulWidget {
  final Gem? gem;
  const SubmitGemScreen({super.key, this.gem});

  bool get isEditing => gem != null;

  @override
  State<SubmitGemScreen> createState() => _SubmitGemScreenState();
}

class _SubmitGemScreenState extends State<SubmitGemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final _locationService = LocationService();

  // Constructed lazily inside methods (not as a field): building it touches
  // FirebaseStorage.instance, which must not run during State construction or
  // the whole screen can fail to mount and render blank.
  MediaUploadService get _media => MediaUploadService();

  GemCategory _category = GemCategory.other;
  double? _lat;
  double? _lng;
  bool _preciseCaptured = false;
  bool _locating = false;

  /// Already-uploaded photo URLs kept from the gem being edited.
  final List<String> _existingUrls = [];

  /// Newly-picked local files to upload on save.
  final List<String> _photoPaths = [];

  late final TextEditingController _contactPhoneController;
  late final TextEditingController _contactWebsiteController;
  late final TextEditingController _promoTitleController;
  late final TextEditingController _promoDetailsController;
  late final TextEditingController _offerTitleController;
  late final TextEditingController _offerTextController;
  late GemListingKind _listingKind;
  GemBusinessType? _businessType;

  bool _submitting = false;

  int get _totalPhotos => _existingUrls.length + _photoPaths.length;

  @override
  void initState() {
    super.initState();
    final gem = widget.gem;
    if (gem != null) {
      _nameController.text = gem.name;
      _summaryController.text = gem.summary;
      _descriptionController.text = gem.description;
      _locationController.text = gem.address;
      _category = gem.category;
      _lat = gem.latitude;
      _lng = gem.longitude;
      _preciseCaptured = gem.latitude != 0 || gem.longitude != 0;
      _existingUrls.addAll(gem.imageUrls.where((u) => u.isNotEmpty));
    }
    _listingKind = gem?.listingKind ?? GemListingKind.community;
    _businessType = gem?.businessType;
    _contactPhoneController = TextEditingController(text: gem?.contactPhone ?? '');
    _contactWebsiteController = TextEditingController(text: gem?.contactWebsite ?? '');
    _promoTitleController = TextEditingController(text: gem?.promoTitle ?? '');
    _promoDetailsController = TextEditingController(text: gem?.promoDetails ?? '');
    _offerTitleController = TextEditingController(text: gem?.offerTitle ?? '');
    _offerTextController = TextEditingController(text: gem?.offerText ?? '');
  }

  bool get _isBusiness => _listingKind == GemListingKind.business;

  bool get _isPremium =>
      context.read<SubscriptionProvider>().isSubscribed;

  Future<void> _openPaywall() async {
    await context.push<bool>('/paywall');
  }

  Future<void> _selectListingKind(GemListingKind kind) async {
    if (widget.gem?.listingKind == GemListingKind.business &&
        kind == GemListingKind.community) {
      return;
    }
    if (kind == GemListingKind.business && !_isPremium) {
      await _openPaywall();
      if (!mounted || !_isPremium) return;
    }
    setState(() => _listingKind = kind);
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactPhoneController.dispose();
    _contactWebsiteController.dispose();
    _promoTitleController.dispose();
    _promoDetailsController.dispose();
    _offerTitleController.dispose();
    _offerTextController.dispose();
    super.dispose();
  }

  Future<void> _usePreciseLocation() async {
    final l10n = AppLocalizations.of(context)!;
    if (_locating) return;
    setState(() => _locating = true);
    final coords =
        await _locationService.getCurrentLocation(requestPermission: true);
    if (!mounted) return;
    setState(() => _locating = false);
    if (coords != null) {
      setState(() {
        _lat = coords.lat;
        _lng = coords.lng;
        _preciseCaptured = true;
      });
      _snack(l10n.gemLocationCaptured);
    } else {
      await _showLocationUnavailable(l10n);
    }
  }

  Future<void> _showLocationUnavailable(AppLocalizations l10n) async {
    final permanentlyDenied = await _locationService.isPermanentlyDenied();
    if (!mounted) return;
    if (permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotGetLocation),
          action: SnackBarAction(
            label: l10n.openSettings,
            onPressed: _locationService.openAppSettings,
          ),
        ),
      );
    } else {
      _snack(l10n.couldNotGetLocation);
    }
  }

  Future<void> _addPhoto() async {
    if (_totalPhotos >= GemService.maxGemPhotos) return;
    final path = await _media.pickImage(fromCamera: false);
    if (path == null || !mounted) return;
    setState(() => _photoPaths.add(path));
  }

  void _removeNewPhoto(int index) {
    setState(() => _photoPaths.removeAt(index));
  }

  void _removeExistingPhoto(int index) {
    setState(() => _existingUrls.removeAt(index));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Resolve a location: prefer the precise pin, otherwise geocode the text.
    double? lat = _lat;
    double? lng = _lng;
    String city = '';
    String state = '';
    final typed = _locationController.text.trim();
    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      final place = resolvePlaceCoordinates(typed);
      if (place == null) {
        _snack(l10n.gemLocationRequired);
        return;
      }
      lat = place.lat;
      lng = place.lng;
      city = place.city;
      state = place.state;
    } else {
      final place = resolvePlaceCoordinates(typed);
      if (place != null) {
        city = place.city;
        state = place.state;
      }
    }

    final auth = context.read<AuthProvider>();
    final service = context.read<GemService>();
    if (!auth.isLoggedIn || auth.isGuest || auth.user == null) {
      _snack(l10n.gemsSignInToAdd);
      return;
    }

    if (_isBusiness && !_isPremium) {
      await _openPaywall();
      if (!mounted || !_isPremium) return;
    }

    setState(() => _submitting = true);
    try {
      // Reuse the existing id when editing so photos land in the same folder
      // and the same document is overwritten.
      final gemId = widget.gem?.id ?? const Uuid().v4();

      // Community listings don't add photos from this form. Existing photos
      // on a legacy community gem are kept by GemService.updateGem.
      final imageUrls = <String>[..._existingUrls];
      if (_isBusiness) for (var i = 0; i < _photoPaths.length; i++) {
        try {
          final url = await _media.uploadGemPhoto(
            gemId: gemId,
            localPath: _photoPaths[i],
            slot: imageUrls.length,
          );
          imageUrls.add(url);
        } catch (_) {
          // Skip a failed photo rather than blocking the whole submission.
        }
      }

      final GemWriteResult result;
      if (widget.isEditing) {
        result = await service.updateGem(
          gemId: gemId,
          requestingUserId: auth.user!.id,
          isAdmin: auth.isAdmin,
          name: _nameController.text,
          category: _category,
          summary: _summaryController.text,
          description: _descriptionController.text,
          latitude: lat,
          longitude: lng,
          address: typed,
          city: city,
          state: state,
          imageUrls: imageUrls,
          listingKind: _listingKind,
          contactPhone: _blankToNull(_contactPhoneController.text),
          clearContactPhone: _contactPhoneController.text.trim().isEmpty,
          contactWebsite: _blankToNull(_contactWebsiteController.text),
          clearContactWebsite: _contactWebsiteController.text.trim().isEmpty,
          promoTitle: _blankToNull(_promoTitleController.text),
          clearPromoTitle: _promoTitleController.text.trim().isEmpty,
          promoDetails: _blankToNull(_promoDetailsController.text),
          clearPromoDetails: _promoDetailsController.text.trim().isEmpty,
          businessType: _businessType,
          clearBusinessType: _businessType == null,
          offerTitle: _blankToNull(_offerTitleController.text),
          clearOfferTitle: _offerTitleController.text.trim().isEmpty,
          offerText: _blankToNull(_offerTextController.text),
          clearOfferText: _offerTextController.text.trim().isEmpty,
        );
      } else {
        result = await service.createGem(
          creatorId: auth.user!.id,
          creatorName: auth.user!.displayName,
          name: _nameController.text,
          category: _category,
          summary: _summaryController.text,
          description: _descriptionController.text,
          latitude: lat,
          longitude: lng,
          address: typed,
          city: city,
          state: state,
          imageUrls: imageUrls,
          listingKind: _listingKind,
          contactPhone: _blankToNull(_contactPhoneController.text),
          contactWebsite: _blankToNull(_contactWebsiteController.text),
          promoTitle: _blankToNull(_promoTitleController.text),
          promoDetails: _blankToNull(_promoDetailsController.text),
          businessType: _businessType,
          offerTitle: _blankToNull(_offerTitleController.text),
          offerText: _blankToNull(_offerTextController.text),
        );
      }

      if (!mounted) return;
      if (result.isRejected) {
        setState(() => _submitting = false);
        _snack(widget.isEditing
            ? l10n.gemUpdateRejected
            : l10n.gemSubmitRejected);
        return;
      }
      _snack(widget.isEditing ? l10n.gemUpdateSuccess : l10n.gemSubmitSuccess);
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(l10n.gemSubmitError);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final editing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l10n.gemsEditTitle : l10n.gemsAddTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            children: [
              _buildForkChooser(l10n, colors),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.gemNameLabel,
                  hintText: l10n.gemNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.gemNameRequired : null,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildCategoryPicker(l10n, colors),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _summaryController,
                textInputAction: TextInputAction.next,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: l10n.gemSummaryLabel,
                  hintText: l10n.gemSummaryHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.gemSummaryRequired
                    : null,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _buildLocationSection(l10n, colors),
              if (_isBusiness) ...[
                const SizedBox(height: AppTheme.spacingMd),
                _buildBusinessTypePicker(l10n),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: l10n.gemDescriptionLabel,
                    hintText: l10n.gemDescriptionHint,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _contactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.gemContactPhoneLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _contactWebsiteController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: l10n.gemContactWebsiteLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _promoTitleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.gemPromoTitleLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _promoDetailsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.gemPromoDetailsLabel,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _offerTitleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.gemOfferTitleLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _offerTextController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.gemOfferTextLabel,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                _buildPhotosSection(l10n, colors),
              ],
              const SizedBox(height: AppTheme.spacingLg),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(editing ? Icons.save_rounded : Icons.send_rounded),
                label: Text(_submitting
                    ? (editing ? l10n.gemUpdating : l10n.gemSubmitting)
                    : (editing ? l10n.gemUpdate : l10n.gemSubmit)),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildForkChooser(AppLocalizations l10n, ColorScheme colors) {
    final lockedBusiness = widget.gem?.listingKind == GemListingKind.business;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GemForkOption(
          title: l10n.gemForkShareTitle,
          body: l10n.gemForkShareBody,
          selected: !_isBusiness,
          onTap: lockedBusiness
              ? null
              : () => _selectListingKind(GemListingKind.community),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _GemForkOption(
          title: l10n.gemForkPromoteTitle,
          body: l10n.gemForkPromoteBody,
          selected: _isBusiness,
          locked: !_isPremium,
          lockedLabel: l10n.gemForkPromoteLocked,
          onTap: () => _selectListingKind(GemListingKind.business),
        ),
        if (!_isBusiness)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSm),
            child: Text(
              'Keep the summary short and skip promo links or offers — those belong on a business listing and will be flagged on a free post.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _buildBusinessTypePicker(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.gemBusinessTypeLabel,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppTheme.spacingXs),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('Not specified'),
              selected: _businessType == null,
              onSelected: (_) => setState(() => _businessType = null),
            ),
            for (final type in GemBusinessType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: _businessType == type,
                onSelected: (_) => setState(() => _businessType = type),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryPicker(AppLocalizations l10n, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.gemCategoryLabel,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppTheme.spacingXs),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: 4,
          children: [
            for (final c in GemCategory.values)
              ChoiceChip(
                avatar: Icon(c.icon, size: 16),
                label: Text(c.label),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection(AppLocalizations l10n, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.gemLocationLabel,
            hintText: l10n.gemLocationHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _locating ? null : _usePreciseLocation,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_preciseCaptured
                    ? Icons.check_circle_rounded
                    : Icons.my_location_rounded),
            label: Text(_preciseCaptured
                ? l10n.gemLocationCaptured
                : l10n.gemUsePreciseLocation),
          ),
        ),
        if (!_preciseCaptured)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.gemLocationNeeded,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotosSection(AppLocalizations l10n, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.gemPhotosLabel,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 8),
            Text('(${l10n.gemPhotosOptional})',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Already-uploaded photos (edit mode).
              for (var i = 0; i < _existingUrls.length; i++)
                _photoTile(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Image.network(
                      _existingUrls[i],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 96,
                        height: 96,
                        color: colors.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_outlined,
                            color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                  onRemove: () => _removeExistingPhoto(i),
                ),
              // Newly-picked local files.
              for (var i = 0; i < _photoPaths.length; i++)
                _photoTile(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: localMediaImage(
                      path: _photoPaths[i],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  onRemove: () => _removeNewPhoto(i),
                ),
              if (_totalPhotos < GemService.maxGemPhotos)
                InkWell(
                  onTap: _addPhoto,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outline),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            color: colors.onSurfaceVariant),
                        const SizedBox(height: 4),
                        Text(l10n.gemAddPhoto,
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoTile({required Widget child, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GemForkOption extends StatelessWidget {
  const _GemForkOption({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    this.locked = false,
    this.lockedLabel,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback? onTap;
  final bool locked;
  final String? lockedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall),
                  ),
                  if (locked && !selected)
                    Icon(Icons.lock_outline,
                        size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 6),
              Text(body, style: theme.textTheme.bodySmall),
              if (locked && lockedLabel != null && !selected) ...[
                const SizedBox(height: 6),
                Text(
                  lockedLabel!,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

