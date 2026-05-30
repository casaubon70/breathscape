import 'package:breathscape/core/sync/drive_app_data_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('DriveAppDataStore', () {
    test('read returns null when there is no access token', () async {
      final store = DriveAppDataStore(
        accessToken: () async => null,
        client: MockClient((_) async => http.Response('', 500)),
      );

      expect(await store.read('pattern_overrides'), isNull);
    });

    test('read fetches file content when the file exists', () async {
      final requests = <http.Request>[];
      final store = DriveAppDataStore(
        accessToken: () async => 'token-123',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/files')) {
            return http.Response('{"files":[{"id":"file-1"}]}', 200);
          }
          return http.Response('{"a":1}', 200);
        }),
      );

      final value = await store.read('pattern_overrides');

      expect(value, '{"a":1}');
      expect(requests.first.headers['Authorization'], 'Bearer token-123');
      expect(requests.last.url.toString(), contains('alt=media'));
    });

    test('read returns null when no file is found', () async {
      final store = DriveAppDataStore(
        accessToken: () async => 'token-123',
        client: MockClient((_) async => http.Response('{"files":[]}', 200)),
      );

      expect(await store.read('pattern_overrides'), isNull);
    });

    test('write updates the file when it already exists', () async {
      String? patchedBody;
      String? patchedMethod;
      final store = DriveAppDataStore(
        accessToken: () async => 'token-123',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/files')) {
            return http.Response('{"files":[{"id":"file-1"}]}', 200);
          }
          patchedMethod = request.method;
          patchedBody = request.body;
          return http.Response('', 200);
        }),
      );

      await store.write('pattern_overrides', '{"a":2}');

      expect(patchedMethod, 'PATCH');
      expect(patchedBody, '{"a":2}');
    });

    test('write creates a new file when none exists', () async {
      final methods = <String>[];
      final store = DriveAppDataStore(
        accessToken: () async => 'token-123',
        client: MockClient((request) async {
          methods.add('${request.method} ${request.url.path}');
          if (request.url.path.endsWith('/drive/v3/files')) {
            return http.Response('{"files":[]}', 200);
          }
          return http.Response('{"id":"new"}', 200);
        }),
      );

      await store.write('pattern_overrides', '{"a":3}');

      expect(methods.any((m) => m.startsWith('POST')), isTrue);
    });
  });
}
