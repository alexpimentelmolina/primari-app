import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../../core/providers/auth_provider.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/seasonal_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL — diseño basado en Stitch
// Secciones: AppBar frosted · Búsqueda+slider · Categorías · Bento grid · Promo
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true, // el body va detrás del appbar para el blur
      appBar: const _FrostedAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth > 900;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80), // espacio para el appbar transparente
                if (isWeb) const _WebHeroSection(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 80 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: isWeb ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      if (isWeb)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: const _SearchSection(),
                        )
                      else
                        const _SearchSection(),
                      const SizedBox(height: 48),
                      if (isWeb)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: const _CategoriesSection(),
                        )
                      else
                        const _CategoriesSection(),
                      const SizedBox(height: 48),
                      const _FeaturedSection(),
                      const SizedBox(height: 48),
                      const _SeasonalPromo(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/publicar'),
        backgroundColor: AppTheme.primaryContainer,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Publicar', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── AppBar con efecto frosted glass ─────────────────────────────────────────
class _FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FrostedAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppTheme.background.withAlpha(179), // ~70% opacidad
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Prímari',
                    style: GoogleFonts.notoSerif(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sección de búsqueda con chips de distancia y botón Buscar ───────────────
// StatefulWidget porque el slider necesita estado local
class _SearchSection extends StatefulWidget {
  const _SearchSection();
  @override
  State<_SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<_SearchSection> {
  final _queryCtrl = TextEditingController();
  int? _selectedKm;

  // 0 = sin límite de distancia (global)
  static const _kms = [
    (10, '0–10 km'),
    (25, '25 km'),
    (50, '50 km'),
    (0, '100+ km'),
  ];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  void _buscar() {
    final q = _queryCtrl.text.trim();
    final params = <String, String>{};
    if (q.isNotEmpty) params['q'] = q;
    if (_selectedKm != null) params['maxKm'] = _selectedKm.toString();
    final uri = Uri(
      path: '/buscar',
      queryParameters: params.isEmpty ? null : params,
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de búsqueda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    style: GoogleFonts.manrope(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos locales...',
                      hintStyle: GoogleFonts.manrope(
                        color: AppTheme.onSurfaceVariant.withAlpha(153),
                      ),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onSubmitted: (_) => _buscar(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Etiqueta radio
          Text(
            'Distancia desde tu ubicación actual',
            style: GoogleFonts.notoSerif(
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          // Chips de km (toca para seleccionar, vuelve a tocar para quitar)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kms.map((entry) {
              final (km, label) = entry;
              final selected = _selectedKm == km;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedKm = selected ? null : km),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Botón Buscar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _buscar,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                'Buscar',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sección de categorías como círculos horizontales ────────────────────────
// TODO: conectar con categorías reales de Supabase
class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection();

  static const _categories = [
    (Icons.apple,                  'Frutas',            Color(0xFFDCEDC8), Color(0xFF388E3C), 'frutas y verduras'),
    (Icons.grass,                 'Verduras',          Color(0xFFFFF3E0), Color(0xFFBF360C), 'frutas y verduras'),
    (Icons.egg_rounded,           'Huevos',            Color(0xFFFFF8E1), Color(0xFF795548), 'huevos'),
    (Icons.hive_rounded,          'Miel',              Color(0xFFFFDCBD), Color(0xFF7A532A), 'miel'),
    (Icons.outdoor_grill,         'Carne',             Color(0xFFFFEBEE), Color(0xFFC62828), 'carne'),
    (Icons.set_meal_rounded,      'Pescado',           Color(0xFFD6EAF8), Color(0xFF1565C0), 'pescado y marisco'),
    (Icons.local_drink_rounded,   'Lácteos',           Color(0xFFF3E5F5), Color(0xFF6A1F17), 'quesos y lácteos'),
    (Icons.water_drop_rounded,    'Aceite',            Color(0xFFE8F5E9), Color(0xFF2D5A27), 'aceite'),
    (Icons.bakery_dining,         'Panadería',         Color(0xFFFBE9D4), Color(0xFF5D4037), 'panadería y repostería artesanal'),
    (Icons.inventory_2_outlined,  'Conservas',         Color(0xFFFFDAD5), Color(0xFF6A1F17), 'conservas y elaborados artesanales'),
    (Icons.more_horiz,            'Otros',             Color(0xFFEEEEEE), Color(0xFF616161), 'otros'),
  ];

  @override
  Widget build(BuildContext context) {
    // Mismo layout para nativo y web móvil: sin kIsWeb para que ambos
    // usen círculos grandes y el espaciado más abierto.
    final isDesktopWeb = MediaQuery.of(context).size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: isDesktopWeb ? 112 : 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: isDesktopWeb ? Clip.hardEdge : Clip.none,
            padding: isDesktopWeb
                ? EdgeInsets.zero
                : const EdgeInsets.only(right: 16),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => SizedBox(
              width: isDesktopWeb ? 16 : 20,
            ),
            itemBuilder: (context, index) {
              final (icon, label, bg, fg, catKey) = _categories[index];
              final svgAsset = label == 'Frutas' ? 'assets/icons/frutas.svg' : label == 'Verduras' ? 'assets/icons/verduras.svg' : label == 'Carne' ? 'assets/icons/carne.svg' : null;
              final applyColorFilter = label != 'Verduras' && label != 'Carne';
              final svgSize = label == 'Verduras' ? 35.0 : label == 'Carne' ? 33.0 : 31.0;
              return _CategoryCircle(
                icon: icon,
                label: label,
                bgColor: bg,
                iconColor: fg,
                categoryKey: catKey,
                svgAsset: svgAsset,
                applyColorFilter: applyColorFilter,
                svgSize: svgSize,
                circleSize: isDesktopWeb ? 80.0 : 88.0,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final String categoryKey;
  final String? svgAsset;
  final bool applyColorFilter;
  final double svgSize;
  final double circleSize;
  const _CategoryCircle({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.categoryKey,
    this.svgAsset,
    this.svgSize = 31,
    this.applyColorFilter = true,
    this.circleSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/buscar?cat=${Uri.encodeComponent(categoryKey)}'),
      child: SizedBox(
        width: circleSize,
        child: Column(
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: svgAsset != null
                  ? SizedBox(
                      width: svgSize,
                      height: svgSize,
                      child: SvgPicture.asset(svgAsset!, fit: BoxFit.contain,
                          colorFilter: applyColorFilter
                              ? ColorFilter.mode(iconColor, BlendMode.srcIn)
                              : null),
                    )
                  : Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sección "Destacados" con productos reales ────────────────────────────────
class _FeaturedSection extends ConsumerWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(activeProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SELECCIÓN PARA TI', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppTheme.secondary)),
                  const SizedBox(height: 6),
                  Text('Destacados', style: GoogleFonts.notoSerif(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/buscar'),
              child: Text('Ver todo', style: GoogleFonts.manrope(color: AppTheme.primary, fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: AppTheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        productsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('No se pudieron cargar los productos', style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant)),
            ),
          ),
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 48, color: AppTheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('Todavía no hay productos', style: GoogleFonts.notoSerif(fontSize: 18, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('¡Sé el primero en publicar!', style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 700) {
                  return _WideBentoGrid(products: products);
                }
                return _NarrowBentoGrid(products: products);
              },
            );
          },
        ),
      ],
    );
  }
}

class _WideBentoGrid extends StatelessWidget {
  final List<Product> products;
  const _WideBentoGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 450,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: RepaintBoundary(child: _HeroProductCard(product: products[0]))),
              if (products.length > 1) ...[
                const SizedBox(width: 24),
                Expanded(flex: 1, child: RepaintBoundary(child: _SmallProductCard(product: products[1]))),
              ],
            ],
          ),
        ),
        if (products.length > 2) ...[
          const SizedBox(height: 24),
          SizedBox(height: 200, child: RepaintBoundary(child: _HorizontalProductCard(product: products[2]))),
        ],
      ],
    );
  }
}

class _NarrowBentoGrid extends StatelessWidget {
  final List<Product> products;
  const _NarrowBentoGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 360, child: RepaintBoundary(child: _HeroProductCard(product: products[0]))),
        if (products.length > 1) ...[
          const SizedBox(height: 24),
          SizedBox(height: 400, child: RepaintBoundary(child: _SmallProductCard(product: products[1]))),
        ],
        if (products.length > 2) ...[
          const SizedBox(height: 24),
          SizedBox(height: 220, child: RepaintBoundary(child: _HorizontalProductCard(product: products[2]))),
        ],
      ],
    );
  }
}

class _HeroProductCard extends ConsumerWidget {
  final Product product;
  const _HeroProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isFav = ref.watch(
      favoriteIdsProvider.select((v) => v.valueOrNull?.contains(product.id) ?? false),
    );

    return GestureDetector(
      onTap: () => kIsWeb ? context.go('/producto/${product.id}') : context.push('/producto/${product.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            product.coverImageUrl != null
                ? Image.network(product.coverImageUrl!, fit: BoxFit.cover,
                    cacheWidth: 800,
                    errorBuilder: (ctx, err, st) => Container(color: AppTheme.surfaceContainerLow))
                : Container(color: AppTheme.surfaceContainerLow,
                    child: const Icon(Icons.image_outlined, size: 48, color: AppTheme.onSurfaceVariant)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC154212)],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
            // Botón favorito en esquina superior derecha
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  if (user == null) {
                    context.push('/login');
                    return;
                  }
                  ref.read(favoriteIdsProvider.notifier).toggle(product.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 32,
              right: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: AppTheme.tertiaryFixed, borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.eco_rounded, size: 13, color: Color(0xFF6A1F17)),
                      const SizedBox(width: 4),
                      Text(product.categoryLabel.toUpperCase(), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.tertiary)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text(product.title, style: GoogleFonts.notoSerif(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(product.priceLabel, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 4),
                    Text('/ ${product.unit}', style: GoogleFonts.manrope(fontSize: 13, color: Colors.white70)),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 2),
                    Text(product.city, style: GoogleFonts.manrope(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallProductCard extends ConsumerWidget {
  final Product product;
  const _SmallProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isFav = ref.watch(
      favoriteIdsProvider.select((v) => v.valueOrNull?.contains(product.id) ?? false),
    );

    return GestureDetector(
      onTap: () => kIsWeb ? context.go('/producto/${product.id}') : context.push('/producto/${product.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          color: AppTheme.surfaceContainerHigh,
          child: Column(
            children: [
              Expanded(
                child: product.coverImageUrl != null
                    ? Image.network(product.coverImageUrl!, fit: BoxFit.cover, width: double.infinity,
                        cacheWidth: 400,
                        errorBuilder: (ctx, err, st) => Container(color: AppTheme.surfaceContainerLow,
                            child: const Icon(Icons.image_outlined, size: 40, color: AppTheme.onSurfaceVariant)))
                    : Container(color: AppTheme.surfaceContainerLow,
                        child: const Icon(Icons.image_outlined, size: 40, color: AppTheme.onSurfaceVariant)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: GoogleFonts.notoSerif(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(product.description, style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(product.priceLabel, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                        GestureDetector(
                          onTap: () {
                            if (user == null) {
                              context.push('/login');
                              return;
                            }
                            ref.read(favoriteIdsProvider.notifier).toggle(product.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isFav ? AppTheme.primaryContainer : AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
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

class _HorizontalProductCard extends StatelessWidget {
  final Product product;
  const _HorizontalProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => kIsWeb ? context.go('/producto/${product.id}') : context.push('/producto/${product.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          color: AppTheme.surfaceContainerLow,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: product.coverImageUrl != null
                    ? Image.network(product.coverImageUrl!, fit: BoxFit.cover, height: double.infinity,
                        cacheWidth: 400,
                        errorBuilder: (ctx, err, st) => Container(color: AppTheme.surfaceContainerHigh,
                            child: const Icon(Icons.image_outlined, size: 40, color: AppTheme.onSurfaceVariant)))
                    : Container(color: AppTheme.surfaceContainerHigh,
                        child: const Icon(Icons.image_outlined, size: 40, color: AppTheme.onSurfaceVariant)),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(product.categoryLabel.toUpperCase(), style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2, color: AppTheme.tertiaryContainer)),
                              const SizedBox(height: 4),
                              Text(product.title, style: GoogleFonts.notoSerif(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                            child: Text(product.priceLabel, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.onSecondaryContainer)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(product.description, style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),
                      Row(children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), elevation: 0),
                          onPressed: () => kIsWeb ? context.go('/producto/${product.id}') : context.push('/producto/${product.id}'),
                          child: Text('Ver producto', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(product.city, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Banner estacional — contenido gestionado desde Supabase ─────────────────
class _SeasonalPromo extends ConsumerWidget {
  const _SeasonalPromo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(seasonalConfigProvider).valueOrNull ??
        SeasonalConfig.fallback;

    const searchUri = '/buscar';

    return ClipRRect(
      borderRadius: BorderRadius.circular(48),
      child: Container(
        color: AppTheme.primary,
        child: Stack(
          children: [
            // Círculo decorativo difuminado (arriba derecha)
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withAlpha(51),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Contenido centrado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      config.title,
                      style: GoogleFonts.notoSerif(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(
                        config.subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: Colors.white.withAlpha(204),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 8,
                      ),
                      onPressed: () => context.go(searchUri),
                      child: Text(
                        'EXPLORAR TEMPORADA',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero web: "we are Prímari" — solo visible en escritorio (>900px) ─────────
class _WebHeroSection extends StatelessWidget {
  const _WebHeroSection();

  static const _kWe      = Color(0xFFEDD16F);
  static const _kAre     = Color(0xFFC1DBDA);
  static const _kPrimari = Color(0xFF628474);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Center(
        // Semantics expone un H1 al árbol de accesibilidad y a los rastreadores
        // web. ExcludeSemantics evita que los textos hijos generen entradas
        // individuales redundantes. El diseño visual no cambia.
        child: Semantics(
          header: true,
          label: 'Prímari — Marketplace del sector primario. Compra y vende sin intermediarios.',
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'we',
                  style: GoogleFonts.notoSerif(
                    fontSize: 72,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: _kWe,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'are',
                  style: GoogleFonts.notoSerif(
                    fontSize: 72,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: _kAre,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  'Prímari',
                  style: GoogleFonts.notoSerif(
                    fontSize: 72,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    color: _kPrimari,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
