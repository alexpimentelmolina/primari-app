import 'dart:ui' show Rect;
import 'share_with_image_mobile.dart'
    if (dart.library.html) 'share_with_image_web.dart' as platform;

/// Comparte texto + imagen descargada en móvil.
/// En web, cae a share de solo texto.
Future<void> shareWithImage({
  required String text,
  required String subject,
  String? imageUrl,
  Rect? sharePositionOrigin,
}) =>
    platform.shareWithImage(
      text: text,
      subject: subject,
      imageUrl: imageUrl,
      sharePositionOrigin: sharePositionOrigin,
    );
