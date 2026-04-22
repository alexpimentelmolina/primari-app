import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';

// ─── Entry en memoria para imagen pendiente de subir ─────────────────────────
class _PendingImage {
  final XFile file;
  final Uint8List bytes;
  _PendingImage({required this.file, required this.bytes});
}

// ─────────────────────────────────────────────────────────────────────────────
class PublishProductScreen extends ConsumerStatefulWidget {
  const PublishProductScreen({super.key});

  @override
  ConsumerState<PublishProductScreen> createState() =>
      _PublishProductScreenState();
}

class _PublishProductScreenState
    extends ConsumerState<PublishProductScreen> {
  // Form
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;
  String _selectedUnit = 'kg';
  String? _deliveryType;

  // Imágenes
  final List<_PendingImage> _images = [];
  int _coverIndex = 0;

  bool _isLoading = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 8) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _images.add(_PendingImage(file: file, bytes: bytes)));
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (_coverIndex >= _images.length) _coverIndex = 0;
    });
  }

  void _setCover(int index) => setState(() => _coverIndex = index);

  String? _validate() {
    if (_images.isEmpty) return 'Añade al menos una imagen.';
    if (_titleController.text.trim().isEmpty) return 'El título es obligatorio.';
    if (_descriptionController.text.trim().isEmpty) {
      return 'La descripción es obligatoria.';
    }
    final price = double.tryParse(
        _priceController.text.trim().replaceAll(',', '.'));
    if (price == null || price <= 0) return 'Introduce un precio válido.';
    if (_selectedCategory == null) return 'Selecciona una categoría.';
    if (_deliveryType == null) return 'Selecciona el tipo de entrega.';
    return null;
  }

  Future<void> _publish() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = ref.read(profileProvider).valueOrNull;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final imageService = ref.read(imageServiceProvider);
      final productService = ref.read(productServiceProvider);

      // 1. Subir imágenes
      final urls = <String>[];
      for (final img in _images) {
        final url = await imageService.uploadImage(img.file, user.id);
        urls.add(url);
      }

      // 2. Crear producto
      final price = double.parse(
          _priceController.text.trim().replaceAll(',', '.'));

      final productId = await productService.createProduct({
        'seller_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'unit': _selectedUnit,
        'category': _selectedCategory,
        'delivery_type': _deliveryType,
        'city': profile?.city ?? '',
        'postal_code': profile?.postalCode ?? '',
        'status': 'active',
        'cover_image_url': urls[_coverIndex],
      });

      // 3. Guardar registros de imágenes
      final imageRecords = urls.asMap().entries.map((e) => {
            'product_id': productId,
            'image_url': e.value,
            'sort_order': e.key,
            'is_cover': e.key == _coverIndex,
          }).toList();

      await productService.replaceImages(productId, imageRecords);

      // 4. Geocodificar ubicación en background (fire-and-forget)
      final city = profile?.city ?? '';
      final postalCode = profile?.postalCode ?? '';
      () async {
        await productService.geocodeAndUpdateCoords(productId, city, postalCode);
      }();

      // 5. Invalidar providers
      ref.invalidate(activeProductsProvider);
      ref.invalidate(myProductsProvider);

      if (mounted) context.go('/home');
    } catch (e) {
      setState(
          () => _error = 'Error al publicar el producto. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _PublishAppBar(
        onClose: () => context.pop(),
        onPublish: _isLoading ? null : _publish,
        isLoading: _isLoading,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 88),
            _SectionHeader(
              title: 'Muestra tu producto',
              subtitle: '${_images.length}/8 imágenes · toca para añadir',
            ),
            const SizedBox(height: 16),
            _PhotoGrid(
              images: _images,
              coverIndex: _coverIndex,
              onAdd: _images.length < 8 ? _pickImage : null,
              onRemove: _removeImage,
              onSetCover: _setCover,
            ),
            const SizedBox(height: 24),
            _FormContainer(
              titleController: _titleController,
              descriptionController: _descriptionController,
              priceController: _priceController,
              selectedUnit: _selectedUnit,
              onUnitChanged: (val) =>
                  setState(() => _selectedUnit = val ?? _selectedUnit),
            ),
            const SizedBox(height: 32),
            _SectionHeader(
              title: 'Categoría',
              subtitle: 'Selecciona la que mejor describe tu producto',
            ),
            const SizedBox(height: 16),
            _CategoryGrid(
              selected: _selectedCategory,
              onSelect: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 32),
            _SectionHeader(
              title: 'Tipo de entrega',
              subtitle: '¿Cómo puede conseguir el comprador tu producto?',
            ),
            const SizedBox(height: 16),
            _DeliverySelector(
              selected: _deliveryType,
              onSelect: (val) => setState(() => _deliveryType = val),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: _PublishBottomBar(
        onPublish: _isLoading ? null : _publish,
        isLoading: _isLoading,
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────
class _PublishAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onClose;
  final VoidCallback? onPublish;
  final bool isLoading;

  const _PublishAppBar({
    required this.onClose,
    required this.onPublish,
    this.isLoading = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppTheme.background.withAlpha(204),
          child: SafeArea(
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppTheme.onSurface,
                      onPressed: onClose,
                    ),
                    const Spacer(),
                    Text(
                      'Nuevo producto',
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: AppTheme.primary, strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: onPublish,
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                            ),
                            child: Text(
                              'Publicar',
                              style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold),
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

// ─── Photo grid ───────────────────────────────────────────────────────────────
class _PhotoGrid extends StatelessWidget {
  final List<_PendingImage> images;
  final int coverIndex;
  final VoidCallback? onAdd;
  final void Function(int) onRemove;
  final void Function(int) onSetCover;

  const _PhotoGrid({
    required this.images,
    required this.coverIndex,
    required this.onAdd,
    required this.onRemove,
    required this.onSetCover,
  });

  @override
  Widget build(BuildContext context) {
    // Slots: first is "hero" (full height left), remaining 4 small (2x2 right)
    final allSlots = List.generate(8, (i) => i);

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 500;
      if (isWide) {
        return SizedBox(
          height: 300,
          child: Row(
            children: [
              // Main slot
              Expanded(
                flex: 2,
                child: _ImageSlot(
                  index: 0,
                  image: images.isNotEmpty ? images[0] : null,
                  isCover: coverIndex == 0,
                  onAdd: images.isEmpty ? onAdd : null,
                  onRemove: () => onRemove(0),
                  onSetCover: () => onSetCover(0),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Secondary slots (2x2)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    for (int row = 0; row < 2; row++) ...[
                      if (row > 0) const SizedBox(height: 4),
                      Expanded(
                        child: Row(
                          children: [
                            for (int col = 0; col < 2; col++) ...[
                              if (col > 0) const SizedBox(width: 4),
                              Expanded(
                                child: () {
                                  final i = 1 + row * 2 + col;
                                  return _ImageSlot(
                                    index: i,
                                    image: images.length > i ? images[i] : null,
                                    isCover: coverIndex == i,
                                    onAdd: images.length == i ? onAdd : null,
                                    onRemove: () => onRemove(i),
                                    onSetCover: () => onSetCover(i),
                                    borderRadius: _cornerRadius(i),
                                  );
                                }(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Narrow: wrap grid
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: allSlots.map((i) {
          final size = (constraints.maxWidth - 12) / 3;
          return SizedBox(
            width: size,
            height: size,
            child: _ImageSlot(
              index: i,
              image: images.length > i ? images[i] : null,
              isCover: coverIndex == i,
              onAdd: images.length == i ? onAdd : null,
              onRemove: () => onRemove(i),
              onSetCover: () => onSetCover(i),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }).toList(),
      );
    });
  }

  BorderRadius _cornerRadius(int i) {
    return switch (i) {
      1 => const BorderRadius.only(topRight: Radius.circular(24)),
      4 => const BorderRadius.only(bottomRight: Radius.circular(24)),
      _ => BorderRadius.zero,
    };
  }
}

class _ImageSlot extends StatelessWidget {
  final int index;
  final _PendingImage? image;
  final bool isCover;
  final VoidCallback? onAdd;
  final VoidCallback onRemove;
  final VoidCallback onSetCover;
  final BorderRadius borderRadius;

  const _ImageSlot({
    required this.index,
    required this.image,
    required this.isCover,
    required this.onAdd,
    required this.onRemove,
    required this.onSetCover,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;

    if (!hasImage && index > 0 && onAdd == null) {
      // Slot vacío no alcanzable aún
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(color: AppTheme.surfaceContainer),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: GestureDetector(
        onTap: !hasImage ? onAdd : null,
        child: Container(
          color: AppTheme.surfaceContainerHigh,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(image!.bytes, fit: BoxFit.cover),
                    // Cover badge
                    if (isCover)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'PORTADA',
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Actions menu
                    Positioned(
                      top: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.more_vert,
                              color: Colors.white, size: 16),
                        ),
                        onSelected: (val) {
                          if (val == 'cover') onSetCover();
                          if (val == 'remove') onRemove();
                        },
                        itemBuilder: (ctx) => [
                          if (!isCover)
                            const PopupMenuItem(
                              value: 'cover',
                              child: Text('Usar como portada'),
                            ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      index == 0
                          ? Icons.add_photo_alternate_outlined
                          : Icons.add,
                      color: AppTheme.onSurfaceVariant,
                      size: index == 0 ? 36 : 24,
                    ),
                    if (index == 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Añadir foto',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Formulario de campos de texto ───────────────────────────────────────────
class _FormContainer extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final String selectedUnit;
  final ValueChanged<String?> onUnitChanged;

  const _FormContainer({
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  static InputDecoration _fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
            fontSize: 14, color: AppTheme.onSurfaceVariant),
        filled: true,
        fillColor: AppTheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'TÍTULO *'),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            decoration: _fieldDeco('Ej. Tomates de temporada'),
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          const SizedBox(height: 20),
          _FieldLabel(label: 'DESCRIPCIÓN *'),
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: _fieldDeco(
                'Describe tu producto: origen, características, cómo se produce...'),
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'PRECIO *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          _fieldDeco('0,00').copyWith(prefixText: '€ '),
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'UNIDAD *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: _fieldDeco(''),
                      style: GoogleFonts.manrope(
                          fontSize: 14, color: AppTheme.onSurface),
                      items: Product.units
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u),
                              ))
                          .toList(),
                      onChanged: onUnitChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Selección de categoría ───────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;

  const _CategoryGrid({required this.selected, required this.onSelect});

  static const _icons = {
    'frutas y verduras': Icons.eco_rounded,
    'huevos': Icons.egg_alt_outlined,
    'miel': Icons.hive_rounded,
    'carne': Icons.restaurant_rounded,
    'pescado y marisco': Icons.set_meal_outlined,
    'quesos y lácteos': Icons.water_drop_outlined,
    'aceite': Icons.opacity_outlined,
    'panadería y repostería artesanal': Icons.bakery_dining_rounded,
    'conservas y elaborados artesanales': Icons.inventory_2_outlined,
    'otros': Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: Product.categories.map((cat) {
        final isSelected = selected == cat;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icons[cat] ?? Icons.category_outlined,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  cat[0].toUpperCase() + cat.substring(1),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Selector de tipo de entrega ──────────────────────────────────────────────
class _DeliverySelector extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;

  const _DeliverySelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Product.deliveryOptions.entries.map((e) {
        final isSelected = selected == e.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryContainer.withAlpha(30)
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    e.key == 'shipping'
                        ? Icons.local_shipping_outlined
                        : e.key == 'in_person'
                            ? Icons.storefront_outlined
                            : Icons.swap_horiz_rounded,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    e.value,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.primary, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.onSurface,
          letterSpacing: 1.2,
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishBottomBar extends StatelessWidget {
  final VoidCallback? onPublish;
  final bool isLoading;
  const _PublishBottomBar({required this.onPublish, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
            top: BorderSide(color: AppTheme.outlineVariant, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPublish,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.primary.withAlpha(100),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'Publicar producto',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
