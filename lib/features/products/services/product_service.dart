import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/geocoding_service.dart';
import '../models/product.dart';

class ProductService {
  SupabaseClient get _db => Supabase.instance.client;

  // ── Listados ────────────────────────────────────────────────────────────────

  Future<List<Product>> getActiveProducts() async {
    final data = await _db
        .from('products')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  /// Búsqueda principal: intenta la función RPC fuzzy (pg_trgm + Haversine).
  /// Si el SQL no está aplicado aún, cae en búsqueda básica ilike.
  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    String city = '',
    double? userLat,
    double? userLng,
    int? maxDistanceKm,
  }) async {
    final q = query.trim();
    final c = city.trim();
    if (q.isEmpty && category == null && c.isEmpty && userLat == null) return [];

    try {
      final params = <String, dynamic>{
        'p_query': q,
        'p_category': category,
        'p_city': c,
      };
      // Solo incluir coords y radio si están disponibles
      if (userLat != null) params['p_lat'] = userLat;
      if (userLng != null) params['p_lng'] = userLng;
      if (maxDistanceKm != null) params['p_max_km'] = maxDistanceKm;

      final data = await _db.rpc('search_products_fuzzy', params: params);
      return (data as List)
          .map((e) => Product.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback si la función RPC no existe todavía en Supabase
      return _searchBasic(query: q, category: category, city: c);
    }
  }

  /// Búsqueda básica ilike — también cubre postal_code en el filtro de ciudad.
  Future<List<Product>> _searchBasic({
    required String query,
    String? category,
    String city = '',
  }) async {
    var builder = _db.from('products').select().eq('status', 'active');
    if (query.isNotEmpty) {
      builder = builder.or('title.ilike.%$query%,description.ilike.%$query%');
    }
    if (category != null && category.isNotEmpty) {
      builder = builder.eq('category', category);
    }
    if (city.isNotEmpty) {
      builder =
          builder.or('city.ilike.%$city%,postal_code.ilike.%$city%');
    }
    final data =
        await builder.order('created_at', ascending: false).limit(50);
    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> getMyProducts(String sellerId) async {
    final data = await _db
        .from('products')
        .select()
        .eq('seller_id', sellerId)
        .neq('status', 'deleted')
        .order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> getMyActiveProducts(String sellerId) async {
    final data = await _db
        .from('products')
        .select()
        .eq('seller_id', sellerId)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> getSellerActiveProducts(String sellerId) async {
    final data = await _db
        .from('products')
        .select()
        .eq('seller_id', sellerId)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  // ── Detalle ─────────────────────────────────────────────────────────────────

  Future<ProductDetail?> getProductDetail(String id) async {
    final productData = await _db
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (productData == null) return null;

    final product = Product.fromMap(productData);

    final imagesData = await _db
        .from('product_images')
        .select()
        .eq('product_id', id)
        .order('sort_order');

    final images =
        (imagesData as List).map((e) => ProductImage.fromMap(e)).toList();

    final sellerData = await _db
        .from('profiles')
        .select('id, display_name, city, avatar_url, phone, bio, account_type')
        .eq('id', product.sellerId)
        .maybeSingle();

    return ProductDetail(
      product: product,
      images: images,
      seller: sellerData,
    );
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<String> createProduct(Map<String, dynamic> data) async {
    final result = await _db
        .from('products')
        .insert(data)
        .select('id')
        .single();
    return result['id'] as String;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.from('products').update(data).eq('id', id);
  }

  Future<void> updateStatus(String id, String status) async {
    final authUid = _db.auth.currentUser?.id;
    debugPrint('[Primari] updateStatus → id=$id  newStatus=$status  authUid=$authUid');

    Future<List<dynamic>> doUpdate() => _db
        .from('products')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select('id');

    try {
      final rows = await doUpdate();
      debugPrint('[Primari] updateStatus → rows devueltas: ${rows.length}  $rows');
      if (rows.isEmpty) {
        debugPrint('[Primari] updateStatus → 0 rows: UPDATE ok pero '
            'policy SELECT filtra la fila (status ya no es active). '
            'Aplica el SQL de corrección de policy SELECT en Supabase.');
        throw Exception('0_rows');
      }
      debugPrint('[Primari] updateStatus → OK ✓');
    } on PostgrestException catch (e) {
      debugPrint('[Primari] updateStatus → PostgrestException '
          'code=${e.code}  message=${e.message}  hint=${e.hint}');
      if (e.code == 'PGRST303') {
        // JWT expirado a nivel PostgREST: intentar refrescar y reintentar
        await _db.auth.refreshSession();
        final rows = await doUpdate();
        debugPrint('[Primari] updateStatus → post-refresh rows: ${rows.length}');
        if (rows.isEmpty) throw Exception('0_rows_after_refresh');
      } else if (e.code == '42501') {
        // WITH CHECK falló: auth.uid() = NULL en PostgreSQL.
        // El JWT es inválido o la sesión está vacía.
        // Lanzar AuthException directamente para que la UI fuerce re-login.
        debugPrint('[Primari] updateStatus → 42501: sesión sin JWT válido, forzando re-login');
        throw const AuthException('Sesión expirada. Inicia sesión de nuevo.');
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('[Primari] updateStatus → catch: ${e.runtimeType}: $e');
      rethrow;
    }
  }

  Future<void> softDelete(String id) => updateStatus(id, 'deleted');

  // ── Geocodificación ──────────────────────────────────────────────────────────

  /// Geocodifica la ubicación de un producto y guarda lat/lng.
  /// Llamar fire-and-forget: no bloquea el flujo principal.
  Future<void> geocodeAndUpdateCoords(
    String productId,
    String city,
    String postalCode,
  ) async {
    try {
      final query =
          [postalCode.trim(), city.trim()].where((s) => s.isNotEmpty).join(', ');
      final coords = await GeocodingService().geocode(query);
      if (coords != null) {
        final (lat, lng) = coords;
        await _db
            .from('products')
            .update({'lat': lat, 'lng': lng})
            .eq('id', productId);
        debugPrint('[Primari] geocode OK → $productId lat=$lat lng=$lng');
      }
    } catch (e) {
      // Fallo silencioso — la búsqueda por texto sigue funcionando
      debugPrint('[Primari] geocode failed: $e');
    }
  }

  // ── Imágenes ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getSellerProfile(String sellerId) async {
    return _db
        .from('profiles')
        .select('id, display_name, city, avatar_url, bio, phone, account_type')
        .eq('id', sellerId)
        .maybeSingle();
  }

  Future<void> replaceImages(
      String productId, List<Map<String, dynamic>> images) async {
    await _db.from('product_images').delete().eq('product_id', productId);
    if (images.isNotEmpty) {
      await _db.from('product_images').insert(images);
    }
  }
}
