import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/review_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/reviews/rating_stars.dart';

class CreateReviewScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingDetails;

  const CreateReviewScreen({
    Key? key,
    required this.bookingId,
    this.bookingDetails,
  }) : super(key: key);

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  late final ReviewService _reviewService;

  int _overallRating = 0;
  int _communicationRating = 0;
  int _expertiseRating = 0;
  int _punctualityRating = 0;
  int _helpfulnessRating = 0;

  bool _isLoading = false;
  bool _showCategoryRatings = false;

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService(ApiService());
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final categories = _showCategoryRatings
          ? {
              if (_communicationRating > 0) 'communication': _communicationRating,
              if (_expertiseRating > 0) 'expertise': _expertiseRating,
              if (_punctualityRating > 0) 'punctuality': _punctualityRating,
              if (_helpfulnessRating > 0) 'helpfulness': _helpfulnessRating,
            }
          : null;

      await _reviewService.createReview(
        bookingId: widget.bookingId,
        rating: _overallRating,
        reviewText: _reviewController.text.trim(),
        categories: categories,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorName = widget.bookingDetails?['tutorName'] ?? 'Tutor';
    final subject = widget.bookingDetails?['subject'] ?? 'Session';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate your session with',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        tutorName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        subject,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLG),

              // Overall rating
              Text(
                'Overall Rating *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Center(
                child: InteractiveRatingStars(
                  rating: _overallRating,
                  onRatingChanged: (rating) {
                    setState(() => _overallRating = rating);
                  },
                  size: 50,
                ),
              ),
              if (_overallRating > 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingXS),
                    child: Text(
                      _getRatingText(_overallRating),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: AppTheme.spacingLG),

              // Review text
              Text(
                'Your Review',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              TextFormField(
                controller: _reviewController,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Share your experience with this tutor...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Review text is optional
                  }
                  if (value.trim().length < 10) {
                    return 'Review must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingMD),

              // Category ratings toggle
              CheckboxListTile(
                title: const Text('Add detailed ratings'),
                subtitle: const Text('Rate specific aspects of your session'),
                value: _showCategoryRatings,
                onChanged: (value) {
                  setState(() => _showCategoryRatings = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),

              // Category ratings
              if (_showCategoryRatings) ...[
                const SizedBox(height: AppTheme.spacingMD),
                _buildCategoryRating(
                  'Communication',
                  _communicationRating,
                  (rating) => setState(() => _communicationRating = rating),
                ),
                _buildCategoryRating(
                  'Expertise',
                  _expertiseRating,
                  (rating) => setState(() => _expertiseRating = rating),
                ),
                _buildCategoryRating(
                  'Punctuality',
                  _punctualityRating,
                  (rating) => setState(() => _punctualityRating = rating),
                ),
                _buildCategoryRating(
                  'Helpfulness',
                  _helpfulnessRating,
                  (rating) => setState(() => _helpfulnessRating = rating),
                ),
              ],

              const SizedBox(height: AppTheme.spacingXL),

              // Submit button
              CustomButton(
                text: 'Submit Review',
                onPressed: _isLoading ? null : _submitReview,
                isLoading: _isLoading,
              ),

              const SizedBox(height: AppTheme.spacingSM),

              // Info text
              Text(
                'You can edit your review within 24 hours of posting.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRating(
    String label,
    int rating,
    Function(int) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: InteractiveRatingStars(
              rating: rating,
              onRatingChanged: onChanged,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent!';
      case 4:
        return 'Very Good';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Poor';
      default:
        return '';
    }
  }
}
