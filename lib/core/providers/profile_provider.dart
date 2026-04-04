import 'package:flutter_riverpod/flutter_riverpod.dart';
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
