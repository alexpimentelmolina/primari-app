import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deep link pendiente que llegó mientras la splash estaba en pantalla.
/// El listener de app_links lo setea ANTES de llamar a router.go().
/// La splash lo comprueba antes de navegar a /home.
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);
