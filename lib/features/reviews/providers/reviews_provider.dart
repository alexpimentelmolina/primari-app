import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';

final reviewServiceProvider =
    Provider<ReviewService>((ref) => ReviewService());

/// Lista de reseñas de un vendedor
final sellerReviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, String>(
        (ref, sellerId) async {
  return ref.read(reviewServiceProvider).getSellerReviews(sellerId);
});

/// (mediaRating, totalReseñas) de un vendedor
final sellerRatingSummaryProvider =
    FutureProvider.autoDispose.family<(double, int), String>(
        (ref, sellerId) async {
  return ref.read(reviewServiceProvider).getRatingSummary(sellerId);
});
