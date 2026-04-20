import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareWithImage({
  required String text,
  required String subject,
  String? imageUrl,
}) async {
  if (imageUrl != null) {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final ext = imageUrl.contains('.png') ? 'png' : 'jpg';
        final file = File('${tempDir.path}/primari_share.$ext');
        await file.writeAsBytes(response.bodyBytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: text,
          subject: subject,
        );
        return;
      }
    } catch (_) {
      // Fallback a share de solo texto
    }
  }

  Share.share(text, subject: subject);
}
