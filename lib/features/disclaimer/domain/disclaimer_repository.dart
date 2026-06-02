import 'package:shared_preferences/shared_preferences.dart';

class DisclaimerRepository {
  static const int currentVersion = 1;
  static const String _key = 'disclaimer_accepted_version';

  Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_key) ?? 0) >= currentVersion;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, currentVersion);
  }
}
