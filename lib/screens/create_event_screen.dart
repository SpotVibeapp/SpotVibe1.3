import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/media_urls.dart';
import '../data/pricing.dart';
import '../l10n/app_localizations.dart';
import '../l10n/category_labels.dart';
import '../models/user_event.dart';
import '../providers/auth_provider.dart';
import '../providers/create_event_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_events_provider.dart';
import '../repositories/user_event_repository.dart';
import '../services/ai_moderation_service.dart';
import '../services/media_upload_service.dart';
import '../services/tour_service.dart';
import '../services/user_event_service.dart';
import '../theme/theme.dart';
import '../widgets/events/ai_promo_image_dialog.dart';
import '../widgets/events/event_creation_guide.dart';
import '../widgets/events/event_media_editor.dart';
import '../widgets/events/event_poster_studio.dart';

export '../models/user_event.dart' show RecurringType;

class CreateEventScreen extends StatefulWidget {
  final UserCreatedEvent? editingEvent;
  const CreateEventScreen({super.key, this.editingEvent});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  static const _eventCreationGuideTourId = 'event_creation_guide';

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
  final _photoUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _chatLinkController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 21, minute: 0);
  String _selectedCategory = 'Music';
  bool _isPremiumListing = false;
  String? _moderationError;
  late final String _eventMediaId;
  String? _localCoverPath;
  final List<String> _localPhotoPaths = [];
  final List<String> _remotePhotoUrls = [];
  final List<String> _localVideoPaths = [];
  final List<String> _remoteVideoUrls = [];
  int _initialPhotoCount = 0;
  int _initialVideoCount = 0;
  bool _aiGeneratedCover = false;
  bool _uploadingMedia = false;
  bool _hasCheckedEventCreationGuide = false;

  // ── Premium fields ────────────────────────────────────────────────────────
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
    _eventMediaId = widget.editingEvent?.id ?? const Uuid().v4();
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
      final savedPhotos = e.allImageUrls;
      _imageUrlController.text =
          savedPhotos.isEmpty ? e.imageUrl : savedPhotos.first;
      _remotePhotoUrls.addAll(savedPhotos.skip(1));
      _remoteVideoUrls.addAll(e.allVideoUrls);
      _initialPhotoCount = savedPhotos.length;
      _initialVideoCount = e.allVideoUrls.length;
      // New links are added to the gallery explicitly. Existing legacy links
      // are already represented in _remoteVideoUrls above.
      _videoUrlController.clear();
      _mapLinkController.text = e.mapLink ?? '';
      _chatLinkController.text = e.chatLink ?? '';
      _selectedDate = e.dateTime;
      _selectedTime = TimeOfDay(hour: e.dateTime.hour, minute: e.dateTime.minute);
      // Older listings did not store an end time. Show a clear editable
      // three-hour suggestion so the organizer can publish the actual end.
      final endDateTime = e.endDateTime ?? e.dateTime.add(const Duration(hours: 3));
      _selectedEndDate = endDateTime;
      _selectedEndTime = TimeOfDay(
        hour: endDateTime.hour,
        minute: endDateTime.minute,
      );
      _selectedCategory = e.category;
      _isPremiumListing = e.isPremiumListing;
      // Restore Premium fields if the event was created on Premium
      _isCreatorPro = e.isCreatorPro;
      _recurringType = e.recurringType;
      _contactPhoneController.text = e.contactPhone ?? '';
      _contactWebsiteController.text = e.contactWebsite ?? '';
      _contactSocialController.text = e.contactSocial ?? '';
      _brandColorController.text = e.brandColor ?? '';
      _brandLogoController.text = e.brandLogoUrl ?? '';
    }
    // Pro subscribers get unlimited creation — pre-confirm for them after first frame.
    // A first-time creator also sees the plan-aware guide once the form exists.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final sub = context.read<SubscriptionProvider>();
      if (sub.isSubscribed) {
        setState(() {
          _isCreatorPro = true;
        });
      }
      await _maybeShowEventCreationGuide();
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
    _photoUrlController.dispose();
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

  DateTime get _combinedEndDateTime => DateTime(
        _selectedEndDate.year,
        _selectedEndDate.month,
        _selectedEndDate.day,
        _selectedEndTime.hour,
        _selectedEndTime.minute,
      );

  bool _isSameCalendarDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  void _ensureEndFollowsStart() {
    if (_combinedEndDateTime.isAfter(_combinedDateTime)) return;
    final adjusted = _combinedDateTime.add(const Duration(hours: 3));
    _selectedEndDate = adjusted;
    _selectedEndTime = TimeOfDay(
      hour: adjusted.hour,
      minute: adjusted.minute,
    );
  }

  double? get _parsedCost {
    final text = _costController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll('\$', ''));
  }

  bool get _hasCover =>
      _localCoverPath != null || _imageUrlController.text.trim().isNotEmpty;

  int get _photoCount =>
      (_hasCover ? 1 : 0) + _remotePhotoUrls.length + _localPhotoPaths.length;

  int get _videoCount => _remoteVideoUrls.length + _localVideoPaths.length;

  EventMediaAllowance get _mediaAllowance => eventMediaAllowance(
        isPremium: context.read<SubscriptionProvider>().isSubscribed,
        isAdmin: context.read<AuthProvider>().isAdmin,
      );

  int get _photoAllowance {
    final limit = _mediaAllowance.maxPhotos;
    // Existing organizers do not lose media they published while Premium.
    return _isEditing && _initialPhotoCount > limit
        ? _initialPhotoCount
        : limit;
  }

  int get _videoAllowance {
    final limit = _mediaAllowance.maxVideos;
    return _isEditing && _initialVideoCount > limit
        ? _initialVideoCount
        : limit;
  }

  Future<void> _handleMediaLimit({required bool photos}) async {
    final isAtAbsoluteLimit = photos
        ? _photoAllowance >= MediaUploadService.maxEventPhotos
        : _videoAllowance >= MediaUploadService.maxEventVideos;
    if (!_mediaAllowance.hasFullGallery && !isAtAbsoluteLimit) {
      await _openPaywall();
      return;
    }
    _showMediaLimit(photos: photos);
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  void _showMediaLimit({required bool photos}) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          photos
              ? l10n.mediaPhotoLimit(MediaUploadService.maxEventPhotos)
              : l10n.mediaVideoLimit(MediaUploadService.maxEventVideos),
        ),
      ),
    );
  }

  void _clearCover() {
    setState(() {
      void promoteNextPhoto() {
        if (_remotePhotoUrls.isNotEmpty) {
          // Keep media order intuitive: the next gallery photo becomes cover.
          _imageUrlController.text = _remotePhotoUrls.removeAt(0);
        } else if (_localPhotoPaths.isNotEmpty) {
          _localCoverPath = _localPhotoPaths.removeAt(0);
        }
      }

      // If a new local cover temporarily replaced a URL cover, reveal the URL
      // again instead of silently discarding it. Otherwise promote the next
      // gallery item so an event never loses its first photo unexpectedly.
      if (_localCoverPath != null) {
        _localCoverPath = null;
        if (_imageUrlController.text.trim().isEmpty) promoteNextPhoto();
      } else {
        _imageUrlController.clear();
        promoteNextPhoto();
      }
      _aiGeneratedCover = false;
    });
  }

  Future<void> _addPhotos({required bool fromCamera}) async {
    final remaining = _photoAllowance - _photoCount;
    if (remaining <= 0) {
      await _handleMediaLimit(photos: true);
      return;
    }

    try {
      final media = MediaUploadService();
      final paths = <String>[];
      if (fromCamera) {
        final path = await media.pickImage(fromCamera: true);
        if (path != null) paths.add(path);
      } else {
        paths.addAll(await media.pickImages(maxImages: remaining));
      }
      if (paths.isEmpty || !mounted) return;

      setState(() {
        for (final path in paths) {
          if (!_hasCover) {
            _localCoverPath = path;
            _imageUrlController.clear();
            _aiGeneratedCover = false;
          } else {
            _localPhotoPaths.add(path);
          }
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _addVideo({required bool fromCamera}) async {
    if (_videoCount >= _videoAllowance) {
      await _handleMediaLimit(photos: false);
      return;
    }
    try {
      final path = await MediaUploadService().pickVideo(fromCamera: fromCamera);
      if (path == null || !mounted) return;
      setState(() => _localVideoPaths.add(path));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _addPhotoLink() async {
    final url = _photoUrlController.text.trim();
    if (url.isEmpty) return;
    if (_photoCount >= _photoAllowance) {
      await _handleMediaLimit(photos: true);
      return;
    }
    if (!_isHttpUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.validPhotoUrl)),
      );
      return;
    }
    setState(() {
      if (!_hasCover) {
        _imageUrlController.text = url;
      } else if (!_remotePhotoUrls.contains(url)) {
        _remotePhotoUrls.add(url);
      }
      _photoUrlController.clear();
    });
  }

  Future<void> _addVideoLink() async {
    final url = _videoUrlController.text.trim();
    if (url.isEmpty) return;
    if (_videoCount >= _videoAllowance) {
      await _handleMediaLimit(photos: false);
      return;
    }
    if (!_isHttpUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.validVideoUrl)),
      );
      return;
    }
    setState(() {
      if (!_remoteVideoUrls.contains(url)) _remoteVideoUrls.add(url);
      _videoUrlController.clear();
    });
  }

  List<EventMediaDraftItem> _additionalPhotoItems(AppLocalizations l10n) {
    final items = <EventMediaDraftItem>[];
    final firstPhotoNumber = _hasCover ? 2 : 1;
    for (var index = 0; index < _remotePhotoUrls.length; index++) {
      final itemIndex = index;
      items.add(EventMediaDraftItem(
        source: _remotePhotoUrls[itemIndex],
        isLocal: false,
        label: l10n.photoNumber(firstPhotoNumber + itemIndex),
        onRemove: () => setState(() => _remotePhotoUrls.removeAt(itemIndex)),
      ));
    }
    for (var index = 0; index < _localPhotoPaths.length; index++) {
      final itemIndex = index;
      items.add(EventMediaDraftItem(
        source: _localPhotoPaths[itemIndex],
        isLocal: true,
        label: l10n.photoNumber(
          firstPhotoNumber + _remotePhotoUrls.length + itemIndex,
        ),
        onRemove: () => setState(() => _localPhotoPaths.removeAt(itemIndex)),
      ));
    }
    return items;
  }

  List<EventMediaDraftItem> _videoItems(AppLocalizations l10n) {
    final items = <EventMediaDraftItem>[];
    for (var index = 0; index < _remoteVideoUrls.length; index++) {
      final itemIndex = index;
      items.add(EventMediaDraftItem(
        source: _remoteVideoUrls[itemIndex],
        isLocal: false,
        label: l10n.videoNumber(itemIndex + 1),
        onRemove: () => setState(() => _remoteVideoUrls.removeAt(itemIndex)),
      ));
    }
    for (var index = 0; index < _localVideoPaths.length; index++) {
      final itemIndex = index;
      items.add(EventMediaDraftItem(
        source: _localVideoPaths[itemIndex],
        isLocal: true,
        label: l10n.videoNumber(_remoteVideoUrls.length + itemIndex + 1),
        onRemove: () => setState(() => _localVideoPaths.removeAt(itemIndex)),
      ));
    }
    return items;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        // A normal one-day event keeps its end on the newly selected start
        // date. Multi-day events keep their separately chosen end date.
        final endWasOnStartDate =
            _isSameCalendarDate(_selectedEndDate, _selectedDate);
        _selectedDate = picked;
        if (endWasOnStartDate) _selectedEndDate = picked;
        _ensureEndFollowsStart();
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _ensureEndFollowsStart();
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedEndDate = picked);
  }

  Future<void> _pickEndTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _selectedEndTime);
    if (picked != null) setState(() => _selectedEndTime = picked);
  }

  Future<void> _pickCover({required bool camera}) async {
    try {
      final path = await MediaUploadService().pickImage(fromCamera: camera);
      if (path != null && mounted) {
        setState(() {
          _localCoverPath = path;
          _aiGeneratedCover = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _generateAiPromoImage() async {
    final auth = context.read<AuthProvider>();
    final subscription = context.read<SubscriptionProvider>();
    if (!auth.isAdmin && !subscription.isSubscribed) {
      final upgraded = await context.push<bool>('/paywall');
      if (upgraded != true || !mounted) return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final venue = _locationController.text.trim();
    if (title.isEmpty || description.isEmpty || venue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add an event title, description, and venue before generating a promo image.'),
        ),
      );
      return;
    }

    final result = await showAiPromoImageDialog(
      context,
      eventId: _eventMediaId,
      title: title,
      description: description,
      category: _selectedCategory,
      venue: venue,
    );
    if (result == null || !mounted) return;
    setState(() {
      _localCoverPath = null;
      _imageUrlController.text = result.imageUrl;
      _aiGeneratedCover = true;
    });
  }

  Future<void> _openPosterStudio() async {
    final title = _titleController.text.trim();
    final venue = _locationController.text.trim();
    if (title.isEmpty || venue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.posterTitleVenueRequired),
        ),
      );
      return;
    }

    // Poster Studio is a separate share asset. It deliberately leaves the
    // selected photo or AI artwork as the in-app event cover.
    await showEventPosterStudio(
      context,
      details: EventPosterDetails(
        title: title,
        dateTime: _combinedDateTime,
        endDateTime: _combinedEndDateTime,
        venue: venue,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        cost: _parsedCost,
        category: _selectedCategory,
        backgroundImageUrl: _imageUrlController.text.trim(),
        localBackgroundPath: _localCoverPath,
      ),
    );
  }

  Future<void> _openPaywall() async {
    final result = await context.push<bool>('/paywall');
    if (result == true && mounted) {
      setState(() {
        _isCreatorPro = true;
      });
    }
  }

  Future<void> _maybeShowEventCreationGuide() async {
    if (_isEditing || _hasCheckedEventCreationGuide) return;
    _hasCheckedEventCreationGuide = true;

    final alreadySeen = await TourService.isSeen(_eventCreationGuideTourId);
    if (!mounted || alreadySeen) return;

    await _openEventCreationGuide();
    if (mounted) {
      await TourService.markSeen(_eventCreationGuideTourId);
    }
  }

  Future<void> _openEventCreationGuide() {
    final sub = context.read<SubscriptionProvider>();
    final auth = context.read<AuthProvider>();
    return showEventCreationGuide(
      context,
      isPremium: sub.isSubscribed,
      isAdmin: auth.isAdmin,
      onUpgrade: () {
        _openPaywall();
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    if (!_combinedEndDateTime.isAfter(_combinedDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.endTimeMustBeAfterStart)),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final subCheck = context.read<SubscriptionProvider>();
    // Admins post unlimited official events without the free-plan cap.
    if (!_isEditing && !subCheck.isSubscribed && !auth.isAdmin) {
      final uid = auth.user?.id;
      if (uid != null) {
        final mine = await context.read<UserEventRepository>().getEventsForUser(uid);
        final active = countActiveUserEvents(mine.map((e) => e.dateTime));
        if (!canPostAnotherFreeEvent(active, isPremium: false)) {
          if (!mounted) return;
          final upgrade = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.freePlanLimit),
              content: Text(
                l10n.freePlanLimitBody(l10n.trialLabel),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.notNow)),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.goPremium)),
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
      setState(() => _moderationError = l10n.policyViolation(
            modResult.category ?? l10n.content,
            modResult.reason ?? '',
          ));
      return;
    }
    if (modResult.isFlagged) {
      setState(() => _moderationError = l10n.contentWarning(
            modResult.category ?? l10n.content,
            modResult.reason ?? '',
          ));
    }
    // ────────────────────────────────────────────────────────────────────────

    var coverUrl = _imageUrlController.text.trim();
    final pendingPhotoUrl = _photoUrlController.text.trim();
    final pendingVideoUrl = _videoUrlController.text.trim();
    if (pendingPhotoUrl.isNotEmpty && !_isHttpUrl(pendingPhotoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validPhotoUrl)),
      );
      return;
    }
    if (pendingVideoUrl.isNotEmpty && !_isHttpUrl(pendingVideoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validVideoUrl)),
      );
      return;
    }
    var photoUrls = normalizeMediaUrls([
      coverUrl,
      ..._remotePhotoUrls,
      pendingPhotoUrl,
    ]).toList();
    var videoUrls = normalizeMediaUrls([
      ..._remoteVideoUrls,
      pendingVideoUrl,
    ]).toList();

    // A replacement local cover occupies one slot even if an old URL remains
    // in the controller until publishing.
    final estimatedPhotoCount =
        (_localCoverPath != null || coverUrl.isNotEmpty ? 1 : 0) +
            _remotePhotoUrls.length +
            (pendingPhotoUrl.isNotEmpty &&
                    pendingPhotoUrl != coverUrl &&
                    !_remotePhotoUrls.contains(pendingPhotoUrl)
                ? 1
                : 0) +
            _localPhotoPaths.length;
    if (estimatedPhotoCount > _photoAllowance) {
      await _handleMediaLimit(photos: true);
      return;
    }
    if (videoUrls.length + _localVideoPaths.length > _videoAllowance) {
      await _handleMediaLimit(photos: false);
      return;
    }

    if (_localCoverPath != null ||
        _localPhotoPaths.isNotEmpty ||
        _localVideoPaths.isNotEmpty) {
      setState(() => _uploadingMedia = true);
      try {
        final media = MediaUploadService();
        if (_localCoverPath != null) {
          coverUrl = await media.uploadEventImage(
            eventId: _eventMediaId,
            localPath: _localCoverPath!,
          );
        }
        photoUrls = normalizeMediaUrls([
          coverUrl,
          ..._remotePhotoUrls,
          pendingPhotoUrl,
        ]).toList();
        for (final path in _localPhotoPaths) {
          photoUrls.add(await media.uploadEventPhoto(
            eventId: _eventMediaId,
            localPath: path,
            slot: photoUrls.length,
          ));
        }
        for (final path in _localVideoPaths) {
          videoUrls.add(await media.uploadAdditionalEventVideo(
            eventId: _eventMediaId,
            localPath: path,
            slot: videoUrls.length,
          ));
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _uploadingMedia = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        return;
      }
      if (mounted) setState(() => _uploadingMedia = false);
    }

    photoUrls = normalizeMediaUrls(photoUrls).toList();
    videoUrls = normalizeMediaUrls(videoUrls).toList();
    coverUrl = photoUrls.isEmpty ? '' : photoUrls.first;
    final videoUrl = videoUrls.isEmpty ? null : videoUrls.first;

    final provider = context.read<CreateEventProvider>();
    final result = await provider.submit(
      id: _eventMediaId,
      title: _titleController.text,
      description: _descriptionController.text,
      dateTime: _combinedDateTime,
      endDateTime: _combinedEndDateTime,
      location: _locationController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipController.text,
      cost: _parsedCost,
      imageUrl: coverUrl,
      imageUrls: photoUrls,
      videoUrl: videoUrl,
      videoUrls: videoUrls,
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
        SnackBar(content: Text(_isEditing ? l10n.eventUpdated : l10n.eventCreated)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreateEventProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final auth = context.watch<AuthProvider>();
    final mediaAllowance = eventMediaAllowance(
      isPremium: sub.isSubscribed,
      isAdmin: auth.isAdmin,
    );
    final photoAllowance = _photoAllowance;
    final videoAllowance = _videoAllowance;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editEvent : l10n.createEvent),
        actions: [
          IconButton(
            tooltip: l10n.eventCreationGuideTooltip,
            onPressed: _openEventCreationGuide,
            icon: const Icon(Icons.help_outline_rounded),
          ),
          if (provider.isSubmitting || _uploadingMedia)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(onPressed: _submit, child: Text(_isEditing ? l10n.save : l10n.publish)),
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
              _SectionHeader(title: l10n.eventPublishing),
              _CreationAccessSelector(
                isSubscribed: sub.isSubscribed,
                isAdmin: auth.isAdmin,
                onUpgrade: _openPaywall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              EventCreationGuideCard(onOpen: _openEventCreationGuide),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            _SectionHeader(title: l10n.eventDetails),
            _FormField(
              controller: _titleController,
              label: l10n.eventTitle,
              hint: l10n.eventTitleHint,
              icon: Icons.title_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.titleRequired : null,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _descriptionController,
              label: l10n.description,
              hint: l10n.descriptionHint,
              icon: Icons.description_rounded,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.descriptionRequired : null,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Category picker
            _CategoryDropdown(
              value: _selectedCategory,
              categories: _categories,
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            _SectionHeader(title: l10n.dateAndTime),
            Text(
              l10n.eventStarts,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.calendar_month_rounded,
                    label: l10n.date,
                    value: '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.access_time_rounded,
                    label: l10n.time,
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              l10n.eventEnds,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.event_available_rounded,
                    label: l10n.date,
                    value: '${_selectedEndDate.month}/${_selectedEndDate.day}/${_selectedEndDate.year}',
                    onTap: _pickEndDate,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.timer_off_rounded,
                    label: l10n.time,
                    value: _selectedEndTime.format(context),
                    onTap: _pickEndTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              l10n.endTimeHint,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            _SectionHeader(title: l10n.locationSection),
            _FormField(
              controller: _locationController,
              label: l10n.venueName,
              hint: l10n.venueNameHint,
              icon: Icons.location_on_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.venueNameRequired : null,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _addressController,
              label: l10n.streetAddress,
              hint: l10n.streetAddressHint,
              icon: Icons.home_rounded,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _FormField(controller: _cityController, label: l10n.city, hint: l10n.cityHint, icon: Icons.location_city_rounded),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _FormField(controller: _stateController, label: l10n.state, hint: l10n.stateHint, icon: Icons.map_rounded),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _FormField(controller: _zipController, label: l10n.zip, hint: l10n.zipHint, icon: Icons.numbers_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _mapLinkController,
              label: l10n.mapLinkOptional,
              hint: 'https://maps.google.com/...',
              icon: Icons.map_outlined,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _costController,
              label: l10n.ticketPriceLabel,
              hint: '0.00',
              icon: Icons.attach_money_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = double.tryParse(v.replaceAll('\$', ''));
                if (parsed == null || parsed < 0) return l10n.enterValidPrice;
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),

            _SectionHeader(title: l10n.extras),
            _MediaPickRow(
              label: 'Cover photo',
              subtitle: _localCoverPath != null
                  ? 'Photo selected'
                  : (_aiGeneratedCover
                      ? 'AI-generated background selected — review before publishing'
                      : (_imageUrlController.text.isNotEmpty
                          ? 'Using image URL'
                          : 'Upload a photo of this event or venue')),
              icon: Icons.add_photo_alternate_rounded,
              preview: _localCoverPath != null && !kIsWeb
                  ? Image.file(File(_localCoverPath!), fit: BoxFit.cover)
                  : (_imageUrlController.text.isNotEmpty
                      ? Image.network(_imageUrlController.text, fit: BoxFit.cover)
                      : null),
              onLibrary: () => _pickCover(camera: false),
              onCamera: () => _pickCover(camera: true),
              onClear: (_localCoverPath == null && _imageUrlController.text.isEmpty)
                  ? null
                  : _clearCover,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            OutlinedButton.icon(
              onPressed: _generateAiPromoImage,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate AI promo background'),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            FilledButton.tonalIcon(
              onPressed: _uploadingMedia ? null : _openPosterStudio,
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: Text(l10n.createSharePoster),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              l10n.posterExactDetails,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (!mediaAllowance.hasFullGallery) ...[
              _MediaGalleryUpgradeBanner(
                description: l10n.mediaPremiumPerk,
                actionLabel: l10n.unlockMediaGallery,
                onUpgrade: _openPaywall,
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
            EventMediaEditor(
              kind: EventMediaKind.photo,
              title: l10n.eventPhotosCount(
                _photoCount,
                photoAllowance,
              ),
              subtitle: mediaAllowance.hasFullGallery
                  ? l10n.photoGalleryHint
                  : l10n.photoGalleryFreeHint,
              emptyLabel: l10n.noAdditionalPhotos,
              libraryLabel: l10n.library,
              cameraLabel: l10n.camera,
              items: _additionalPhotoItems(l10n),
              onLibrary: _photoCount < MediaUploadService.maxEventPhotos
                  ? () => _addPhotos(fromCamera: false)
                  : null,
              onCamera: _photoCount < MediaUploadService.maxEventPhotos
                  ? () => _addPhotos(fromCamera: true)
                  : null,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _FormField(
              controller: _photoUrlController,
              label: l10n.addPhotoUrl,
              hint: 'https://example.com/photo.jpg',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _photoCount < MediaUploadService.maxEventPhotos
                    ? _addPhotoLink
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addPhotoLink),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            EventMediaEditor(
              kind: EventMediaKind.video,
              title: l10n.eventVideosCount(
                _videoCount,
                videoAllowance,
              ),
              subtitle: mediaAllowance.hasFullGallery
                  ? l10n.videoGalleryHint
                  : l10n.videoGalleryFreeHint,
              emptyLabel: l10n.noVideosYet,
              libraryLabel: l10n.library,
              cameraLabel: l10n.camera,
              items: _videoItems(l10n),
              onLibrary: _videoCount < MediaUploadService.maxEventVideos
                  ? () => _addVideo(fromCamera: false)
                  : null,
              onCamera: _videoCount < MediaUploadService.maxEventVideos
                  ? () => _addVideo(fromCamera: true)
                  : null,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _FormField(
              controller: _videoUrlController,
              label: l10n.addVideoUrl,
              hint: 'https://youtube.com/watch?v=... or .mp4 link',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _videoCount < MediaUploadService.maxEventVideos
                    ? _addVideoLink
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addVideoLink),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            if (_uploadingMedia) ...[
              const SizedBox(height: AppTheme.spacingSm),
              const LinearProgressIndicator(),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Uploading media…',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _imageUrlController,
              label: l10n.eventImageUrl,
              hint: 'https://example.com/image.jpg',
              icon: Icons.image_rounded,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              controller: _chatLinkController,
              label: l10n.chatLink,
              hint: 'https://discord.gg/... or WhatsApp, Telegram link',
              icon: Icons.forum_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Premium section ──────────────────────────────────────────────
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
              onPressed: (provider.isSubmitting || _uploadingMedia) ? null : _submit,
              icon: const Icon(Icons.publish_rounded),
              label: Text(_isEditing
                  ? l10n.saveChanges
                  : sub.isSubscribed
                      ? l10n.publishPremium
                      : l10n.publishFree),
            ),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

// ── Premium section ────────────────────────────────────────────────────────────

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
    final l10n = AppLocalizations.of(context)!;

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
                  gradient: AppTheme.tealGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: appColors.creatorTeal.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                        Text(l10n.premium, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: AppTheme.spacingXs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: appColors.creatorTeal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          ),
                          child: Text(
                            l10n.perMonth('\$${kPremiumMonthlyPrice.toStringAsFixed(2)}'),
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
                      l10n.premiumFeaturesSubtitle,
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

    // Unlocked Premium fields
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
          decoration: BoxDecoration(
            gradient: AppTheme.tealGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: appColors.creatorTeal.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: AppTheme.iconSm),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                l10n.premiumFeaturesUnlocked,
                style: text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Recurring picker
        _SectionHeader(title: l10n.recurringSchedule),
        _RecurringPicker(value: recurringType, onChanged: onRecurringChanged, appColors: appColors, colors: colors, text: text),
        const SizedBox(height: AppTheme.spacingLg),

        // Contact info
        _SectionHeader(title: l10n.contactInfo),
        _FormField(controller: contactPhoneController, label: l10n.phoneOptional, hint: '+1 555-000-0000', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
        const SizedBox(height: AppTheme.spacingMd),
        _FormField(controller: contactWebsiteController, label: l10n.websiteOptional, hint: 'https://yoursite.com', icon: Icons.language_rounded, keyboardType: TextInputType.url),
        const SizedBox(height: AppTheme.spacingMd),
        _FormField(controller: contactSocialController, label: l10n.socialHandleOptional, hint: '@yourhandle or full URL', icon: Icons.alternate_email_rounded),
        const SizedBox(height: AppTheme.spacingLg),

        // Custom branding
        _SectionHeader(title: l10n.customBranding),
        _FormField(controller: brandColorController, label: l10n.brandAccentColor, hint: '#FF5733', icon: Icons.palette_rounded),
        const SizedBox(height: AppTheme.spacingMd),
        _FormField(controller: brandLogoController, label: l10n.brandLogoUrl, hint: 'https://yoursite.com/logo.png', icon: Icons.image_rounded, keyboardType: TextInputType.url),
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
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _RecurringOption(
          label: l10n.oneTime,
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
          label: l10n.weekly,
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
          label: l10n.monthly,
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

class _MediaPickRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Widget? preview;
  final VoidCallback onLibrary;
  final VoidCallback onCamera;
  final VoidCallback? onClear;

  const _MediaPickRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    this.preview,
    required this.onLibrary,
    required this.onCamera,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: SizedBox(
              width: 56,
              height: 56,
              child: preview ??
                  Container(
                    color: colors.primaryContainer,
                    child: Icon(icon, color: colors.primary),
                  ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.titleSmall),
                Text(subtitle, style: text.labelSmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Library',
            onPressed: onLibrary,
            icon: const Icon(Icons.photo_library_rounded),
          ),
          IconButton(
            tooltip: 'Camera',
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera_rounded),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Remove',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _MediaGalleryUpgradeBanner extends StatelessWidget {
  final String description;
  final String actionLabel;
  final VoidCallback onUpgrade;

  const _MediaGalleryUpgradeBanner({
    required this.description,
    required this.actionLabel,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.collections_rounded, color: colors.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
            ),
          ),
          TextButton(
            onPressed: onUpgrade,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

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
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
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
        labelText: AppLocalizations.of(context)!.category,
        prefixIcon: Icon(Icons.category_rounded, size: AppTheme.iconSm, color: colors.onSurfaceVariant),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(categoryLabel(context, c))))
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
  final bool isAdmin;
  final VoidCallback onUpgrade;

  const _CreationAccessSelector({
    required this.isSubscribed,
    this.isAdmin = false,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    if (isAdmin) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.brandViolet.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.brandViolet.withValues(alpha: 0.5),
            width: AppTheme.borderSelected,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: AppTheme.iconMd),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminAccess,
                    style: text.titleSmall?.copyWith(
                      color: AppTheme.brandViolet,
                    ),
                  ),
                  Text(
                    l10n.adminPostUnlimited,
                    style: text.labelSmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
                    l10n.premiumUnlimited,
                    style: text.titleSmall?.copyWith(color: appColors.proGold),
                  ),
                  Text(
                    l10n.premiumIncludes,
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
          Text(l10n.freePlan, style: text.titleSmall),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            l10n.freePlanBody,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          OutlinedButton.icon(
            onPressed: onUpgrade,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: Text(l10n.upgradeToPremium(
              l10n.perMonth('\$${kPremiumMonthlyPrice.toStringAsFixed(2)}'),
            )),
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
