import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/utils/share_with_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../services/report_service.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(productDetailProvider(widget.productId));

    return detailAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: AppTheme.background, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: AppTheme.background, elevation: 0),
        body: Center(child: Text('Error al cargar el producto', style: GoogleFonts.manrope(color: AppTheme.error))),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(backgroundColor: AppTheme.background, elevation: 0),
            body: Center(child: Text('Producto no encontrado', style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant))),
          );
        }

        final product = detail.product;
        final images = detail.images;
        // La portada siempre la primera: isCover=true adelante, resto por sort_order
        final allImageUrls = images.isNotEmpty
            ? [
                ...images.where((i) => i.isCover),
                ...images.where((i) => !i.isCover),
              ].map((i) => i.imageUrl).toList()
            : [if (product.coverImageUrl != null) product.coverImageUrl!];
        final seller = detail.seller;

        return Scaffold(
          backgroundColor: AppTheme.background,
          extendBodyBehindAppBar: true,
          appBar: _DetailAppBar(
            title: product.title,
            productId: product.id,
            coverImageUrl: allImageUrls.isNotEmpty ? allImageUrls.first : null,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _ImageGallery(
                      imageUrls: allImageUrls,
                      currentIndex: _currentImageIndex,
                      onPageChanged: (i) => setState(() => _currentImageIndex = i),
                      category: product.categoryLabel,
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 96,
                      right: 16,
                      child: _ReportButton(
                        productId: product.id,
                        sellerId: product.sellerId,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title, style: GoogleFonts.notoSerif(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(product.priceLabel, style: GoogleFonts.notoSerif(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          const SizedBox(width: 6),
                          Text('/ ${product.unit}', style: GoogleFonts.manrope(fontSize: 16, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SpecsGrid(product: product),
                      const SizedBox(height: 24),
                      Text('Descripción', style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const SizedBox(height: 12),
                      Text(product.description, style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.onSurfaceVariant, height: 1.6)),
                      const SizedBox(height: 32),
                      if (seller != null) ...[
                        _SellerBlock(seller: seller, sellerId: product.sellerId),
                        const SizedBox(height: 24),
                      ],
                      _LocationBlock(city: product.city, postalCode: product.postalCode),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _BottomBar(seller: seller, productId: product.id),
        );
      },
    );
  }
}

class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String productId;
  final String? coverImageUrl;
  const _DetailAppBar({required this.title, required this.productId, this.coverImageUrl});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  Future<void> _shareProduct() async {
    const base = 'https://www.weareprimari.com/producto';
    final url = '$base/$productId';
    final text = '$title\n$url';

    // En web: solo texto + URL
    if (kIsWeb) {
      Share.share(text, subject: title);
      return;
    }

    // En móvil: intentar compartir con imagen, fallback a solo texto
    await shareWithImage(
      text: text,
      subject: title,
      imageUrl: coverImageUrl,
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
                    IconButton(icon: const Icon(Icons.arrow_back_ios_new), color: AppTheme.primary, onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
                    Expanded(child: Text(title, style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      color: AppTheme.primary,
                      onPressed: _shareProduct,
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

class _ImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final int currentIndex;
  final void Function(int) onPageChanged;
  final String category;

  const _ImageGallery({required this.imageUrls, required this.currentIndex, required this.onPageChanged, required this.category});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.width > 600 ? 400.0 : 300.0;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrls.isEmpty
              ? Container(color: AppTheme.surfaceContainerHigh, child: const Icon(Icons.image_outlined, size: 64, color: AppTheme.onSurfaceVariant))
              : PageView.builder(
                  itemCount: imageUrls.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => _openFullscreen(ctx, imageUrls, i),
                    child: Image.network(imageUrls[i], fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(color: AppTheme.surfaceContainerHigh, child: const Icon(Icons.image_not_supported_outlined, size: 48, color: AppTheme.onSurfaceVariant))),
                  ),
                ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 96,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.tertiaryFixed, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.eco_rounded, size: 12, color: AppTheme.tertiary),
                const SizedBox(width: 4),
                Text(category.toUpperCase(), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
              ]),
            ),
          ),
          if (imageUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageUrls.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == currentIndex ? Colors.white : Colors.white.withAlpha(120), borderRadius: BorderRadius.circular(999)),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  final Product product;
  const _SpecsGrid({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _SpecCell(icon: Icons.straighten_outlined, label: 'UNIDAD', value: product.unit)),
          Container(width: 1, height: 40, color: AppTheme.outlineVariant),
          Expanded(child: _SpecCell(icon: Icons.local_shipping_outlined, label: 'ENTREGA', value: product.deliveryLabel)),
          Container(width: 1, height: 40, color: AppTheme.outlineVariant),
          Expanded(child: _SpecCell(icon: Icons.location_on_outlined, label: 'LUGAR', value: product.city.isEmpty ? 'No indicado' : product.city)),
        ],
      ),
    );
  }
}

class _SpecCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SpecCell({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 20, color: AppTheme.primary),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurface), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
    ]);
  }
}

class _SellerBlock extends StatelessWidget {
  final Map<String, dynamic> seller;
  final String sellerId;
  const _SellerBlock({required this.seller, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final name = seller['display_name'] as String? ?? 'Vendedor';
    final city = seller['city'] as String? ?? '';
    final avatarUrl = seller['avatar_url'] as String?;

    return GestureDetector(
      onTap: () => context.push('/vendedor/$sellerId'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor: AppTheme.surfaceContainerHigh,
            child: avatarUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
            if (city.isNotEmpty) Row(children: [
              Icon(Icons.location_on_outlined, size: 12, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 2),
              Text(city, style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.onSurfaceVariant)),
            ]),
          ])),
          Icon(Icons.chevron_right, color: AppTheme.outline, size: 20),
        ]),
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  final String city;
  final String postalCode;
  const _LocationBlock({required this.city, required this.postalCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.map_outlined, color: AppTheme.primary, size: 24),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ubicación', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
          Text(
            city.isEmpty ? 'No indicada' : '$city${postalCode.isNotEmpty ? ' · $postalCode' : ''}',
            style: GoogleFonts.notoSerif(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
          ),
        ]),
      ]),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final Map<String, dynamic>? seller;
  final String productId;
  const _BottomBar({this.seller, required this.productId});

  Future<void> _openWhatsApp() async {
    final phone = seller?['phone'] as String?;
    if (phone == null || phone.isEmpty) return;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isFav = ref.watch(favoriteIdsProvider).valueOrNull?.contains(productId) ?? false;

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))]),
      child: Row(children: [
        // Favorito — botón pequeño a la izquierda
        ElevatedButton(
          onPressed: () {
            if (user == null) {
              context.push('/login');
              return;
            }
            ref.read(favoriteIdsProvider.notifier).toggle(productId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isFav ? AppTheme.primaryContainer : AppTheme.surfaceContainerHigh,
            foregroundColor: isFav ? Colors.white : AppTheme.primary,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        // Contactar — botón grande a la derecha
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openWhatsApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.chat_outlined, size: 20),
            label: Text('Contactar',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

// ─── Reporte de producto ──────────────────────────────────────────────────────

const _kReasons = [
  'Fraude o estafa',
  'Producto falso o engañoso',
  'Contenido inapropiado',
  'No pertenece al sector primario',
  'Información falsa',
  'Spam o anuncio duplicado',
  'Otro',
];

class _ReportButton extends ConsumerWidget {
  final String productId;
  final String sellerId;
  const _ReportButton({required this.productId, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(90),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 20,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onPressed: () async {
          final user = ref.read(currentUserProvider);
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Inicia sesión para reportar un producto',
                  style: GoogleFonts.manrope()),
            ));
            return;
          }
          if (user.id == sellerId) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('No puedes reportar tu propio producto',
                  style: GoogleFonts.manrope()),
            ));
            return;
          }
          final reported = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) =>
                _ReportSheet(productId: productId, sellerId: sellerId),
          );
          if (reported == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                'Tu reporte se ha enviado correctamente. Lo revisaremos.',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 5),
            ));
          }
        },
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  final String productId;
  final String sellerId;
  const _ReportSheet({required this.productId, required this.sellerId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selectedReason;
  final _detailsCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _loading = true);
    try {
      await ReportService().submitReport(
        productId: widget.productId,
        sellerId: widget.sellerId,
        reason: _selectedReason!,
        details: _detailsCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      debugPrint('Report submit error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al enviar el reporte. Inténtalo de nuevo.',
              style: GoogleFonts.manrope()),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Text('Reportar producto',
                      style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Selecciona el motivo de tu reporte:',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  ..._kReasons.map((r) => GestureDetector(
                        onTap: () => setState(() => _selectedReason = r),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedReason == r
                                      ? AppTheme.primary
                                      : AppTheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                              child: _selectedReason == r
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(r,
                                  style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: AppTheme.onSurface)),
                            ),
                          ]),
                        ),
                      )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _detailsCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Comentario adicional (opcional)',
                      hintStyle: GoogleFonts.manrope(
                          color: AppTheme.onSurfaceVariant, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      counterStyle: GoogleFonts.manrope(fontSize: 11),
                    ),
                    style: GoogleFonts.manrope(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        (_selectedReason == null || _loading) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.primary.withAlpha(80),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Enviar reporte',
                            style:
                                GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancelar',
                        style: GoogleFonts.manrope(
                            color: AppTheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Visor de imágenes a pantalla completa ────────────────────────────────────

void _openFullscreen(BuildContext context, List<String> imageUrls, int initialIndex) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierColor: Colors.black,
      pageBuilder: (ctx, animation, secondaryAnimation) => _FullscreenGallery(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _FullscreenGallery({required this.imageUrls, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.imageUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14),
              )
            : null,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.imageUrls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, st) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white30,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentIndex ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
