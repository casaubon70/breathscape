# Pattern-Sync – Einrichtung

Die Pattern-Overrides (geänderte Phasen-Sekunden) werden lokal über
`shared_preferences` persistiert und – plattform-nativ, ohne eigenen Server –
geräteübergreifend synchronisiert:

- **Apple (iOS/macOS):** iCloud Key-Value Store (`NSUbiquitousKeyValueStore`),
  kein Login.
- **Android:** privater Google-Drive-Ordner `appDataFolder`, erfordert
  Google-Login.
- **Andere Plattformen (Web/Desktop):** nur lokal.

Der Code ist vollständig vorhanden. Die folgenden Schritte sind **manuelle,
projektspezifische Einrichtungen**, die nicht im Repo abbildbar sind (Signing,
OAuth-Consent). Ohne sie funktioniert die App weiter – nur ohne Cloud-Sync.

---

## Apple – iCloud Key-Value Store

### iOS (Xcode-Schritt erforderlich)
Die Entitlement-Datei `ios/Runner/Runner.entitlements` existiert bereits mit:

```xml
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
```

In Xcode noch zu erledigen:
1. `ios/Runner.xcworkspace` öffnen → Target **Runner** → **Signing &
   Capabilities**.
2. Ein **Team** auswählen (Apple Developer Account).
3. **+ Capability → iCloud** hinzufügen, **Key-value storage** ankreuzen.
   Xcode verknüpft dabei die `Runner.entitlements` mit dem Build-Setting
   `CODE_SIGN_ENTITLEMENTS` (falls nicht automatisch: Build Settings →
   *Code Signing Entitlements* = `Runner/Runner.entitlements`).

### macOS
`macos/Runner/DebugProfile.entitlements` und `Release.entitlements` enthalten
bereits den `ubiquity-kvstore-identifier` und `network.client`. In Xcode nur ein
Team auswählen und die iCloud-Capability (Key-value storage) aktivieren.

### Verifizieren
Auf zwei Geräten mit demselben iCloud-Account einloggen, eine Phasen-Dauer
ändern, App auf dem zweiten Gerät neu starten → Wert ist übernommen.
(Sync braucht echtes Signing/Provisioning, im Simulator nur eingeschränkt.)

---

## Android – Google Drive appDataFolder

Erfordert ein Google-Cloud-Projekt mit OAuth-Consent (einmalig):

1. **Google Cloud Console** → Projekt anlegen/wählen.
2. **APIs & Services → Library → Google Drive API** aktivieren.
3. **OAuth consent screen** konfigurieren (External, App-Name, Scope
   `.../auth/drive.appdata` hinzufügen, Testnutzer eintragen).
4. **Credentials → OAuth client ID → Android**:
   - Package name: aus `android/app/build.gradle` (`applicationId`).
   - SHA-1: `cd android && ./gradlew signingReport` (Debug- und Release-Key).
5. Der `drive.appdata`-Scope wird im Code bereits angefragt
   (`lib/core/sync/google_drive_auth.dart`).

> Hinweis: `google_sign_in` v7 nutzt auf Android die plattformseitige
> Client-ID-Auflösung; je nach Setup ist zusätzlich eine **Web**-OAuth-Client-ID
> als `serverClientId` in `GoogleSignIn.instance.initialize(...)` nötig. Bei
> Login-Problemen dort die Web-Client-ID ergänzen.

### Verifizieren
Auf zwei Android-Geräten mit demselben Google-Account einloggen, Dauer ändern,
App auf dem zweiten Gerät neu starten → Wert übernommen. Die Datei
`pattern_overrides.json` liegt im (für den Nutzer unsichtbaren) appDataFolder.

---

## Architektur (Kurzüberblick)

```
PatternsBloc
  └─ PatternOverridesRepository  (last-writer-wins via updatedAt)
       ├─ local  : LocalKeyValueStore        (shared_preferences, immer)
       └─ remote : createRemoteSyncStore()    (per Plattform)
                    ├─ ICloudKeyValueStore     (iOS/macOS, MethodChannel/EventChannel)
                    └─ DriveAppDataStore        (Android, Drive REST + google_sign_in)
```

Native iCloud-Bridge: `ios/Runner/AppDelegate.swift` und
`macos/Runner/MainFlutterWindow.swift` (Channels `breathscape/icloud_kv` und
`breathscape/icloud_kv_changes`).
