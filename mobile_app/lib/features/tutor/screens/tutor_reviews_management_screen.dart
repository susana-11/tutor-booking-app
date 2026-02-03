import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/review_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/reviews/rating_distribution.dart';
import '../../../core/widgets/reviews/review_card.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/models/user_model.dart';

class TutorReviewsManagementScreen extends StatefulWidget {
  const TutorReviewsManagementScreen({Key? key}) : super(key: key);

  @override
  State<TutorReviewsManagementScreen> createState() => _TutorReviewsManagementScreenState();
}

class _TutorReviewsManagementScreenState extends State<TutorReviewsManagementScreen> {
  late final ReviewService _reviewService;
  
  ReviewsResponse? _reviewsResponse;
  bool _isLoading = true;
  String? _error;
  String? _tutorProfileId;
  
  int? _filterRating;
  String _sortBy = 'recent';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService(ApiService());
    _loadTutorProfile();
  }

  Future<void> _loadTutorProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if user is a tutor
      if (user.role != UserRole.tutor) {
        throw Exception('Only tutors can access this page');
      }

      // Get tutor profile ID
      final apiService = ApiService();
      final response = await apiService.get('/tutors/profile');
      
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _tutorProfileId = data['_id'];
        _loadReviews();
      } else {
        throw Exception(response.error ?? response.message ?? 'Failed to load tutor profile');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews({bool loadMore = false}) async {
    if (_tutorProfileId == null) return;

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
        tutorId: _tutorProfileId!,
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

  Future<void> _respondToReview(Review review) async {
    final response = await showDialog<String>(
      context: context,
      builder: (context) => _RespondToReviewDialog(),
    );

    if (response != null && response.isNotEmpty) {
      try {
        await _reviewService.addTutorResponse(
          reviewId: review.id,
          response: response,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Response added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReviews();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add response: ${e.toString()}')),
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
                        onPressed: _loadTutorProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reviewsResponse == null || _reviewsResponse!.reviews.isEmpty
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
                            'Complete sessions to receive reviews',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
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
                          child: RefreshIndicator(
                            onRefresh: _loadReviews,
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
                                  isTutor: true,
                                  onRespond: review.tutorResponse == null
                                      ? () => _respondToReview(review)
                                      : null,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _RespondToReviewDialog extends StatefulWidget {
  @override
  State<_RespondToReviewDialog> createState() => _RespondToReviewDialogState();
}

class _RespondToReviewDialogState extends State<_RespondToReviewDialog> {
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Respond to Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your response will be visible to all users.'),
          const SizedBox(height: AppTheme.spacingMD),
          TextField(
            controller: _responseController,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Thank you for your feedback...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _responseController.text.trim());
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
