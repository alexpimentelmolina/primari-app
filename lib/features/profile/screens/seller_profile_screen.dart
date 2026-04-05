import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(sellerProfileProvider(sellerId));
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _SellerAppBar(),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, st) => Center(
          child: Text('Error al cargar el perfil',
              style: GoogleFonts.manrope(color: AppTheme.error)),
        ),
        data: (seller) {
          if (seller == null) {
            return Center(
              child: Text('Vendedor no encontrado',
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurfaceVariant)),
            );
          }

          final name = seller['display_name'] as String? ?? 'Vendedor';
          final city = seller['city'] as String? ?? '';
          final avatarUrl = seller['avatar_url'] as String?;
          final bio = seller['bio'] as String?;
          final phone = seller['phone'] as String?;
          final isBusiness = seller['account_type'] == 'business';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 96),
                // Header del vendedor
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Avatar
                      Center(
                        child: CircleAvatar(
                          radius: 56,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          child: avatarUrl == null
                              ? Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: GoogleFonts.notoSerif(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (city.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on,
                                size: 14,
                                color: AppTheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              city.toUpperCase(),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                letterSpacing: 1.2,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryFixed,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBusiness
                                  ? Icons.business
                                  : Icons.eco,
                              size: 13,
                              color: AppTheme.tertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isBusiness
                                  ? 'EMPRESA VERIFICADA'
                                  : 'PRODUCTOR VERIFICADO',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bio != null && bio.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppTheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                      ],
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _WhatsAppButton(phone: phone),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/vendedor/$sellerId/resenas'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.outline),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.star_outline_rounded, size: 18),
                          label: Text(
                            'Ver valoraciones',
                            style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Productos del vendedor
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Productos',
                    style: GoogleFonts.notoSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                productsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: AppTheme.primary),
                    ),
                  ),
                  error: (e, st) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error al cargar productos',
                        style: GoogleFonts.manrope(
                            color: AppTheme.onSurfaceVariant)),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Este vendedor aún no tiene productos activos.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                                color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length,
                      itemBuilder: (ctx, i) =>
                          _ProductCard(product: products[i]),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SellerAppBar extends StatelessWidget implements PreferredSizeWidget {
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppTheme.primary,
                      onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                    ),
                    Text(
                      'Perfil del vendedor',
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
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

class _WhatsAppButton extends StatelessWidget {
  final String phone;
  const _WhatsAppButton({required this.phone});

  Future<void> _open() async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _open,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.chat_outlined, size: 20),
        label: Text(
          'Contactar por WhatsApp',
          style:
              GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/producto/${product.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: AppTheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: product.coverImageUrl != null
                    ? Image.network(
                        product.coverImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        cacheWidth: 340,
                        cacheHeight: 340,
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
              ),
              Padding(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 4),
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

