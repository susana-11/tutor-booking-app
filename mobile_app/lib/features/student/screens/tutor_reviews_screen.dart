import 'package:flutter/material.dart';
import '../../../core/models/review_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/reviews/rating_distribution.dart';
import '../../../core/widgets/reviews/review_card.dart';

class TutorReviewsScreen extends StatefulWidget {
  final String tutorId;
  final String tutorName;

  const TutorReviewsScreen({
    Key? key,
    required this.tutorId,
    required this.tutorName,
  }) : super(key: key);

  @override
  State<TutorReviewsScreen> createState() => _TutorReviewsScreenState();
}

class _TutorReviewsScreenState extends State<TutorReviewsScreen> {
  late final ReviewService _reviewService;
  
  ReviewsResponse? _reviewsResponse;
  bool _isLoading = true;
  String? _error;
  
  int? _filterRating;
  String _sortBy = 'recent';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService(ApiService());
    _loadReviews();
  }

  Future<void> _loadReviews({bool loadMore = false}) async {
    if (loadMore) {
      _currentPage++;
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
      });
    }

    try {
      final response = await _reviewService.getTutorReviews(
        tutorId: widget.tutorId,
        page: _currentPage,
        rating: _filterRating,
        sortBy: _sortBy,
      );

      setState(() {
        if (loadMore && _reviewsResponse != null) {
          _reviewsResponse = ReviewsResponse(
            reviews: [..._reviewsResponse!.reviews, ...response.reviews],
            statistics: response.statistics,
            pagination: response.pagination,
          );
        } else {
          _reviewsResponse = response;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markHelpful(String reviewId, bool helpful) async {
    try {
      await _reviewService.markHelpful(
        reviewId: reviewId,
        helpful: helpful,
      );
      _loadReviews(); // Reload to show updated counts
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark review: ${e.toString()}')),
      );
    }
  }

  Future<void> _flagReview(String reviewId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _FlagReviewDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _reviewService.flagReview(reviewId: reviewId, reason: reason);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report review: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tutorName}\'s Reviews'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadReviews();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'recent', child: Text('Most Recent')),
              const PopupMenuItem(value: 'helpful', child: Text('Most Helpful')),
              const PopupMenuItem(value: 'rating_high', child: Text('Highest Rating')),
              const PopupMenuItem(value: 'rating_low', child: Text('Lowest Rating')),
            ],
          ),
        ],
      ),
      body: _isLoading && _reviewsResponse == null
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
              : _reviewsResponse == null || _reviewsResponse!.reviews.isEmpty
                  ? const Center(child: Text('No reviews yet'))
                  : Column(
                      children: [
                        // Statistics section
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          color: Colors.grey[100],
                          child: RatingDistribution(
                            stats: _reviewsResponse!.statistics,
                          ),
                        ),

                        // Filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMD,
                            vertical: AppTheme.spacingSM,
                          ),
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: _filterRating == null,
                                onSelected: (selected) {
                                  setState(() => _filterRating = null);
                                  _loadReviews();
                                },
                              ),
                              const SizedBox(width: AppTheme.spacingSM),
                              for (int i = 5; i >= 1; i--)
                                Padding(
                                  padding: const EdgeInsets.only(right: AppTheme.spacingSM),
                                  child: FilterChip(
                                    label: Text('$i★'),
                                    selected: _filterRating == i,
                                    onSelected: (selected) {
                                      setState(() => _filterRating = selected ? i : null);
                                      _loadReviews();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // Reviews list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.spacingMD),
                            itemCount: _reviewsResponse!.reviews.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _reviewsResponse!.reviews.length) {
                                // Load more button
                                if (_reviewsResponse!.pagination.hasNextPage) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                                    child: Center(
                                      child: ElevatedButton(
                                        onPressed: () => _loadReviews(loadMore: true),
                                        child: const Text('Load More'),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }

                              final review = _reviewsResponse!.reviews[index];
                              return ReviewCard(
                                review: review,
                                onHelpful: () => _markHelpful(review.id, true),
                                onNotHelpful: () => _markHelpful(review.id, false),
                                onFlag: () => _flagReview(review.id),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _FlagReviewDialog extends StatefulWidget {
  @override
  State<_FlagReviewDialog> createState() => _FlagReviewDialogState();
}

class _FlagReviewDialogState extends State<_FlagReviewDialog> {
  String? _selectedReason;
  final _otherReasonController = TextEditingController();

  final List<String> _reasons = [
    'Inappropriate content',
    'Spam or fake review',
    'Offensive language',
    'Misleading information',
    'Other',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why are you reporting this review?'),
          const SizedBox(height: AppTheme.spacingMD),
          ..._reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
                contentPadding: EdgeInsets.zero,
              )),
          if (_selectedReason == 'Other') ...[
            const SizedBox(height: AppTheme.spacingSM),
            TextField(
              controller: _otherReasonController,
              decoration: const InputDecoration(
                hintText: 'Please specify...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _selectedReason == 'Other'
                ? _otherReasonController.text.trim()
                : _selectedReason;
            Navigator.pop(context, reason);
          },
          child: const Text('Report'),
        ),
      ],
    );
  }
}
