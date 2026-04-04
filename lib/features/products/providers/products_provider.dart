import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/product.dart';
import '../services/image_service.dart';
import '../services/product_service.dart';

final productServiceProvider =
    Provider<ProductService>((ref) => ProductService());

final imageServiceProvider =
    Provider<ImageService>((ref) => ImageService());

// Productos activos para el home
final activeProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.read(productServiceProvider).getActiveProducts();
});

// Mis productos (usuario autenticado) — todos los no eliminados
final myProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return [];
  return ref.read(productServiceProvider).getMyProducts(user.id);
});

// Solo mis productos activos — para el bento y la pantalla "Listados activos"
final myActiveProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return [];
  return ref.read(productServiceProvider).getMyActiveProducts(user.id);
});

// Detalle de un producto
final productDetailProvider =
    FutureProvider.autoDispose.family<ProductDetail?, String>((ref, id) async {
  return ref.read(productServiceProvider).getProductDetail(id);
});

// Productos activos de un vendedor
final sellerProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>(
        (ref, sellerId) async {
  return ref
      .read(productServiceProvider)
      .getSellerActiveProducts(sellerId);
});

// Parámetros de búsqueda: query + categoría + ciudad + coordenadas + radio
class SearchFilter {
  final String query;
  final String? category;
  final String city;
  // Coordenadas GPS del usuario (obtenidas del dispositivo).
  // Cuando están presentes, la RPC ordena resultados por distancia.
  final double? userLat;
  final double? userLng;
  // Radio máximo en km (null = sin límite de distancia).
  final int? maxDistanceKm;

  const SearchFilter({
    this.query = '',
    this.category,
    this.city = '',
    this.userLat,
    this.userLng,
    this.maxDistanceKm,
  });

  bool get hasFilter =>
      query.trim().isNotEmpty ||
      category != null ||
      city.trim().isNotEmpty ||
      userLat != null;

  @override
  bool operator ==(Object other) =>
      other is SearchFilter &&
      other.query == query &&
      other.category == category &&
      other.city == city &&
      other.userLat == userLat &&
      other.userLng == userLng &&
      other.maxDistanceKm == maxDistanceKm;

  @override
  int get hashCode =>
      Object.hash(query, category, city, userLat, userLng, maxDistanceKm);
}

// Búsqueda de productos activos con filtros
final searchProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, SearchFilter>(
        (ref, filter) async {
  return ref.read(productServiceProvider).searchProducts(
        query: filter.query,
        category: filter.category,
        city: filter.city,
        userLat: filter.userLat,
        userLng: filter.userLng,
        maxDistanceKm: filter.maxDistanceKm,
      );
});

/// Caché de sesión para coordenadas GPS del usuario.
/// Se rellena la primera vez que Search obtiene la ubicación.
/// En búsquedas sucesivas se reutiliza al instante, sin volver a pedir GPS.
final cachedGpsProvider =
    StateProvider<({double lat, double lng})?>((_) => null);

// Perfil público de un vendedor
final sellerProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
        (ref, sellerId) async {
  return ref.read(productServiceProvider).getSellerProfile(sellerId);
});
