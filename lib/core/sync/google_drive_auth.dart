import 'package:google_sign_in/google_sign_in.dart';

/// OAuth scope granting access to the app's private Drive appDataFolder only.
const String driveAppDataScope =
    'https://www.googleapis.com/auth/drive.appdata';

/// Returns an access token for the Drive appDataFolder scope using
/// `google_sign_in`, or null if the user is not signed in / declines / the
/// platform is unsupported.
///
/// Silent (lightweight) authentication is tried first so an already signed-in
/// user syncs without friction; otherwise an interactive sign-in is attempted.
///
/// Requires OAuth client configuration (see docs/SYNC_SETUP.md). All failures
/// are swallowed so sync degrades gracefully to local-only.
Future<String?> driveAppDataAccessToken() async {
  try {
    final signIn = GoogleSignIn.instance;
    await signIn.initialize();

    var account =
        await (signIn.attemptLightweightAuthentication() ??
            Future<GoogleSignInAccount?>.value());
    if (account == null) {
      if (!signIn.supportsAuthenticate()) return null;
      account = await signIn.authenticate(scopeHint: const [driveAppDataScope]);
    }

    final client = signIn.authorizationClient;
    const scopes = [driveAppDataScope];
    final authorization =
        await client.authorizationForScopes(scopes) ??
        await client.authorizeScopes(scopes);
    return authorization.accessToken;
  } on Object {
    // Any failure (unsupported platform, declined sign-in, network) degrades
    // gracefully to local-only sync. Catches Error too (e.g. the unimplemented
    // platform stub in tests), not just Exception.
    return null;
  }
}
