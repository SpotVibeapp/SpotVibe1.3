import '../models/gem.dart';
import '../services/feature_flags.dart';

DateTime gemApprovedAt(Gem gem) => gem.approvedAt ?? gem.createdAt;

DateTime gemVisibleToFreeAt(Gem gem, {int delayHours = kDefaultGemEarlyAccessHours}) {
  if (gem.visibleToFreeAt != null) return gem.visibleToFreeAt!;
  return gemApprovedAt(gem).add(Duration(hours: delayHours));
}

/// Casual "share a spot" gems are visible to everyone immediately.
/// The early-access delay applies only to new business promo listings:
/// Premium viewers and the gem's creator see those immediately; everyone
/// else waits until [gemVisibleToFreeAt]. Hidden gems are never visible.
bool gemIsBusinessPromo(Gem gem) =>
    gem.listingKind == GemListingKind.business ||
    gem.listingTier == GemListingTier.promoted;

bool gemVisibleToViewer(
  Gem gem, {
  required bool isPremium,
  String? viewerId,
  int delayHours = kDefaultGemEarlyAccessHours,
  DateTime? now,
}) {
  if (gem.hidden) return false;
  if (isPremium) return true;
  if (viewerId != null && viewerId.isNotEmpty && viewerId == gem.creatorId) {
    return true;
  }
  if (!gemIsBusinessPromo(gem)) return true;
  final clock = now ?? DateTime.now();
  return !clock.isBefore(gemVisibleToFreeAt(gem, delayHours: delayHours));
}

List<Gem> filterGemsForViewer(
  Iterable<Gem> gems, {
  required bool isPremium,
  String? viewerId,
  int delayHours = kDefaultGemEarlyAccessHours,
  DateTime? now,
}) {
  return gems
      .where((gem) => gemVisibleToViewer(
            gem,
            isPremium: isPremium,
            viewerId: viewerId,
            delayHours: delayHours,
            now: now,
          ))
      .toList();
}
