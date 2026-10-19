import 'dart:convert';

import 'package:http/http.dart' as http;

/// A WebDAV request the server answered with an error status.
class WebDavException implements Exception {
  final int? statusCode;
  final String message;

  const WebDavException(this.message, {this.statusCode});

  /// The server rejected the credentials (wrong or revoked token).
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'WebDavException($statusCode): $message';
}

/// The few WebDAV calls the automatic backup needs, against one folder.
///
/// Authenticates with HTTP basic auth, the token as the password. That is
/// how FileBrowser Quantum takes its API tokens (the user name is ignored),
/// and how most WebDAV servers take an app password.
class WebDavClient {
  static const _userName = 'nutritracker';
  static final _href = RegExp(
    r'<(?:[A-Za-z][\w-]*:)?href>([^<]+)</(?:[A-Za-z][\w-]*:)?href>',
    caseSensitive: false,
  );

  /// Long enough for a backup with photos over a slow uplink; a server that
  /// stops answering must not hold every later backup up.
  static const defaultTimeout = Duration(seconds: 120);

  final http.Client _client;
  final Uri _folder;
  final String _authorization;
  final Duration _timeout;

  /// [folder] must be an `https` URL; a trailing slash is added when it is
  /// missing.
  WebDavClient(
    this._client, {
    required Uri folder,
    required String token,
    Duration timeout = defaultTimeout,
  }) : _timeout = timeout,
       _folder = _asFolder(folder),
       _authorization =
           'Basic ${base64Encode(utf8.encode('$_userName:$token'))}';

  static Uri _asFolder(Uri folder) {
    if (folder.scheme != 'https' || folder.host.isEmpty) {
      throw ArgumentError.value(folder, 'folder', 'must be an https URL');
    }
    return folder.path.endsWith('/')
        ? folder
        : folder.replace(path: '${folder.path}/');
  }

  Uri _file(String name) =>
      _folder.replace(path: '${_folder.path}${Uri.encodeComponent(name)}');

  Future<void> put(String name, List<int> bytes) async {
    final request = http.Request('PUT', _file(name))
      ..headers.addAll({
        'Authorization': _authorization,
        'Content-Type': 'application/zip',
      })
      ..bodyBytes = bytes;
    await _send(request, 'upload $name');
  }

  Future<List<int>> get(String name) async {
    final response = await _send(
      http.Request('GET', _file(name))
        ..headers['Authorization'] = _authorization,
      'download $name',
    );
    return response.bodyBytes;
  }

  Future<void> delete(String name) async {
    await _send(
      http.Request('DELETE', _file(name))
        ..headers['Authorization'] = _authorization,
      'delete $name',
    );
  }

  /// The names of the files directly inside the folder.
  Future<List<String>> list() async {
    final response = await _send(_propfind(), 'list the folder');
    final folderPath = _folder.path;
    final names = <String>[];
    for (final match in _href.allMatches(response.body)) {
      final href = match.group(1)!.trim();
      final path = Uri.decodeFull(
        href.startsWith('http') ? Uri.parse(href).path : href,
      );
      if (path == folderPath ||
          path == folderPath.replaceAll(RegExp(r'/$'), '')) {
        continue;
      }
      final name = path.split('/').where((part) => part.isNotEmpty).last;
      names.add(name);
    }
    return names;
  }

  /// Checks that the folder exists and creates it when it does not.
  Future<void> ensureFolder() async {
    try {
      await _send(_propfind(depth: '0'), 'open the folder');
    } on WebDavException catch (error) {
      if (error.statusCode != 404) rethrow;
      await _send(
        http.Request('MKCOL', _folder)
          ..headers['Authorization'] = _authorization,
        'create the folder',
      );
    }
  }

  http.Request _propfind({String depth = '1'}) =>
      http.Request('PROPFIND', _folder)
        ..headers.addAll({
          'Authorization': _authorization,
          'Depth': depth,
          'Content-Type': 'application/xml',
        })
        ..body =
            '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop>'
            '<d:resourcetype/></d:prop></d:propfind>';

  Future<http.Response> _send(http.BaseRequest request, String what) async {
    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavException('Could not $what', statusCode: response.statusCode);
    }
    return response;
  }
}
