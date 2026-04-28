import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

final routerNotifierProvider =
    ChangeNotifierProvider<RouterNotifier>((ref) => RouterNotifier(ref));

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (prev, next) {
      // Force a fresh profile fetch whenever auth state changes so that
      // a suspension applied while the user is logged in is detected promptly
      // instead of relying on the cached profileProvider value.
      _ref.invalidate(profileProvider);
      notifyListeners();
    });
    _ref.listen(profileProvider, (prev, next) => notifyListeners());
  }

  // Rutas que requieren sesión iniciada
  static const _privateRoutes = ['/publicar', '/favoritos', '/mi-perfil', '/mis-productos', '/editar-producto', '/configuracion'];

  String? redirect(BuildContext context, GoRouterState state) {
    final authValue = _ref.read(authStateProvider);
    // Mientras carga el estado de auth, no redirigir
    if (authValue is AsyncLoading) return null;

    final session = authValue.whenOrNull(data: (s) => s.session);
    final isAuthenticated = session != null;
    final loc = state.matchedLocation;

    // --- Sin sesión ---
    if (!isAuthenticated) {
      // Rutas privadas → login
      if (_privateRoutes.any((r) => loc.startsWith(r))) return '/login';
      // completar-perfil sin sesión → login
      if (loc == '/completar-perfil') return '/login';
      return null;
    }

    // --- Con sesión: comprobar perfil ---
    final profileValue = _ref.read(profileProvider);
    // Mientras carga el perfil, no redirigir
    if (profileValue is AsyncLoading) return null;

    final profile = profileValue.whenOrNull(data: (p) => p);
    final hasProfile = profile != null;

    if (!hasProfile) {
      // Forzar completar perfil (except si ya está ahí)
      if (loc == '/completar-perfil') return null;
      return '/completar-perfil';
    }

    // Cuenta suspendida: cerrar sesión y redirigir a login con mensaje
    if (!profile.isActive) {
      Future.microtask(() => Supabase.instance.client.auth.signOut());
      return '/login?error=suspended';
    }

    // Tiene perfil: redirigir fuera de pantallas de auth
    if (loc == '/login' ||
        loc == '/registro' ||
        loc == '/completar-perfil') {
      return '/home';
    }

    return null;
  }
}
