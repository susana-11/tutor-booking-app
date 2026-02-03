import 'package:flutter/material.dart';
import '../../models/review_models.dart';
import '../../theme/app_theme.dart';

class RatingDistribution extends StatelessWidget {
  final RatingStats stats;

  const RatingDistribution({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall rating
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'out of 5',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          '${stats.totalReviews} ${stats.totalReviews == 1 ? 'review' : 'reviews'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        // Distribution bars
        for (int i = 5; i >= 1; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
            child: _buildDistributionBar(
              context,
              i,
              stats.distribution[i] ?? 0,
              stats.getPercentage(i),
            ),
          ),
      ],
    );
  }

  Widget _buildDistributionBar(
    BuildContext context,
    int stars,
    int count,
    int percentage,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '$stars★',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingXS),
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
