import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../config/theme.dart';
import '../../providers/artisan_provider.dart';
import '../common/rating_stars.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String artisanId;
  const ReviewScreen({super.key, required this.artisanId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _isLoading = true);

    final success =
        await ref.read(artisanDetailProvider.notifier).submitReview(
              artisanId: widget.artisanId,
              rating: _rating,
              comment: _commentCtrl.text.trim().isNotEmpty
                  ? _commentCtrl.text.trim()
                  : null,
            );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avis envoyé !'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('review.already_done'.tr()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('review.leave'.tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('review.your_rating'.tr(),
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              Center(
                child: RatingStars(
                  rating: _rating.toDouble(),
                  size: 40,
                  interactive: true,
                  onRatingChanged: (r) => setState(() => _rating = r),
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _commentCtrl,
                label: 'review.your_comment'.tr(),
                maxLines: 5,
              ),
              const Spacer(),
              AppButton(
                text: 'review.submit'.tr(),
                isLoading: _isLoading,
                onPressed: _rating > 0 ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
