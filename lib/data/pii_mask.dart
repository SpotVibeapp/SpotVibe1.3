/// Masks phone numbers, emails, and social handles in event threads,
/// direct messages, and public comments so people can coordinate without
/// exchanging personal contact details.
const String kContactInfoMask = '[hidden]';

final _email = RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false);
final _phone = RegExp(r'(?:\+?1[-.\s]*)?(?:\(?\d{3}\)?[-.\s]*)\d{3}[-.\s]*\d{4}');
final _handle = RegExp(r'(^|[\s(])@([A-Za-z0-9._]{2,30})');
final _socialUrl = RegExp(
  r'https?://(?:www\.)?(?:instagram|facebook|fb|tiktok|twitter|x|snapchat)\.com/\S+',
  caseSensitive: false,
);

String maskContactInfo(String text) {
  var value = text;
  value = value.replaceAll(_email, kContactInfoMask);
  value = value.replaceAll(_phone, kContactInfoMask);
  value = value.replaceAll(_socialUrl, kContactInfoMask);
  value = value.replaceAllMapped(_handle, (m) => '${m[1]}$kContactInfoMask');
  return value.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

bool containsContactInfo(String text) =>
    maskContactInfo(text) != text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
