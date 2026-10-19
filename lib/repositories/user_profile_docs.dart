/// Layout of a SpotVibe user's Firestore profile.
///
///   users/{uid}                  PUBLIC profile — any signed-in user can read
///                                it (attendee lists, comments, follows).
///                                Only name, avatarUrl, provider, timestamps.
///   users/{uid}/private/profile  OWNER-ONLY (and admins) — email and any
///                                other contact details.
///
/// Older documents still carry `email` on the public doc. The client moves it
/// on the next sign-in (see [planProfileSync]); the `scrubPublicUserPii`
/// trigger and the `functions/scripts/migrate_user_private_fields.js` script
/// handle everyone else. Firestore rules block writing these fields to the
/// public doc (removing them is allowed).
library;

/// Sub-collection and doc id of the owner-only profile.
const String kUserPrivateCollection = 'private';
const String kUserPrivateProfileDoc = 'profile';

/// Fields that must never live on the publicly readable `users/{uid}` doc.
const List<String> kPrivateProfileFields = ['email', 'phone', 'phoneNumber'];

/// What [planProfileSync] decided to write. The repository turns this into
/// Firestore writes (adding server timestamps / FieldValue.delete()).
class ProfileSyncPlan {
  const ProfileSyncPlan({
    required this.createPublic,
    required this.publicFields,
    required this.removeFromPublic,
    required this.privateFields,
  });

  /// True when `users/{uid}` does not exist yet and must be created.
  final bool createPublic;

  /// Public fields to create/merge (never contains a private field).
  final Map<String, Object> publicFields;

  /// Legacy private fields to delete from the public doc. Only populated
  /// once their values are safely included in [privateFields] (or were
  /// blank), so an email is never lost in the move.
  final List<String> removeFromPublic;

  /// Fields to merge into `users/{uid}/private/profile`; empty = no write.
  final Map<String, Object> privateFields;
}

/// Decides the profile writes for a sign-in / refresh.
///
/// * The email resolved by the caller ([email], may be '') goes only to the
///   private doc, and never overwrites a stored one with a blank (Apple sends
///   the email only on the first sign-in).
/// * Legacy `email`/`phone` values found on the public doc are copied to the
///   private doc (unless it already has a value) and then removed from the
///   public doc.
/// * A stored name is never replaced; a blank one is filled in.
ProfileSyncPlan planProfileSync({
  required Map<String, dynamic>? publicData,
  required Map<String, dynamic>? privateData,
  required String name,
  required String email,
  required String avatarUrl,
  String? provider,
}) {
  final privateFields = <String, Object>{};
  final removeFromPublic = <String>[];

  String stored(Map<String, dynamic>? data, String key) {
    final value = data?[key];
    return value is String ? value.trim() : '';
  }

  final trimmedEmail = email.trim();
  final privateEmail = stored(privateData, 'email');
  if (trimmedEmail.isNotEmpty && trimmedEmail != privateEmail) {
    privateFields['email'] = trimmedEmail;
  }

  for (final field in kPrivateProfileFields) {
    if (publicData == null || !publicData.containsKey(field)) continue;
    final legacy = stored(publicData, field);
    if (legacy.isNotEmpty &&
        stored(privateData, field).isEmpty &&
        !privateFields.containsKey(field)) {
      privateFields[field] = legacy;
    }
    removeFromPublic.add(field);
  }

  if (publicData == null) {
    return ProfileSyncPlan(
      createPublic: true,
      publicFields: {
        'name': name,
        'avatarUrl': avatarUrl,
        if (provider != null) 'provider': provider,
      },
      removeFromPublic: const [],
      privateFields: privateFields,
    );
  }

  final storedName = stored(publicData, 'name');
  return ProfileSyncPlan(
    createPublic: false,
    publicFields: {
      if (storedName.isEmpty && name.trim().isNotEmpty) 'name': name,
    },
    removeFromPublic: removeFromPublic,
    privateFields: privateFields,
  );
}

/// The email to show for the signed-in user: the provider's, then Firebase
/// Auth's, then the private profile's, then a not-yet-migrated public value.
/// '' when none exists — an email is never invented.
String storedEmailFor({
  Map<String, dynamic>? publicData,
  Map<String, dynamic>? privateData,
}) {
  for (final data in [privateData, publicData]) {
    final value = data?['email'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
