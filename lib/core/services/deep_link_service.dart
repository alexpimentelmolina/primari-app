import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/deep_link_provider.dart';

/// Inicializa la escucha de deep links (Universal Links / App Links).
///
/// - Cold start: `getInitialLink()` captura el link que abrió la app.
/// - Warm: `uriLinkStream` captura links que llegan con la app abierta.
///
/// En web no hacemos nada: GoRouter lee la URL del navegador directamente.
void initDeepLinks(WidgetRef ref, GoRouter router) {
  if (kIsWeb) return;

  final appLinks = AppLinks();

  // --- Cold start ---
  appLinks.getInitialLink().then((uri) {
    if (uri == null) return;
    final path = _extractPath(uri);
    if (path == null) return;
    debugPrint('[deep_link] initial: $path');
    ref.read(pendingDeepLinkProvider.notifier).state = path;
    router.go(path);
  }).catchError((e) {
    debugPrint('[deep_link] getInitialLink error: $e');
  });

  // --- Warm (app ya abierta) ---
  appLinks.uriLinkStream.listen((uri) {
    final path = _extractPath(uri);
    if (path == null) return;
    debugPrint('[deep_link] stream: $path');
    ref.read(pendingDeepLinkProvider.notifier).state = path;
    router.go(path);
  }, onError: (e) {
    debugPrint('[deep_link] stream error: $e');
  });
}

/// Extrae el path interno de la URI si pertenece a weareprimari.com.
/// Ejemplo: https://weareprimari.com/producto/abc → /producto/abc
String? _extractPath(Uri uri) {
  // Solo aceptamos links de nuestro dominio
  if (uri.host != 'weareprimari.com' && uri.host != 'www.weareprimari.com') {
    return null;
  }
  final path = uri.path;
  if (path.isEmpty || path == '/') return null;
  return path;
}
