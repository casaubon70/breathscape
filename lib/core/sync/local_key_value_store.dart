import 'package:breathscape/core/sync/synced_key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local [SyncedKeyValueStore] backed by [SharedPreferences].
///
/// Used as the always-available base store and as the fallback on platforms
/// without a native sync provider. [watch] never emits — there is no external
/// source of change.
class LocalKeyValueStore implements SyncedKeyValueStore {
  const LocalKeyValueStore();

  @override
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Stream<String> watch(String key) => const Stream.empty();
}
