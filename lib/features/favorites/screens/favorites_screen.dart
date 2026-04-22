import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../products/models/product.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(favoritedProductsProvider);
    // Watch IDs para filtrar en tiempo real cuando el usuario quita un favorito
    final currentIds = ref.watch(favoriteIdsProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: const _FavoritesAppBar(),
      body: user == null
          ? _NotLoggedIn()
          : productsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (e, st) => Center(
                child: Text('Error al cargar favoritos',
                    style: GoogleFonts.manrope(color: AppTheme.error)),
              ),
              data: (products) {
                // Filtrar en tiempo real sin llamada de red adicional
                final visible =
                    products.where((p) => currentIds.contains(p.id)).toList();
                if (visible.isEmpty) return const _EmptyFavorites();
                return _FavoritesList(products: visible);
              },
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _FavoritesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FavoritesAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppTheme.background.withAlpha(179),
          child: SafeArea(
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Mis favoritos',
                      style: GoogleFonts.notoSerif(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.favorite_rounded,
                        color: AppTheme.primary, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Estado: no autenticado ────────────────────────────────────────────────────

class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border_rounded,
                size: 64, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Guarda lo que te gusta',
              style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia sesión para guardar productos y acceder a ellos cuando quieras.',
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text('Iniciar sesión',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado: sin favoritos ─────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border_rounded,
                size: 64, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Todavía no hay favoritos',
              style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Pulsa el corazón en cualquier producto para guardarlo aquí.',
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text('Explorar productos',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lista de favoritos ────────────────────────────────────────────────────────

class _FavoritesList extends StatelessWidget {
  final List<Product> products;
  const _FavoritesList({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 1100 ? 5 : w >= 800 ? 4 : w >= 550 ? 3 : 2;
        return GridView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 96,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 240,
          ),
          itemCount: products.length,
          itemBuilder: (ctx, i) => _FavoriteCard(product: products[i]),
        );
      },
    );
  }
}

// ── Tarjeta de producto en favoritos ─────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  final Product product;
  const _FavoriteCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => kIsWeb ? context.go('/producto/${product.id}') : context.push('/producto/${product.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: AppTheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.coverImageUrl != null
                        ? Image.network(
                            product.coverImageUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 400,
                            errorBuilder: (ctx, err, st) => Container(
                              color: AppTheme.surfaceContainerHigh,
                              child: const Icon(Icons.image_outlined,
                                  color: AppTheme.onSurfaceVariant),
                            ),
                          )
                        : Container(
                            color: AppTheme.surfaceContainerHigh,
                            child: const Icon(Icons.image_outlined,
                                color: AppTheme.onSurfaceVariant),
                          ),
                    // Botón quitar favorito
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _RemoveFavoriteBtn(productId: product.id),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.notoSerif(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${product.priceLabel} / ${product.unit}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveFavoriteBtn extends ConsumerWidget {
  final String productId;
  const _RemoveFavoriteBtn({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(favoriteIdsProvider.notifier).toggle(productId),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.favorite_rounded,
            size: 18, color: AppTheme.primary),
      ),
    );
  }
}
