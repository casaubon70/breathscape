import 'package:breathscape/core/sync/icloud_key_value_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('breathscape/icloud_kv');
  const changes = EventChannel('breathscape/icloud_kv_changes');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  const store = ICloudKeyValueStore();

  tearDown(() {
    messenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(changes, null);
  });

  group('ICloudKeyValueStore', () {
    test('read invokes the get method with the key', () async {
      MethodCall? captured;
      messenger.setMockMethodCallHandler(methods, (call) async {
        captured = call;
        return 'stored-value';
      });

      final value = await store.read('pattern_overrides');

      expect(value, 'stored-value');
      expect(captured?.method, 'get');
      expect(captured?.arguments, {'key': 'pattern_overrides'});
    });

    test('write invokes the set method with key and value', () async {
      MethodCall? captured;
      messenger.setMockMethodCallHandler(methods, (call) async {
        captured = call;
        return null;
      });

      await store.write('pattern_overrides', '{"a":1}');

      expect(captured?.method, 'set');
      expect(captured?.arguments, {
        'key': 'pattern_overrides',
        'value': '{"a":1}',
      });
    });

    test('watch emits the read value only for the matching key', () async {
      messenger
        ..setMockMethodCallHandler(methods, (call) async {
          if (call.method == 'get') return 'remote-value';
          return null;
        })
        ..setMockStreamHandler(
          changes,
          MockStreamHandler.inline(
            onListen: (arguments, sink) {
              sink
                ..success('other_key')
                ..success('pattern_overrides');
            },
          ),
        );

      final first = await store.watch('pattern_overrides').first;

      expect(first, 'remote-value');
    });
  });
}
