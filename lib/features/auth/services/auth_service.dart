import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) =>
      _client.auth.signUp(email: email, password: password);

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  /// En web, Supabase redirige al origen actual (localhost:8080 o weareprimari.com).
  /// Supabase procesa el token del fragment automáticamente al volver a la app.
  Future<void> signInWithGoogle() => _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : 'io.primari.app://login-callback',
      );

  /// Web  → OAuth redirect (igual que Google).
  /// iOS  → flujo nativo con nonce seguro + signInWithIdToken.
  Future<void> signInWithApple() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: Uri.base.origin,
      );
      return;
    }

    // ── iOS: flujo nativo ─────────────────────────────────────────────
    final (rawNonce, hashedNonce) = _generateNonce();

    debugPrint('[Apple] Solicitando credencial nativa…');

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[Apple] El usuario canceló el inicio de sesión.');
        return; // Cancelación silenciosa, no es un error
      }
      debugPrint('[Apple] Error de autorización: ${e.code} — ${e.message}');
      rethrow;
    }

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw Exception('[Apple] No se recibió identity token.');
    }

    debugPrint('[Apple] Identity token recibido, completando con Supabase…');

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: identityToken,
      nonce: rawNonce,
    );

    debugPrint('[Apple] Sesión iniciada correctamente en Supabase.');
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Devuelve (rawNonce, sha256HashedNonce).
  static (String, String) _generateNonce() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final raw =
        List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
    final hashed = sha256.convert(utf8.encode(raw)).toString();
    return (raw, hashed);
  }
}
