import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/complete_profile_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/seller_profile_screen.dart';
import '../../features/profile/screens/my_profile_screen.dart';
import '../../features/products/screens/publish_product_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/products/screens/my_products_screen.dart';
import '../../features/products/screens/edit_product_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/reviews/screens/seller_reviews_screen.dart';
import '../../features/legal/screens/terms_screen.dart';
import '../../features/legal/screens/privacy_screen.dart';
import '../../features/legal/screens/aviso_legal_screen.dart';
import 'router_notifier.dart';

// El router como Provider de Riverpod para acceder a ref
// Se crea una sola vez (ref.read en el build del notifier)
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          errorParam: state.uri.queryParameters['error'],
        ),
      ),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/completar-perfil',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/vendedor/:id',
        builder: (context, state) => SellerProfileScreen(
          sellerId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/vendedor/:id/resenas',
        builder: (context, state) => SellerReviewsScreen(
          sellerId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/producto/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/publicar',
        builder: (context, state) => const PublishProductScreen(),
      ),
      GoRoute(
        path: '/favoritos',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/mi-perfil',
        builder: (context, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: '/perfil',
        redirect: (context, state) => '/mi-perfil',
      ),
      GoRoute(
        path: '/mis-productos',
        builder: (context, state) => const MyProductsScreen(),
      ),
      GoRoute(
        path: '/listados-activos',
        builder: (context, state) =>
            const MyProductsScreen(activeOnly: true),
      ),
      GoRoute(
        path: '/editar-producto/:id',
        builder: (context, state) => EditProductScreen(
          productId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/configuracion',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/terminos',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacidad',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/aviso-legal',
        builder: (context, state) => const AvisoLegalScreen(),
      ),
      GoRoute(
        path: '/buscar',
        builder: (context, state) => SearchScreen(
          initialQuery: state.uri.queryParameters['q'] ?? '',
          initialCategory: state.uri.queryParameters['cat'],
          initialMaxDistanceKm:
              int.tryParse(state.uri.queryParameters['maxKm'] ?? ''),
          initialSeasonalTerms: state.uri.queryParameters['seasonalQ']
                  ?.split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList() ??
              const [],
        ),
      ),
    ],
  );
});
