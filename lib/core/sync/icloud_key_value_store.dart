import 'package:breathscape/core/sync/synced_key_value_store.dart';
import 'package:flutter/services.dart';

/// Apple (iOS/macOS) [SyncedKeyValueStore] backed by
/// `NSUbiquitousKeyValueStore` — iCloud's automatic key-value sync.
///
/// No sign-in is required: the OS uses the device's iCloud account. The native
/// side (see `AppDelegate.swift` / `MainFlutterWindow.swift`) bridges:
/// - method channel `breathscape/icloud_kv` with `get`/`set`,
/// - event channel `breathscape/icloud_kv_changes` that emits the key whose
///   value changed externally (i.e. from another device).
class ICloudKeyValueStore implements SyncedKeyValueStore {
  const ICloudKeyValueStore();

  static const MethodChannel _methods = MethodChannel('breathscape/icloud_kv');
  static const EventChannel _changes = EventChannel(
    'breathscape/icloud_kv_changes',
  );

  // Single shared broadcast stream so multiple watch() calls register only one
  // native EventChannel listener. Calling receiveBroadcastStream() more than
  // once would create duplicate native handlers that cancel each other on
  // unsubscribe.
  static final Stream<Object?> _rawChanges = _changes.receiveBroadcastStream();

  @override
  Future<String?> read(String key) async {
    return _methods.invokeMethod<String>('get', {'key': key});
  }

  @override
  Future<void> write(String key, String value) async {
    await _methods.invokeMethod<void>('set', {'key': key, 'value': value});
  }

  @override
  Stream<String> watch(String key) {
    return _rawChanges
        .where((event) => event == key)
        .asyncMap<String?>((_) async => read(key))
        // Drop null (key missing / transient read failure) but pass through
        // empty string, which is a legitimate stored value.
        .where((v) => v != null)
        .cast<String>();
  }
}
