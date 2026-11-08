/// Characters that are invisible on screen and never part of a key.
///
/// Zero-width space and joiners, the bidi marks, U+2060 WORD JOINER and its
/// invisible-operator neighbours, the byte-order mark and the soft hyphen.
/// They ride along when a key is copied out of a notes app, a translator or
/// a web page: the #1253 report has a WORD JOINER on either side of every
/// "AQ...", and `String.trim` keeps all of them.
final _invisible = RegExp(
  '[\u00AD\u200B-\u200F\u202A-\u202E\u2060-\u2064\uFEFF]',
);

/// [raw] as typed or pasted, without what the paste added.
///
/// Drops the invisible characters above wherever they are, then surrounding
/// whitespace, line breaks included. Nothing else is touched: a space or a
/// line break *inside* the key is left for [isWellFormedApiKey] to refuse,
/// because removing it would join two things the user may not have meant to
/// join.
///
/// No prefix is checked. Google AI Studio creates every new key as an "auth
/// key" since 28 May 2026 (aistudio.google.com/docs/api-key), and those start
/// with `AQ.` rather than `AIza` (#1253); OpenRouter's start with `sk-or-`;
/// and a proxy in front of a user's own server can issue anything.
String cleanApiKey(String raw) => raw.replaceAll(_invisible, '').trim();

/// Whether [key] can be sent at all.
///
/// Every character must be printable ASCII (`!` to `~`). That is the whole
/// rule, and it is not a guess at any provider's format: it is what an HTTP
/// header value can carry and what every key format in use is made of. A
/// key outside it makes the request fail on the phone before it is sent,
/// which the app could only report as a connection problem.
bool isWellFormedApiKey(String key) =>
    key.isNotEmpty && key.codeUnits.every((c) => c >= 0x21 && c <= 0x7E);
