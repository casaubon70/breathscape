import 'dart:async';
import 'dart:convert';

import 'package:breathscape/core/sync/synced_key_value_store.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [SyncedKeyValueStore] whose [watch] stream can be driven by tests.
class FakeStore implements SyncedKeyValueStore {
  FakeStore([this._value]);

  String? _value;
  final _controller = StreamController<String>.broadcast();

  String? get value => _value;

  @override
  Future<String?> read(String key) async => _value;

  @override
  Future<void> write(String key, String value) async => _value = value;

  @override
  Stream<String> watch(String key) => _controller.stream;

  void emitRemote(String raw) => _controller.add(raw);
}

/// Remote store whose every operation throws — mimics a missing native sync
/// provider (e.g. the iCloud MethodChannel on web).
class ThrowingStore implements SyncedKeyValueStore {
  @override
  Future<String?> read(String key) async => throw Exception('no plugin');

  @override
  Future<void> write(String key, String value) async =>
      throw Exception('no plugin');

  @override
  Stream<String> watch(String key) =>
      Stream<String>.error(Exception('no plugin'));
}

String encode(PatternOverrides overrides) => jsonEncode(overrides.toJson());

void main() {
  group('PatternOverridesRepository', () {
    test('load falls back to local when the remote read throws', () async {
      const local = PatternOverrides(
        byPattern: {
          'Box': {0: 5},
        },
        updatedAt: 100,
      );
      final repo = PatternOverridesRepository(
        local: FakeStore(encode(local)),
        remote: ThrowingStore(),
      );

      expect(await repo.load(), local);
    });

    test('save still succeeds locally when the remote write throws', () async {
      const overrides = PatternOverrides(
        byPattern: {
          'Box': {0: 7},
        },
        updatedAt: 42,
      );
      final localStore = FakeStore();
      final repo = PatternOverridesRepository(
        local: localStore,
        remote: ThrowingStore(),
      );

      await repo.save(overrides);

      expect(localStore.value, encode(overrides));
    });

    test('load returns empty overrides when both stores are empty', () async {
      final repo = PatternOverridesRepository(
        local: FakeStore(),
        remote: FakeStore(),
      );

      expect(await repo.load(), const PatternOverrides());
    });

    test('load prefers the local copy when it is newer', () async {
      const local = PatternOverrides(
        byPattern: {
          'Box': {0: 5},
        },
        updatedAt: 200,
      );
      const remote = PatternOverrides(
        byPattern: {
          'Box': {0: 9},
        },
        updatedAt: 100,
      );
      final repo = PatternOverridesRepository(
        local: FakeStore(encode(local)),
        remote: FakeStore(encode(remote)),
      );

      expect(await repo.load(), local);
    });

    test('load prefers the remote copy when it is newer and writes '
        'it through to local', () async {
      const local = PatternOverrides(
        byPattern: {
          'Box': {0: 5},
        },
        updatedAt: 100,
      );
      const remote = PatternOverrides(
        byPattern: {
          'Box': {0: 9},
        },
        updatedAt: 300,
      );
      final localStore = FakeStore(encode(local));
      final repo = PatternOverridesRepository(
        local: localStore,
        remote: FakeStore(encode(remote)),
      );

      expect(await repo.load(), remote);
      expect(localStore.value, encode(remote));
    });

    test('save writes to both stores', () async {
      const overrides = PatternOverrides(
        byPattern: {
          'Box': {0: 7},
        },
        updatedAt: 42,
      );
      final localStore = FakeStore();
      final remoteStore = FakeStore();
      final repo = PatternOverridesRepository(
        local: localStore,
        remote: remoteStore,
      );

      await repo.save(overrides);

      expect(localStore.value, encode(overrides));
      expect(remoteStore.value, encode(overrides));
    });

    test(
      'changes emits parsed remote updates and writes them to local',
      () async {
        const remote = PatternOverrides(
          byPattern: {
            'Box': {1: 6},
          },
          updatedAt: 500,
        );
        final localStore = FakeStore();
        final remoteStore = FakeStore();
        final repo = PatternOverridesRepository(
          local: localStore,
          remote: remoteStore,
        );

        final future = repo.changes.first;
        remoteStore.emitRemote(encode(remote));

        expect(await future, remote);
        expect(localStore.value, encode(remote));
      },
    );

    test('changes is empty when there is no remote store', () async {
      final repo = PatternOverridesRepository(local: FakeStore());

      expect(await repo.changes.isEmpty, isTrue);
    });
  });
}
