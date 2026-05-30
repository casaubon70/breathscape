/// A string key-value store that may be backed by a cross-device sync provider
/// (iCloud, Google Drive) or a purely local store.
///
/// Implementations must tolerate being offline: [write] persists locally and
/// best-effort to the remote, [read] returns the last known value.
abstract class SyncedKeyValueStore {
  /// Returns the current value for [key], or null if unset.
  Future<String?> read(String key);

  /// Persists [value] under [key].
  Future<void> write(String key, String value);

  /// Emits the new value for [key] whenever it changes externally (e.g. from
  /// another device). Local stores emit nothing.
  Stream<String> watch(String key);
}
