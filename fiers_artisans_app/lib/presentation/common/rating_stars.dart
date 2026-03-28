import 'package:flutter/material.dart';
import '../../config/theme.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          color = AppTheme.gold;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
          color = AppTheme.gold;
        } else {
          icon = Icons.star_outline_rounded;
          color = Colors.grey.shade400;
        }

        return GestureDetector(
          onTap: interactive ? () => onRatingChanged?.call(starValue) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(icon, size: size, color: color),
          ),
        );
      }),
    );
  }
}
