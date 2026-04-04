import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewService {
  SupabaseClient get _db => Supabase.instance.client;

  /// Devuelve todas las reseñas de un vendedor, con el nombre del reviewer.
  Future<List<Review>> getSellerReviews(String sellerId) async {
    final data = await _db
        .from('reviews')
        .select('*, reviewer:profiles!reviewer_id(display_name, avatar_url)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Review.fromMap(e)).toList();
  }

  /// Devuelve (media, total) de valoraciones de un vendedor.
  Future<(double, int)> getRatingSummary(String sellerId) async {
    final data = await _db
        .from('reviews')
        .select('rating')
        .eq('seller_id', sellerId);
    final list = data as List;
    if (list.isEmpty) return (0.0, 0);
    final ratings = list.map((e) => (e['rating'] as num).toInt()).toList();
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    return (avg, ratings.length);
  }

  /// Devuelve la reseña existente del reviewer para ese seller, o null.
  Future<Review?> getMyReviewForSeller(
      String reviewerId, String sellerId) async {
    final data = await _db
        .from('reviews')
        .select()
        .eq('reviewer_id', reviewerId)
        .eq('seller_id', sellerId)
        .maybeSingle();
    if (data == null) return null;
    return Review.fromMap(data);
  }

  /// Inserta o actualiza la reseña (un reviewer → un seller = una reseña).
  Future<void> submitReview({
    required String reviewerId,
    required String sellerId,
    required int rating,
    String? comment,
  }) async {
    final existing = await _db
        .from('reviews')
        .select('id')
        .eq('reviewer_id', reviewerId)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (existing != null) {
      await _db.from('reviews').update({
        'rating': rating,
        'comment': comment,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existing['id'] as String);
    } else {
      await _db.from('reviews').insert({
        'reviewer_id': reviewerId,
        'seller_id': sellerId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      });
    }
  }
}
