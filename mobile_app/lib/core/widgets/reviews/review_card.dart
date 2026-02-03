import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/review_models.dart';
import '../../theme/app_theme.dart';
import 'rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showTutorResponse;
  final VoidCallback? onHelpful;
  final VoidCallback? onNotHelpful;
  final VoidCallback? onFlag;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRespond;
  final bool isOwnReview;
  final bool isTutor;

  const ReviewCard({
    Key? key,
    required this.review,
    this.showTutorResponse = true,
    this.onHelpful,
    this.onNotHelpful,
    this.onFlag,
    this.onEdit,
    this.onDelete,
    this.onRespond,
    this.isOwnReview = false,
    this.isTutor = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with student info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.studentInfo?.profilePicture != null
                      ? NetworkImage(review.studentInfo!.profilePicture!)
                      : null,
                  child: review.studentInfo?.profilePicture == null
                      ? Text(review.studentInfo?.firstName[0] ?? 'U')
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.studentInfo?.fullName ?? 'Anonymous',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(review.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                RatingStars(rating: review.rating.toDouble(), size: 18),
              ],
            ),

            const SizedBox(height: AppTheme.spacingSM),

            // Review text
            if (review.review != null && review.review!.isNotEmpty) ...[
              Text(
                review.review!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingSM),
            ],

            // Category ratings
            if (review.categories != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              Wrap(
                spacing: AppTheme.spacingSM,
                runSpacing: AppTheme.spacingXS,
                children: [
                  if (review.categories!.communication != null)
                    _buildCategoryChip('Communication', review.categories!.communication!),
                  if (review.categories!.expertise != null)
                    _buildCategoryChip('Expertise', review.categories!.expertise!),
                  if (review.categories!.punctuality != null)
                    _buildCategoryChip('Punctuality', review.categories!.punctuality!),
                  if (review.categories!.helpfulness != null)
                    _buildCategoryChip('Helpfulness', review.categories!.helpfulness!),
                ],
              ),
            ],

            // Edited indicator
            if (review.isEdited) ...[
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                'Edited',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Tutor response
            if (showTutorResponse && review.tutorResponse != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply, size: 16, color: Colors.blue),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          'Tutor Response',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      review.tutorResponse!.text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            const SizedBox(height: AppTheme.spacingSM),
            Row(
              children: [
                // Helpfulness buttons
                if (!isOwnReview && !isTutor) ...[
                  TextButton.icon(
                    onPressed: onHelpful,
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    label: Text('Helpful (${review.helpful.length})'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onNotHelpful,
                    icon: const Icon(Icons.thumb_down_outlined, size: 16),
                    label: Text('(${review.notHelpful.length})'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],

                const Spacer(),

                // Owner actions
                if (isOwnReview) ...[
                  if (review.canEdit())
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],

                // Tutor actions
                if (isTutor && review.tutorResponse == null)
                  TextButton.icon(
                    onPressed: onRespond,
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Respond'),
                  ),

                // Flag action
                if (!isOwnReview && !isTutor)
                  IconButton(
                    onPressed: onFlag,
                    icon: const Icon(Icons.flag_outlined, size: 20),
                    tooltip: 'Report',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int rating) {
    return Chip(
      label: Text(
        '$label: $rating★',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey[200],
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
