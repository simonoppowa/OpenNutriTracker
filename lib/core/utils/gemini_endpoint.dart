/// Google's OpenAI-compatible Gemini endpoint, which people reach through
/// "your own server" (#1253, #1257).
const geminiOpenAiCompatibleHost = 'generativelanguage.googleapis.com';

/// Whether [endpoint] is Google's hosted Gemini API rather than a server the
/// user runs.
///
/// **One check for both places that depend on it**: the request asks for the
/// tool by name only here, and the disclosure names Google as the recipient
/// only here. Two copies of the match could disagree, and the one that drifted
/// would either break Gemini or tell someone sending their meals to Google
/// that no third party receives them.
///
/// Matched on the exact host, so a look-alike such as
/// `generativelanguage.googleapis.com.example.org` is not Google.
bool isGeminiEndpoint(Uri endpoint) =>
    canonicalHost(endpoint) == geminiOpenAiCompatibleHost;

/// [uri]'s host in the one form every comparison of hosts uses.
///
/// `Uri` already lower-cases it, but keeps a terminal root dot, and
/// `example.org.` is the same name as `example.org` written absolutely: DNS
/// reaches the same machine either way. One trailing dot is dropped, and only
/// one — a name ending in two is not a valid absolute form.
///
/// Shared so the checks that decide who is on the other end cannot disagree
/// about it: whether an address is Google's, and whether a stored key
/// belongs to the server being typed.
String canonicalHost(Uri uri) {
  final host = uri.host;
  return host.endsWith('.') ? host.substring(0, host.length - 1) : host;
}
