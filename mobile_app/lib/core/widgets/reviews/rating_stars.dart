import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final bool allowHalfRating;

  const RatingStars({
    Key? key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.color = Colors.amber,
    this.allowHalfRating = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return Icon(
          _getStarIcon(index),
          size: size,
          color: color,
        );
      }),
    );
  }

  IconData _getStarIcon(int index) {
    double difference = rating - index;
    
    if (difference >= 1.0) {
      return Icons.star;
    } else if (difference >= 0.5 && allowHalfRating) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }
}

class InteractiveRatingStars extends StatefulWidget {
  final int rating;
  final Function(int) onRatingChanged;
  final int starCount;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const InteractiveRatingStars({
    Key? key,
    required this.rating,
    required this.onRatingChanged,
    this.starCount = 5,
    this.size = 40,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  }) : super(key: key);

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = index + 1;
            });
            widget.onRatingChanged(_currentRating);
          },
          child: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            size: widget.size,
            color: index < _currentRating ? widget.activeColor : widget.inactiveColor,
          ),
        );
      }),
    );
  }
}
