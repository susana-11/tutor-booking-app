import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/review_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/reviews/review_card.dart';
import '../../../features/auth/providers/auth_provider.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({Key? key}) : super(key: key);

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late final ReviewService _reviewService;
  
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService(ApiService());
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final reviews = await _reviewService.getStudentReviews(studentId: userId);

      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _editReview(Review review) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditReviewDialog(review: review),
    );

    if (result != null) {
      try {
        await _reviewService.updateReview(
          reviewId: review.id,
          rating: result['rating'],
          reviewText: result['review'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReviews();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update review: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reviewService.deleteReview(review.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReviews();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete review: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: AppTheme.spacingMD),
                      Text(_error!),
                      const SizedBox(height: AppTheme.spacingMD),
                      ElevatedButton(
                        onPressed: _loadReviews,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: AppTheme.spacingMD),
                          Text(
                            'No reviews yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTheme.spacingSM),
                          Text(
                            'Complete a session to leave a review',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReviews,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return ReviewCard(
                            review: review,
                            isOwnReview: true,
                            onEdit: review.canEdit() ? () => _editReview(review) : null,
                            onDelete: () => _deleteReview(review),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _EditReviewDialog extends StatefulWidget {
  final Review review;

  const _EditReviewDialog({required this.review});

  @override
  State<_EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<_EditReviewDialog> {
  late int _rating;
  late TextEditingController _reviewController;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _reviewController = TextEditingController(text: widget.review.review ?? '');
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating'),
            const SizedBox(height: AppTheme.spacingSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _rating = index + 1);
                  },
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            const Text('Review'),
            const SizedBox(height: AppTheme.spacingSM),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'rating': _rating,
              'review': _reviewController.text.trim(),
            });
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
