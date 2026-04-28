import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/profile.dart';
import '../../features/profile/services/profile_service.dart';
import 'auth_provider.dart';

final profileServiceProvider =
    Provider<ProfileService>((ref) => ProfileService());

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    // Await the auth stream so we never return null prematurely while
    // auth is still loading — prevents the /mi-perfil → /completar-perfil
    // → /home redirect race condition.
    final authState = await ref.watch(authStateProvider.future);
    final user = authState.session?.user;
    if (user == null) return null;

    // Subscribe to realtime changes on this user's profile row so that
    // an admin suspension (is_active = false) takes effect immediately
    // without waiting for the JWT to expire or the user to navigate.
    final channel = Supabase.instance.client
        .channel('profile:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: user.id,
          ),
          callback: (_) => ref.invalidateSelf(),
        )
        .subscribe();

    // Cancel the subscription when this provider is disposed (e.g. on sign-out)
    ref.onDispose(() => channel.unsubscribe());

    return ref.read(profileServiceProvider).getProfile(user.id);
  }

  Future<void> save(Profile profile) async {
    state = const AsyncLoading();
    try {
      await ref.read(profileServiceProvider).upsertProfile(profile);
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Actualiza el avatar en Supabase y refleja el cambio en el estado local.
  Future<void> updateAvatar(String newAvatarUrl) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref
        .read(profileServiceProvider)
        .updateAvatarUrl(current.id, newAvatarUrl);
    state = AsyncData(Profile(
      id: current.id,
      accountType: current.accountType,
      displayName: current.displayName,
      phone: current.phone,
      city: current.city,
      postalCode: current.postalCode,
      address: current.address,
      addressVisibility: current.addressVisibility,
      avatarUrl: newAvatarUrl,
      bio: current.bio,
      isActive: current.isActive,
    ));
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);
