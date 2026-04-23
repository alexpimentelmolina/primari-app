import 'dart:ui' show Rect;
import 'package:share_plus/share_plus.dart';

Future<void> shareWithImage({
  required String text,
  required String subject,
  String? imageUrl,
  Rect? sharePositionOrigin,
}) async {
  Share.share(text, subject: subject);
}
