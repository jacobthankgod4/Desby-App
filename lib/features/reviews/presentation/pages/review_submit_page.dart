import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class ReviewSubmitPage extends ConsumerStatefulWidget {
  final String orderId;
  final String revieweeId;
  final String reviewType; // 'client_to_tailor', 'tailor_to_seller'
  const ReviewSubmitPage({
    super.key,
    required this.orderId,
    required this.revieweeId,
    required this.reviewType,
  });

  @override
  ConsumerState<ReviewSubmitPage> createState() => _ReviewSubmitPageState();
}

class _ReviewSubmitPageState extends ConsumerState<ReviewSubmitPage> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      const uuid = Uuid();
      await Supabase.instance.client.from('reviews').insert({
        'id': uuid.v4(),
        'order_id': widget.orderId,
        'reviewer_id': user.id,
        'reviewee_id': widget.revieweeId,
        'rating': _rating,
        'comment': _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
        'review_type': widget.reviewType,
      });

      if (mounted) {
        setState(() => _hasSubmitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('REVIEW SUBMITTED'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_hasSubmitted) {
      return Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'THANK YOU',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your review helps build trust',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (ref.canPopShell) ref.popShell();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                ),
                child: const Text('BACK TO DASHBOARD'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'LEAVE A REVIEW',
        iconTheme: const IconThemeData(color: AppColors.amber),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Rating stars
            Center(
              child: Column(
                children: [
                  Text(
                    _rating == 0
                        ? 'Tap to rate'
                        : _rating == 5
                        ? 'Excellent!'
                        : _rating >= 4
                        ? 'Great'
                        : _rating >= 3
                        ? 'Good'
                        : 'Needs improvement',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => GestureDetector(
                        onTap: () => setState(() => _rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            index < _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: index < _rating
                                ? AppColors.amber
                                : colors.iconMuted,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Comment
            const Text(
              'YOUR REVIEW',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 5,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: TextStyle(color: colors.textHint),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.amber),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Submit
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(
                        color: context.colors.textOnAmber,
                      )
                    : const Text(
                        'SUBMIT REVIEW',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
