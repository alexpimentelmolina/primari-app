class Review {
  final String id;
  final String reviewerId;
  final String sellerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? reviewerName;
  final String? reviewerAvatarUrl;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.sellerId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatarUrl,
  });

  factory Review.fromMap(Map<String, dynamic> m) {
    final reviewer = m['reviewer'] as Map<String, dynamic>?;
    return Review(
      id: m['id'] as String,
      reviewerId: m['reviewer_id'] as String,
      sellerId: m['seller_id'] as String,
      rating: (m['rating'] as num).toInt(),
      comment: m['comment'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      reviewerName: reviewer?['display_name'] as String?,
      reviewerAvatarUrl: reviewer?['avatar_url'] as String?,
    );
  }
}
