import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products/models/product.dart';

class FavoriteService {
  SupabaseClient get _db => Supabase.instance.client;

  /// IDs de productos favoritos del usuario
  Future<Set<String>> getFavoriteIds(String userId) async {
    final data = await _db
        .from('favorites')
        .select('product_id')
        .eq('user_id', userId);
    return (data as List).map((r) => r['product_id'] as String).toSet();
  }

  /// Productos completos favoritos del usuario (sólo activos)
  Future<List<Product>> getFavoriteProducts(String userId) async {
    final ids = await getFavoriteIds(userId);
    if (ids.isEmpty) return [];
    final data = await _db
        .from('products')
        .select()
        .inFilter('id', ids.toList())
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (data as List).map((m) => Product.fromMap(m)).toList();
  }

  Future<void> add(String userId, String productId) async {
    await _db.from('favorites').upsert({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<void> remove(String userId, String productId) async {
    await _db
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }
}
