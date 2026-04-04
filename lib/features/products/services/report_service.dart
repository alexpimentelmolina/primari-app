import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  static final _db = Supabase.instance.client;

  /// Crea o actualiza un reporte (upsert por reporter_id + product_id).
  Future<void> submitReport({
    required String productId,
    required String sellerId,
    required String reason,
    String? details,
  }) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw Exception('Debes iniciar sesión para reportar.');

    final trimmedDetails = details?.trim();
    final payload = {
      'product_id': productId,
      'reporter_id': userId,
      'seller_id': sellerId,
      'reason': reason,
      'details': (trimmedDetails?.isEmpty ?? true) ? null : trimmedDetails,
      'status': 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    debugPrint('Report payload: $payload');
    await _db.from('product_reports').upsert(
      payload,
      onConflict: 'reporter_id,product_id',
    );
  }
}
