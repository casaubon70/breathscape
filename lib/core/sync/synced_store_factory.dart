import 'package:breathscape/core/sync/drive_app_data_store.dart';
import 'package:breathscape/core/sync/google_drive_auth.dart';
import 'package:breathscape/core/sync/icloud_key_value_store.dart';
import 'package:breathscape/core/sync/synced_key_value_store.dart';
import 'package:flutter/foundation.dart';

/// Returns the platform-native cross-device sync store, or null when the
/// current platform has no sync provider (web/desktop) — callers then fall
/// back to local-only persistence.
///
/// - Apple (iOS/macOS): iCloud key-value store (no sign-in required).
/// - Android: Google Drive appDataFolder (requires Google sign-in).
SyncedKeyValueStore? createRemoteSyncStore() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return const ICloudKeyValueStore();
    case TargetPlatform.android:
      return DriveAppDataStore(accessToken: driveAppDataAccessToken);
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return null;
  }
}
