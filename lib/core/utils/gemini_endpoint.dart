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
/// `generativelanguage.googleapis.com.example.org` is not Google. `Uri`
/// already lower-cases the host, but keeps a terminal root dot, and
/// `generativelanguage.googleapis.com.` is the same name written absolutely:
/// DNS reaches Google either way, so one trailing dot is dropped first.
bool isGeminiEndpoint(Uri endpoint) {
  final host = endpoint.host;
  final name = host.endsWith('.') ? host.substring(0, host.length - 1) : host;
  return name == geminiOpenAiCompatibleHost;
}
