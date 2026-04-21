import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/cookie_banner.dart';

Future<void> main() async {
  // Activa PathUrlStrategy en web: GoRouter leerá window.location.pathname
  // en vez del hash fragment. Sin esto, Flutter web usa HashUrlStrategy por
  // defecto y GoRouter ignora la URL entrante (/producto/UUID), arranca en /,
  // la splash navega a /home, y la URL queda como /producto/UUID#/home.
  // Es no-op en iOS y Android.
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: PrimariApp()));
}

class PrimariApp extends ConsumerStatefulWidget {
  const PrimariApp({super.key});

  @override
  ConsumerState<PrimariApp> createState() => _PrimariAppState();
}

class _PrimariAppState extends ConsumerState<PrimariApp> {
  bool _deepLinksInitialized = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Inicializar deep links una sola vez, cuando el router ya existe
    if (!_deepLinksInitialized) {
      _deepLinksInitialized = true;
      initDeepLinks(ref, router);
    }

    return MaterialApp.router(
      title: 'Prímari',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
      builder: (context, child) {
        if (!kIsWeb) return child!;
        return Stack(
          children: [
            child!,
            const CookieBannerOverlay(),
          ],
        );
      },
    );
  }
}

