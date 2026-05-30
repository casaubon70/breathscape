import 'package:breathscape/core/sync/synced_key_value_store.dart';
import 'package:flutter/foundation.dart';

/// Returns the platform-native cross-device sync store, or null when the
/// current platform has no sync provider (web/desktop) — callers then fall
/// back to local-only persistence.
///
/// Native implementations (iCloud on Apple, Google Drive on Android) are wired
/// in a later slice; until then this returns null everywhere.
SyncedKeyValueStore? createRemoteSyncStore() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      // TODO(sync): return ICloudKeyValueStore() once the native channel lands.
      return null;
    case TargetPlatform.android:
      // TODO(sync): return DriveAppDataStore() once Drive auth lands.
      return null;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return null;
  }
}
