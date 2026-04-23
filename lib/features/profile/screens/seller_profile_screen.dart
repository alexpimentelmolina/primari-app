import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/share_with_image.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';
import '../../reviews/providers/reviews_provider.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(sellerProfileProvider(sellerId));
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));
    final ratingSummaryAsync = ref.watch(sellerRatingSummaryProvider(sellerId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _SellerAppBar(
        sellerId: sellerId,
        sellerName: profileAsync.valueOrNull?['display_name'] as String?,
        avatarUrl: profileAsync.valueOrNull?['avatar_url'] as String?,
      ),
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

          return LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktopWeb = kIsWeb && w > 900;
            final columns = isDesktopWeb ? (w >= 1400 ? 5 : w >= 1100 ? 4 : 3) : 2;
            Widget wideButton(Widget child) => isDesktopWeb
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: child,
                    ),
                  )
                : SizedBox(width: double.infinity, child: child);
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktopWeb ? 1200.0 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 96),
                // Header del vendedor
                if (isDesktopWeb)
                  // ── DESKTOP: foto izquierda + datos derecha ──────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar rectangular grande
                        ClipOval(
                          child: SizedBox(
                            width: 260,
                            height: 260,
                            child: avatarUrl != null
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => _AvatarFallback(name: name),
                                  )
                                : _AvatarFallback(name: name),
                          ),
                        ),
                        const SizedBox(width: 48),
                        // Info derecha
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge + ciudad en la misma fila
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.tertiaryFixed,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isBusiness ? Icons.business : Icons.eco, size: 13, color: AppTheme.tertiary),
                                        const SizedBox(width: 6),
                                        Text(
                                          isBusiness ? 'EMPRESA' : 'PRODUCTOR PARTICULAR',
                                          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.tertiary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (city.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    Icon(Icons.location_on, size: 14, color: AppTheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      city.toUpperCase(),
                                      style: GoogleFonts.manrope(fontSize: 12, letterSpacing: 1.2, color: AppTheme.onSurfaceVariant),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Nombre grande
                              Text(
                                name,
                                style: GoogleFonts.notoSerif(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                              ),
                              if (bio != null && bio.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  bio,
                                  style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.onSurfaceVariant, height: 1.6),
                                ),
                              ],
                              const SizedBox(height: 24),
                              // ── Métricas: productos activos + valoración ──
                              Row(
                                children: [
                                  // Productos activos
                                  _MetricCard(
                                    label: 'PRODUCTOS ACTIVOS',
                                    value: productsAsync.when(
                                      data: (p) => '${p.length}',
                                      loading: () => '—',
                                      error: (e, _) => '—',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Media de valoraciones
                                  _MetricCard(
                                    label: 'VALORACIÓN MEDIA',
                                    value: ratingSummaryAsync.when(
                                      data: (s) => s.$2 == 0 ? 'Sin reseñas' : '${s.$1.toStringAsFixed(1)} ★',
                                      loading: () => '—',
                                      error: (e, _) => '—',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              // Botones en fila horizontal
                              Row(
                                children: [
                                  if (phone != null && phone.isNotEmpty) ...[
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 240),
                                      child: _WhatsAppButton(phone: phone),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  OutlinedButton.icon(
                                    onPressed: () => kIsWeb ? context.go('/vendedor/$sellerId/resenas') : context.push('/vendedor/$sellerId/resenas'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.outline),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                    ),
                                    icon: const Icon(Icons.star_outline_rounded, size: 18),
                                    label: Text('Ver valoraciones', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // ── MÓVIL: layout original sin tocar ─────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Avatar
                        Center(
                          child: CircleAvatar(
                            radius: 56,
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            child: avatarUrl == null
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: GoogleFonts.notoSerif(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: GoogleFonts.notoSerif(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        if (city.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, size: 14, color: AppTheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                city.toUpperCase(),
                                style: GoogleFonts.manrope(fontSize: 12, letterSpacing: 1.2, color: AppTheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: AppTheme.tertiaryFixed, borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isBusiness ? Icons.business : Icons.eco, size: 13, color: AppTheme.tertiary),
                              const SizedBox(width: 6),
                              Text(
                                isBusiness ? 'EMPRESA' : 'PRODUCTOR PARTICULAR',
                                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.tertiary),
                              ),
                            ],
                          ),
                        ),
                        if (bio != null && bio.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(bio, textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.6)),
                        ],
                        if (phone != null && phone.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          wideButton(_WhatsAppButton(phone: phone)),
                        ],
                        const SizedBox(height: 12),
                        wideButton(OutlinedButton.icon(
                          onPressed: () => kIsWeb ? context.go('/vendedor/$sellerId/resenas') : context.push('/vendedor/$sellerId/resenas'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.outline),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.star_outline_rounded, size: 18),
                          label: Text('Ver valoraciones', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14)),
                        )),
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
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                        mainAxisExtent: isDesktopWeb ? 260.0 : null,
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
          ),
        ),
      );
    });
        },
      ),
    );
  }
}

class _SellerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String sellerId;
  final String? sellerName;
  final String? avatarUrl;

  const _SellerAppBar({
    required this.sellerId,
    this.sellerName,
    this.avatarUrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  Future<void> _share(BuildContext context) async {
    const base = 'https://www.weareprimari.com/vendedor';
    final url  = '$base/$sellerId';
    final name = sellerName ?? 'Productor en Prímari';
    final text = '$name\n$url';

    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? Rect.zero
        : box.localToGlobal(Offset.zero) & box.size;

    if (kIsWeb) {
      await Share.share(text, subject: name, sharePositionOrigin: origin);
      return;
    }

    await shareWithImage(
      text: text,
      subject: name,
      imageUrl: avatarUrl,
      sharePositionOrigin: origin,
    );
  }

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
                    Expanded(
                      child: Text(
                        sellerName ?? 'Perfil del vendedor',
                        style: GoogleFonts.notoSerif(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Builder(
                      builder: (btnCtx) => IconButton(
                        icon: const Icon(Icons.share_outlined),
                        color: AppTheme.primary,
                        onPressed: () => _share(btnCtx),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.notoSerif(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.notoSerif(fontSize: 80, fontWeight: FontWeight.bold, color: AppTheme.primary),
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
      onTap: () => kIsWeb ? context.go('/producto/${product.id}') : context.push('/producto/${product.id}'),
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

