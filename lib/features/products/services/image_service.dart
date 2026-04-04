import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  SupabaseClient get _client => Supabase.instance.client;
  static const _bucket = 'product-images';

  Future<String> uploadImage(XFile file, String userId) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${ts}_${file.name}';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
