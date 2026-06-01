import 'dart:convert';

import 'package:breathscape/core/sync/synced_key_value_store.dart';
import 'package:http/http.dart' as http;

/// Supplies a valid OAuth access token with the `drive.appdata` scope, or null
/// when the user is not signed in.
typedef AccessTokenProvider = Future<String?> Function();

/// Android (and any platform with Google sign-in) [SyncedKeyValueStore] backed
/// by the user's private Google Drive **appDataFolder**.
///
/// The store keeps a single JSON file named after the key. The Drive REST API
/// is called directly so the heavy `googleapis` package is not needed; auth is
/// injected via an access-token provider so it can be unit-tested and is
/// decoupled from the `google_sign_in` API surface.
///
/// [watch] emits nothing — Drive offers no cheap push channel; cross-device
/// sync happens when the repository reloads on app start.
class DriveAppDataStore implements SyncedKeyValueStore {
  DriveAppDataStore({
    required AccessTokenProvider accessToken,
    http.Client? client,
  }) : _accessToken = accessToken,
       _client = client ?? http.Client();

  static const String _filesUrl = 'https://www.googleapis.com/drive/v3/files';
  static const String _uploadUrl =
      'https://www.googleapis.com/upload/drive/v3/files';

  final AccessTokenProvider _accessToken;
  final http.Client _client;

  // Serialises writes per key so two concurrent write() calls never both call
  // _create (which would produce duplicate appDataFolder files for one key).
  final _ongoing = <String, Future<void>>{};

  @override
  Future<String?> read(String key) async {
    final token = await _accessToken();
    if (token == null) return null;
    final id = await _fileId(key, token);
    if (id == null) return null;
    final response = await _client.get(
      Uri.parse('$_filesUrl/$id?alt=media'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // Accept any 2xx (Drive may return 206 for large files).
    return response.statusCode >= 200 && response.statusCode < 300
        ? response.body
        : null;
  }

  @override
  Future<void> write(String key, String value) {
    // Chain writes for the same key to prevent the TOCTOU race where two
    // concurrent callers both see no existing file and both call _create.
    final prev = _ongoing[key];
    final next = (prev ?? Future<void>.value()).then<void>(
      (_) => _writeNow(key, value),
    );
    _ongoing[key] = next.whenComplete(() {
      if (_ongoing[key] == next) _ongoing.remove(key);
    });
    return _ongoing[key]!;
  }

  @override
  Stream<String> watch(String key) => const Stream.empty();

  Future<void> _writeNow(String key, String value) async {
    final token = await _accessToken();
    if (token == null) return;
    final id = await _fileId(key, token);
    if (id == null) {
      await _create(key, value, token);
    } else {
      await _update(id, value, token);
    }
  }

  /// Returns the Drive file id for [key] in the appDataFolder, or null.
  Future<String?> _fileId(String key, String token) async {
    // Escape single quotes in the filename for the Drive query string.
    final escapedName = _fileName(key).replaceAll("'", "\\'");
    final uri = Uri.parse(_filesUrl).replace(
      queryParameters: {
        'spaces': 'appDataFolder',
        'q': "name = '$escapedName'",
        'fields': 'files(id)',
      },
    );
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return null;
    final files =
        (jsonDecode(response.body) as Map<String, dynamic>)['files']
            as List<dynamic>?;
    if (files == null || files.isEmpty) return null;
    return (files.first as Map<String, dynamic>)['id'] as String?;
  }

  Future<void> _create(String key, String value, String token) async {
    final metadata = {
      'name': _fileName(key),
      'parents': ['appDataFolder'],
      'mimeType': 'application/json',
    };
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$_uploadUrl?uploadType=multipart'),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromString('metadata', jsonEncode(metadata)),
          )
          ..files.add(http.MultipartFile.fromString('file', value));
    final streamed = await _client.send(request);
    // Ignore non-2xx responses: sync is best-effort; local store is the source
    // of truth and the remote will re-sync on the next app launch.
    streamed.stream.drain<void>();
  }

  Future<void> _update(String id, String value, String token) async {
    await _client.patch(
      Uri.parse('$_uploadUrl/$id?uploadType=media'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: value,
    );
    // Non-2xx is silently ignored — sync is best-effort.
  }

  String _fileName(String key) => '$key.json';
}
