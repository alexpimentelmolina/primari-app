import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'primari_cookie_consent';

// Possible values stored in localStorage:
//   null          → pending (banner must show)
//   'accepted'    → all cookies accepted
//   'rejected'    → only essential cookies
//   'customized'  → user configured per-category

class CookieConsentNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    if (!kIsWeb) return 'accepted'; // iOS/Android: no banner needed
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kKey);
  }

  Future<void> accept() => _persist('accepted');
  Future<void> reject() => _persist('rejected');
  Future<void> saveCustom() => _persist('customized');

  Future<void> _persist(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, value);
    state = AsyncData(value);
  }

  /// Clears the stored consent and re-shows the banner.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
    state = const AsyncData(null);
  }
}

final cookieConsentProvider =
    AsyncNotifierProvider<CookieConsentNotifier, String?>(
  CookieConsentNotifier.new,
);
