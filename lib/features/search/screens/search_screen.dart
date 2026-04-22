import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  final String? initialCategory;
  final int? initialMaxDistanceKm;
  /// Términos de temporada: filtran resultados internamente pero NO
  /// rellenan el TextField visible del buscador.
  final List<String> initialSeasonalTerms;
  const SearchScreen({
    super.key,
    this.initialQuery = '',
    this.initialCategory,
    this.initialMaxDistanceKm,
    this.initialSeasonalTerms = const [],
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryCtrl;
  late final TextEditingController _cityCtrl;
  String _query = '';
  String? _category;
  String _city = '';

  // GPS
  double? _userLat;
  double? _userLng;
  int? _maxDistanceKm;
  bool _isGettingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialQuery);
    _cityCtrl = TextEditingController();
    // Si hay una query explícita la usamos; si no, usamos seasonal_terms
    // como filtro interno sin mostrarlos en el TextField.
    _query = widget.initialQuery.trim().isNotEmpty
        ? widget.initialQuery.trim()
        : widget.initialSeasonalTerms.join(' ').trim();
    _category = widget.initialCategory;
    _maxDistanceKm = widget.initialMaxDistanceKm;
    // Si viene con un radio preseleccionado desde Home, pide GPS automáticamente
    if (widget.initialMaxDistanceKm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _getLocation();
      });
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  SearchFilter get _filter => SearchFilter(
        query: _query,
        category: _category,
        city: _city,
        userLat: _userLat,
        userLng: _userLng,
        // 0 = "100+ km" (chip seleccionado pero sin límite real → global)
        maxDistanceKm: (_maxDistanceKm == null || _maxDistanceKm == 0)
            ? null
            : _maxDistanceKm,
      );

  Future<void> _getLocation() async {
    // ── Caché de sesión: si ya tenemos coords, las reutilizamos al instante ──
    final cached = ref.read(cachedGpsProvider);
    if (cached != null) {
      setState(() {
        _userLat = cached.lat;
        _userLng = cached.lng;
        _maxDistanceKm ??= 50;
      });
      return;
    }

    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });
    try {
      // En apps nativas hay que solicitar el permiso explícitamente antes de
      // llamar a getCurrentPosition (en web el navegador lo gestiona solo).
      if (!kIsWeb) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          setState(() {
            _locationError = permission == LocationPermission.deniedForever
                ? 'Permiso denegado permanentemente. Actívalo en Ajustes > Privacidad > Ubicación.'
                : 'Permiso de ubicación denegado.';
            _isGettingLocation = false;
          });
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      // Guardar en caché para las siguientes búsquedas de esta sesión
      ref.read(cachedGpsProvider.notifier).state =
          (lat: pos.latitude, lng: pos.longitude);
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _maxDistanceKm ??= 50;
        _isGettingLocation = false;
      });
    } on LocationServiceDisabledException {
      if (!mounted) return;
      setState(() {
        _locationError = 'Los servicios de ubicación están desactivados.';
        _isGettingLocation = false;
      });
    } on PermissionDeniedException {
      if (!mounted) return;
      setState(() {
        _locationError = kIsWeb
            ? 'Permiso denegado. Actívalo en la configuración del navegador.'
            : 'Permiso denegado. Actívalo en Ajustes > Privacidad > Ubicación.';
        _isGettingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = 'No se pudo obtener la ubicación. Inténtalo de nuevo.';
        _isGettingLocation = false;
      });
    }
  }

  void _clearLocation() {
    setState(() {
      _userLat = null;
      _userLng = null;
      _maxDistanceKm = null;
      _locationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _SearchAppBar(
        controller: _queryCtrl,
        onChanged: (v) => setState(() => _query = v.trim()),
        onClear: () {
          _queryCtrl.clear();
          setState(() => _query = '');
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 72),
          // Chips de categoría
          _CategoryFilterRow(
            selected: _category,
            onSelect: (cat) => setState(() => _category = cat),
          ),
          // Filtro por ciudad (texto)
          _CityFilterRow(
            controller: _cityCtrl,
            onChanged: (v) => setState(() => _city = v.trim()),
            onClear: () {
              _cityCtrl.clear();
              setState(() => _city = '');
            },
          ),
          // Búsqueda por distancia (GPS)
          _DistanceRow(
            userLat: _userLat,
            maxDistanceKm: _maxDistanceKm,
            isGettingLocation: _isGettingLocation,
            locationError: _locationError,
            onGetLocation: _getLocation,
            onSelectDistance: (km) => setState(() => _maxDistanceKm = km),
            onClearLocation: _clearLocation,
          ),
          // Resultados
          Expanded(
            child: _isGettingLocation && !_filter.hasFilter
                ? const _LocationLoading()
                : _filter.hasFilter
                    ? _SearchResults(filter: _filter)
                    : const _AllProductsList(),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}

// ── AppBar con campo de búsqueda ──────────────────────────────────────────────

class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchAppBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                color: AppTheme.onSurfaceVariant, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                autofocus: true,
                                onChanged: onChanged,
                                style: GoogleFonts.manrope(
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Buscar productos...',
                                  hintStyle: GoogleFonts.manrope(
                                    color: AppTheme.onSurfaceVariant
                                        .withAlpha(153),
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (controller.text.isNotEmpty)
                              GestureDetector(
                                onTap: onClear,
                                child: const Icon(Icons.close,
                                    color: AppTheme.onSurfaceVariant, size: 18),
                              ),
                          ],
                        ),
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

// ── Fila de filtro por categoría ──────────────────────────────────────────────

class _CategoryFilterRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _CategoryFilterRow({required this.selected, required this.onSelect});

  static const _icons = <String, IconData>{
    'frutas y verduras': Icons.eco_rounded,
    'huevos': Icons.egg_rounded,
    'miel': Icons.hive_rounded,
    'carne': Icons.lunch_dining,
    'pescado y marisco': Icons.set_meal_rounded,
    'quesos y lácteos': Icons.local_drink_rounded,
    'aceite': Icons.water_drop_rounded,
    'panadería y repostería artesanal': Icons.bakery_dining,
    'conservas y elaborados artesanales': Icons.inventory_2_outlined,
    'otros': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'Todas',
            icon: Icons.apps_rounded,
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...Product.categories.map((cat) => _CategoryChip(
                label: cat[0].toUpperCase() + cat.substring(1),
                icon: _icons[cat] ?? Icons.circle_outlined,
                isSelected: selected == cat,
                onTap: () => onSelect(selected == cat ? null : cat),
              )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de filtro por ciudad ─────────────────────────────────────────────────

class _CityFilterRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _CityFilterRow({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 16, color: AppTheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Filtrar por ciudad o código postal',
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant.withAlpha(153),
                  ),
                  border: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 16, color: AppTheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de búsqueda por distancia (GPS) ──────────────────────────────────────

class _DistanceRow extends StatelessWidget {
  final double? userLat;
  final int? maxDistanceKm;
  final bool isGettingLocation;
  final String? locationError;
  final VoidCallback onGetLocation;
  final ValueChanged<int?> onSelectDistance;
  final VoidCallback onClearLocation;

  const _DistanceRow({
    required this.userLat,
    required this.maxDistanceKm,
    required this.isGettingLocation,
    required this.locationError,
    required this.onGetLocation,
    required this.onSelectDistance,
    required this.onClearLocation,
  });

  // 0 = sin límite de distancia (global)
  static const _kms = [
    (10, '0–10 km'),
    (25, '25 km'),
    (50, '50 km'),
    (0, '100+ km'),
  ];

  @override
  Widget build(BuildContext context) {
    final locationActive = userLat != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón GPS
          GestureDetector(
            onTap: isGettingLocation ? null : onGetLocation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: locationActive
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isGettingLocation)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  else
                    Icon(
                      locationActive
                          ? Icons.my_location_rounded
                          : Icons.near_me_outlined,
                      size: 15,
                      color: locationActive
                          ? Colors.white
                          : AppTheme.onSurfaceVariant,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    locationActive
                        ? 'Ubicación activa'
                        : 'Buscar cerca de mí',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: locationActive
                          ? Colors.white
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                  if (locationActive) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onClearLocation,
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Error de permiso / servicio
          if (locationError != null) ...[
            const SizedBox(height: 4),
            Text(
              locationError!,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.error,
              ),
            ),
          ],
          // Chips de radio (solo cuando GPS activo)
          if (locationActive) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kms.map((entry) {
                  final (km, label) = entry;
                  final selected = maxDistanceKm == km;
                  return GestureDetector(
                    onTap: () => onSelectDistance(selected ? null : km),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryContainer
                            : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
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
            ),
          ],
        ],
      ),
    );
  }
}

// ── Todos los productos (sin filtro activo) ───────────────────────────────────

class _AllProductsList extends ConsumerWidget {
  const _AllProductsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(activeProductsProvider);
    return productsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(
        child: Text(
          'Error al cargar productos.',
          style: GoogleFonts.manrope(color: AppTheme.error),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Text(
              'Todavía no hay productos.',
              style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          itemCount: products.length,
          separatorBuilder: (i, s) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => _SearchResultCard(product: products[i]),
        );
      },
    );
  }
}

// ── Cargando ubicación GPS ────────────────────────────────────────────────────

class _LocationLoading extends StatelessWidget {
  const _LocationLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            'Obteniendo tu ubicación...',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resultados de búsqueda ────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  final SearchFilter filter;
  const _SearchResults({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchProductsProvider(filter));

    return resultsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, st) => Center(
        child: Text(
          'Error al buscar. Inténtalo de nuevo.',
          style: GoogleFonts.manrope(color: AppTheme.error),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 64, color: AppTheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Sin resultados',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prueba con otros términos o quita algún filtro.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          itemCount: products.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => _SearchResultCard(product: products[i]),
        );
      },
    );
  }
}

// ── Tarjeta de resultado ──────────────────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  final Product product;
  const _SearchResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => kIsWeb ? context.go('/producto/${product.id}') : context.push('/producto/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: product.coverImageUrl != null
                    ? Image.network(
                        product.coverImageUrl!,
                        fit: BoxFit.cover,
                        cacheWidth: 200,
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
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.notoSerif(
                        fontSize: 15,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                    if (product.city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppTheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              product.city,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right,
                  color: AppTheme.outline, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
