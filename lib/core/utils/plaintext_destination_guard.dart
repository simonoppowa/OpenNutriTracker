import 'dart:io';

import 'package:http/http.dart' as http;

/// Raised when a plaintext request would leave the phone. Carries the host, never the path or the body: this is thrown on
/// a request that may be a photograph of somebody's dinner.
class InsecureDestinationException implements Exception {
  final String host;

  const InsecureDestinationException(this.host);

  @override
  String toString() => 'InsecureDestinationException($host)';
}

/// Whether the app is willing to send **plaintext** to [address]: only when
/// it is this phone itself, `127.0.0.0/8` or `::1`.
///
/// Until #1050 this also admitted link-local, RFC 1918 and IPv6 unique-local
/// addresses, on the reasoning that a payload sent there stays off the
/// public internet. It does not stay on the phone, though, and Play's Data
/// safety form can only declare encryption in transit if it holds for
/// **all** data the app transmits off the device — with no room for "unless
/// the user typed a LAN address". Loopback never leaves the device, so it is
/// not transmission at all, and the declaration stays true. A server
/// elsewhere on the user's network needs `https://`.
bool isLoopbackDestination(InternetAddress address) {
  if (address.isLoopback) return true;

  // An IPv4-mapped v6 address — `::ffff:127.0.0.1` — is a v4 destination
  // wearing a v6 shape, and is judged by its v4 bytes.
  final raw = address.rawAddress;
  return raw.length == 16 && _isV4Mapped(raw) && raw[12] == 127;
}

bool _isV4Mapped(List<int> raw) {
  for (var i = 0; i < 10; i++) {
    if (raw[i] != 0) return false;
  }
  return raw[10] == 0xFF && raw[11] == 0xFF;
}

/// Decides, per request, whether a plaintext URL may be sent — and to which
/// address.
///
/// **The typed string cannot carry the answer.** `http://ollama.lan` is what
/// people configure, and a name resolves wherever DNS says: possibly
/// somewhere public, and possibly somewhere different today than when it was
/// saved. #746 and #748 measured that neither platform's transport policy
/// reaches `dart:io` — it is BSD sockets, not NSURLSession — so nothing
/// outside this app is enforcing anything. This is the whole of the
/// enforcement.
///
/// A measured dual-stack case shows why both families have to be considered:
/// `example-server.home.arpa` reverse-resolves to
/// `192.168.1.46`, while its **forward lookup returns only a public-scope
/// IPv6 address**. An IPv4-only check would never see where the connection
/// actually went.
class PlaintextDestinationGuard {
  final Future<List<InternetAddress>> Function(String host) _lookup;

  PlaintextDestinationGuard({
    Future<List<InternetAddress>> Function(String host)? lookup,
  }) : _lookup = lookup ?? _resolve;

  static Future<List<InternetAddress>> _resolve(String host) =>
      InternetAddress.lookup(host, type: InternetAddressType.any);

  /// Turns the `%25` a URI must spell a zone id with back into the `%` that
  /// [InternetAddress] parses.
  ///
  /// A link-local address needs a zone to be routable on a host with more
  /// than one interface, and RFC 6874 says a URI escapes it: `Uri` stores
  /// `http://[fe80::1%wlan0]` with a host of `fe80::1%25wlan0` — typing the
  /// bare `%` gets you the same thing, so this is not a corner someone has to
  /// know the RFC to reach. `InternetAddress.tryParse` returns null on that
  /// escaped form, which sent the address down the DNS branch below, where
  /// the lookup fails and the caller is told the server is **unreachable** —
  /// when the true answer is the policy refusal, which wants a different fix
  /// (`https://`) from an unreachable server.
  ///
  /// `dart:io` does exactly this substitution itself, in
  /// `escapeLinkLocalAddress`, before it resolves or connects. Doing it here
  /// too is what makes the check agree with the socket layer it is guarding.
  ///
  /// Anything that still fails to parse falls through to the lookup unchanged,
  /// so a name is never touched: the `25` is only dropped when it directly
  /// follows the first `%`.
  static String _withZoneUnescaped(String host) {
    final marker = host.indexOf('%');
    if (marker < 0 || !host.startsWith('25', marker + 1)) return host;
    return host.replaceRange(marker + 1, marker + 3, '');
  }

  /// Returns the URL to actually request, or throws
  /// [InsecureDestinationException].
  ///
  /// For `https://` the URL is returned untouched: TLS is what the rule is
  /// about, so any address is fine, and rewriting the host would break SNI
  /// and name-based virtual hosting.
  ///
  /// For `http://` the returned URL is **pinned to the resolved address**.
  /// Checking a name and then handing the name back to the socket layer
  /// leaves a gap where the second lookup can answer differently from the
  /// first; connecting to the address that was actually approved closes it.
  Future<Uri> approve(Uri url) async {
    if (url.scheme != 'http') return url;

    final host = url.host;
    final literal = InternetAddress.tryParse(_withZoneUnescaped(host));
    if (literal != null) {
      // No lookup to do, and nothing to pin — the user typed the address.
      if (isLoopbackDestination(literal)) return url;
      throw InsecureDestinationException(host);
    }

    final List<InternetAddress> addresses;
    try {
      addresses = await _lookup(host);
    } on SocketException {
      // A name that does not resolve is not a policy refusal. Reporting it as
      // one would tell someone their address is unsafe when it is simply
      // unreachable, and those want opposite fixes.
      rethrow;
    }

    for (final address in addresses) {
      if (!isLoopbackDestination(address)) continue;
      // The first loopback answer wins, whichever family it came from. A name
      // that resolves to both `127.0.0.1` and something else is reachable on
      // the phone, and the app is about to prove it by connecting there.
      return url.replace(host: address.address);
    }

    throw InsecureDestinationException(host);
  }
}

/// Applies [PlaintextDestinationGuard] to every request that passes through.
///
/// A client decorator rather than a check inside one API class, because the
/// promise is about the app's traffic to a user-supplied address and not
/// about one call site. Anything given this client is covered, including
/// call sites that do not exist yet.
///
/// **Redirects are not followed.** They would be followed below this layer,
/// where the guard never sees them, so a 30x comes back to the caller
/// unfollowed rather than becoming an unchecked second destination.
class GuardedPlaintextClient extends http.BaseClient {
  final http.Client _inner;
  final PlaintextDestinationGuard _guard;

  GuardedPlaintextClient(this._inner, {PlaintextDestinationGuard? guard})
    : _guard = guard ?? PlaintextDestinationGuard();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final approved = await _guard.approve(request.url);
    final outgoing = approved == request.url
        ? request
        : _reboundTo(approved, request);

    // Redirects are followed inside `dart:io`, below `BaseClient.send`, so a
    // hop never comes back through here and never meets [approve]. Left on,
    // a server answering 30x with an `http://` target off the phone would
    // have that connection made — past a check that only saw the first hop.
    // The guard cannot vouch for a hop it never sees, so it does not let one
    // happen: a redirect is returned to the caller as the 30x it is.
    //
    // This holds for `https://` too, which [approve] waves through: an
    // encrypted first hop says nothing about where a `Location` points.
    if (outgoing.followRedirects) outgoing.followRedirects = false;

    return _inner.send(outgoing);
  }

  /// Rebuilds the request against the approved address, keeping the original
  /// authority in the `host` header so a name-based server still routes it.
  ///
  /// **The port is part of that authority.** A local model server is almost
  /// never on 80 — `http://ollama.lan:11434` is the ordinary shape — and a
  /// `Host: ollama.lan` that drops the `:11434` is a different authority from
  /// the one that was typed. A reverse proxy or a strict server routes by
  /// what that header says, so it has to keep saying it. The port is written
  /// only when the URL gave one, so a plain `http://ollama.lan` still sends
  /// the bare name rather than a redundant `:80`.
  ///
  /// Only [http.Request] can be rebuilt — its body is bytes already. A
  /// streamed request is passed through **after** the check, which still
  /// refuses a public destination; it only loses the address pinning. The app
  /// sends no streamed requests to a user-supplied endpoint, and a wrong
  /// guess about how to re-wrap one would be worse than the gap.
  http.BaseRequest _reboundTo(Uri url, http.BaseRequest request) {
    if (request is! http.Request) return request;
    final origin = request.url;
    return http.Request(request.method, url)
      ..headers.addAll(request.headers)
      ..headers['host'] = origin.hasPort
          ? '${origin.host}:${origin.port}'
          : origin.host
      ..bodyBytes = request.bodyBytes
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
  }

  @override
  void close() => _inner.close();
}
