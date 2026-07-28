import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class RatingModal extends ConsumerStatefulWidget {
  final String jobId;
  final String revieweeProfileId;
  final VoidCallback onClose;

  const RatingModal({
    super.key,
    required this.jobId,
    required this.revieweeProfileId,
    required this.onClose,
  });

  @override
  ConsumerState<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends ConsumerState<RatingModal> {
  int _rating = 5;
  final _commentController = TextEditingController(
    text: 'Very punctual, reliable, and clean work!',
  );

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final workers = ref.read(workerProvider);
    final revieweeData = workers.getPublicProfile(
      widget.revieweeProfileId,
      profile.workerProfile,
      profile.workerDetails,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Material(
        color: AppColors.slate900.withValues(alpha: 0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.star_rate_rounded,
                          size: 24, color: AppColors.amber500),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rate Your Experience',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close,
                            size: 20, color: AppColors.slate400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reviewee info
                  if (revieweeData != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.teal50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.teal200),
                          ),
                          child: Center(
                            child: Text(
                              revieweeData.profile.displayName.isNotEmpty
                                  ? revieweeData.profile.displayName[0]
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                revieweeData.profile.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate800,
                                ),
                              ),
                              const Text(
                                'How was the work quality?',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _rating = starValue),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starValue <= _rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 36,
                            color: AppColors.amber500,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Comment
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Write a brief review...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(profileProvider.notifier).addReview(
                          widget.jobId,
                          widget.revieweeProfileId,
                          _rating,
                          _commentController.text,
                        );
                        widget.onClose();
                      },
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 18),
                          SizedBox(width: 8),
                          Text('Submit Review'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ],
);
  }
}
