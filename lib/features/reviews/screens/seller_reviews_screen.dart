import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/review.dart';
import '../providers/reviews_provider.dart';

class SellerReviewsScreen extends ConsumerWidget {
  final String sellerId;
  const SellerReviewsScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id;
    final canReview = currentUserId != null && currentUserId != sellerId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: AppTheme.primary,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Valoraciones',
          style: GoogleFonts.notoSerif(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        actions: [
          if (canReview)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () =>
                    _openReviewSheet(context, ref, currentUserId),
                icon: const Icon(
                  Icons.star_outline_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
                label: Text(
                  'Valorar',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _ReviewsBody(sellerId: sellerId),
    );
  }

  void _openReviewSheet(
      BuildContext context, WidgetRef ref, String currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReviewFormSheet(
        sellerId: sellerId,
        reviewerId: currentUserId,
        onSubmitted: () {
          ref.invalidate(sellerReviewsProvider(sellerId));
          ref.invalidate(sellerRatingSummaryProvider(sellerId));
        },
      ),
    );
  }
}

// ── Cuerpo con resumen + lista ────────────────────────────────────────────────

class _ReviewsBody extends ConsumerWidget {
  final String sellerId;
  const _ReviewsBody({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(sellerRatingSummaryProvider(sellerId));
    final reviewsAsync = ref.watch(sellerReviewsProvider(sellerId));

    final reviews = reviewsAsync.valueOrNull;

    return CustomScrollView(
      slivers: [
        // Resumen de rating
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: summaryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
              data: (s) {
                final (avg, count) = s;
                if (count == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Sin valoraciones todavía.',
                      style: GoogleFonts.manrope(
                          fontSize: 14, color: AppTheme.onSurfaceVariant),
                    ),
                  );
                }
                return _RatingSummaryRow(avg: avg, count: count);
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Lista de reviews con builder (lazy)
        if (reviewsAsync.isLoading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 2),
              ),
            ),
          )
        else if (reviews != null && reviews.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverList.builder(
              itemCount: reviews.length,
              itemBuilder: (ctx, i) => _ReviewCard(review: reviews[i]),
            ),
          ),
      ],
    );
  }
}

// ── Resumen numérico de rating ────────────────────────────────────────────────

class _RatingSummaryRow extends StatelessWidget {
  final double avg;
  final int count;
  const _RatingSummaryRow({required this.avg, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          avg.toStringAsFixed(1),
          style: GoogleFonts.notoSerif(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StarRow(rating: avg.round(), size: 20),
            Text(
              '$count ${count == 1 ? 'reseña' : 'reseñas'}',
              style: GoogleFonts.manrope(
                  fontSize: 13, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tarjeta de reseña individual ──────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final name = review.reviewerName ?? 'Usuario';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: review.reviewerAvatarUrl != null
                    ? NetworkImage(review.reviewerAvatarUrl!)
                    : null,
                backgroundColor: AppTheme.surfaceContainerHigh,
                child: review.reviewerAvatarUrl == null
                    ? Text(initial,
                        style: GoogleFonts.notoSerif(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.onSurface)),
                    _StarRow(rating: review.rating, size: 14),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: GoogleFonts.manrope(
                    fontSize: 11, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

// ── Fila de estrellas ─────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppTheme.secondary,
        ),
      ),
    );
  }
}

// ── Bottom sheet para enviar reseña ───────────────────────────────────────────

class _ReviewFormSheet extends ConsumerStatefulWidget {
  final String sellerId;
  final String reviewerId;
  final VoidCallback onSubmitted;

  const _ReviewFormSheet({
    required this.sellerId,
    required this.reviewerId,
    required this.onSubmitted,
  });

  @override
  ConsumerState<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<_ReviewFormSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Selecciona al menos una estrella.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(reviewServiceProvider).submitReview(
            reviewerId: widget.reviewerId,
            sellerId: widget.sellerId,
            rating: _rating,
            comment: _commentCtrl.text.isEmpty ? null : _commentCtrl.text,
          );
      if (mounted) {
        widget.onSubmitted();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error al enviar. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tu valoración',
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: AppTheme.secondary,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Añade un comentario (opcional)...',
              hintStyle: GoogleFonts.manrope(
                  fontSize: 14, color: AppTheme.onSurfaceVariant),
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppTheme.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primary.withAlpha(100),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Enviar valoración',
                      style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
