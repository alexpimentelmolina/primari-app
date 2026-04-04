import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../products/models/product.dart';
import '../services/favorite_service.dart';

final favoriteServiceProvider =
    Provider<FavoriteService>((ref) => FavoriteService());

// ── Notifier que mantiene el Set de IDs favoritos ─────────────────────────────
// Permite toggle optimista: la UI se actualiza inmediatamente sin esperar red.
class FavoriteIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    // Espera a que auth esté resuelto (evita falsos nulls mientras carga)
    final authState = await ref.watch(authStateProvider.future);
    final user = authState.session?.user;
    if (user == null) return {};
    return ref.read(favoriteServiceProvider).getFavoriteIds(user.id);
  }

  Future<void> toggle(String productId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final current = state.valueOrNull ?? {};
    final isFav = current.contains(productId);

    // Actualización optimista inmediata
    state = AsyncData(
      isFav
          ? (Set<String>.from(current)..remove(productId))
          : {...current, productId},
    );

    try {
      final svc = ref.read(favoriteServiceProvider);
      if (isFav) {
        await svc.remove(user.id, productId);
      } else {
        await svc.add(user.id, productId);
      }
    } catch (_) {
      // Revertir si la llamada de red falla
      state = AsyncData(current);
    }
  }
}

final favoriteIdsProvider =
    AsyncNotifierProvider<FavoriteIdsNotifier, Set<String>>(
        FavoriteIdsNotifier.new);

// ── Productos completos favoritos (para la pantalla de favoritos) ─────────────
// autoDispose: se recarga automáticamente cada vez que el usuario entra a la pantalla.
final favoritedProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  final user = authState.session?.user;
  if (user == null) return [];
  return ref.read(favoriteServiceProvider).getFavoriteProducts(user.id);
});
