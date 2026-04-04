import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Profile?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  Future<void> upsertProfile(Profile profile) async {
    await _client.from('profiles').upsert(profile.toMap());
  }

  /// Sube la foto de perfil al bucket `avatars` y devuelve la URL pública.
  Future<String> uploadAvatar(XFile file, String userId) async {
    final bytes = await file.readAsBytes();
    final ext =
        file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${ts}_avatar.$ext';

    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Guarda la nueva URL de avatar en la tabla `profiles`.
  Future<void> updateAvatarUrl(String userId, String url) async {
    await _client
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', userId);
  }
}
