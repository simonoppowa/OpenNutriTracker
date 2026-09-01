import 'dart:io';

import 'package:http/http.dart' as http;

/// Raised when a plaintext request would leave for somewhere that is not
/// private. Carries the host, never the path or the body: this is thrown on
/// a request that may be a photograph of somebody's dinner.
class InsecureDestinationException implements Exception {
  final String host;

  const InsecureDestinationException(this.host);

  @override
  String toString() => 'InsecureDestinationException($host)';
}

/// Whether the app is willing to send **plaintext** to [address].
///
/// Loopback, link-local, RFC 1918 and IPv6 unique-local. Deliberately not a
/// judgement about whether an address is *reachable* or *safe* in general —
/// only about whether an unencrypted payload sent to it stays off the public
/// internet.
///
/// **Carrier-grade NAT (`100.64.0.0/10`) is not included, and that is a real
/// exclusion rather than an oversight.** It is what Tailscale hands out, so
/// a user reaching their own machine over a tailnet is refused plaintext and
/// has to use `https://`. The range is shared address space, not private
/// space: the app cannot tell a tailnet from an ISP's CGNAT, and treating
/// every `100.x` as private would quietly permit plaintext to a carrier's
/// network. Worth revisiting with evidence, not by assumption.
bool isPrivateDestination(InternetAddress address) {
  // `::1` and `127.0.0.0/8`, and `fe80::/10` and `169.254.0.0/16`. Dart
  // already answers both correctly for both families.
  if (address.isLoopback || address.isLinkLocal) return true;

  final raw = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) return _isPrivateV4(raw);

  // An IPv4-mapped v6 address — `::ffff:192.168.1.5` — is a v4 destination
  // wearing a v6 shape. Judging it by its v6 bytes would call a LAN address
  // public, which is the mirror of the bug that makes this check necessary
  // at all.
  if (raw.length == 16 && _isV4Mapped(raw)) {
    return _isPrivateV4(raw.sublist(12));
  }

  // `fc00::/7` — unique local. The v6 answer to RFC 1918.
  return raw.isNotEmpty && (raw[0] & 0xFE) == 0xFC;
}

bool _isPrivateV4(List<int> raw) {
  if (raw.length != 4) return false;
  return raw[0] == 10 ||
      (raw[0] == 172 && raw[1] >= 16 && raw[1] <= 31) ||
      (raw[0] == 192 && raw[1] == 168);
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
    final literal = InternetAddress.tryParse(host);
    if (literal != null) {
      // No lookup to do, and nothing to pin — the user typed the address.
      if (isPrivateDestination(literal)) return url;
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
      if (!isPrivateDestination(address)) continue;
      // The first private answer wins, whichever family it came from. A name
      // that resolves to both a public v4 and a private v6 is reachable
      // privately, and the app is about to prove it by connecting there.
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
    // a server answering 30x with a public `http://` target would have that
    // connection made — from a check that reported the destination private.
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
