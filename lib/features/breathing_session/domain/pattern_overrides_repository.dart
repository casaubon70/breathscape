import 'dart:async';
import 'dart:convert';

import 'package:breathscape/core/sync/local_key_value_store.dart';
import 'package:breathscape/core/sync/synced_key_value_store.dart';
import 'package:breathscape/core/sync/synced_store_factory.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides.dart';

/// Loads, persists and syncs [PatternOverrides].
///
/// A device-local store ([LocalKeyValueStore]) is the authoritative source for
/// immediate reads; an optional remote store mirrors the data across devices.
/// Conflicts are resolved last-writer-wins via [PatternOverrides.updatedAt].
class PatternOverridesRepository {
  PatternOverridesRepository({
    SyncedKeyValueStore? local,
    SyncedKeyValueStore? remote,
  }) : _local = local ?? const LocalKeyValueStore(),
       _remote = remote ?? createRemoteSyncStore();

  static const String storageKey = 'pattern_overrides';

  final SyncedKeyValueStore _local;
  final SyncedKeyValueStore? _remote;

  /// Loads overrides, preferring whichever of local/remote is newer. If the
  /// remote copy wins it is written through to the local store.
  Future<PatternOverrides> load() async {
    final local = _parse(await _local.read(storageKey));
    final remote = _remote == null
        ? null
        : _parse(await _remote.read(storageKey));

    if (remote != null && remote.updatedAt > local.updatedAt) {
      await _local.write(storageKey, jsonEncode(remote.toJson()));
      return remote;
    }
    return local;
  }

  /// Persists [overrides] locally and best-effort to the remote store.
  Future<void> save(PatternOverrides overrides) async {
    final encoded = jsonEncode(overrides.toJson());
    await _local.write(storageKey, encoded);
    await _remote?.write(storageKey, encoded);
  }

  /// Emits overrides received from another device, writing each through to the
  /// local store so subsequent [load] calls stay consistent.
  Stream<PatternOverrides> get changes {
    final remote = _remote;
    if (remote == null) return const Stream.empty();
    return remote.watch(storageKey).asyncMap((raw) async {
      await _local.write(storageKey, raw);
      return _parse(raw);
    });
  }

  PatternOverrides _parse(String? raw) {
    if (raw == null || raw.isEmpty) return const PatternOverrides();
    try {
      return PatternOverrides.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const PatternOverrides();
    }
  }
}
