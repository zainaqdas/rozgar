import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class RatingModal extends StatefulWidget {
  final AppState appState;
  final String jobId;
  final String revieweeProfileId;
  final VoidCallback onClose;

  const RatingModal({
    super.key,
    required this.appState,
    required this.jobId,
    required this.revieweeProfileId,
    required this.onClose,
  });

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
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
    final revieweeData =
        widget.appState.getPublicProfile(widget.revieweeProfileId);

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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate Service & Job Experience',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your review builds trust in the Lahore Rozgar community.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviewee info
                  if (revieweeData?.profile != null) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),
                          child: Image.network(
                            revieweeData!.profile
                                .profilePhotoUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const CircleAvatar(
                              radius: 20,
                              child: Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              revieweeData
                                  .profile.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate800,
                              ),
                            ),
                            Text(
                              revieweeData.profile.profileType
                                  .name,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Star Rating
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starNum = i + 1;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _rating = starNum),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 4),
                          child: Icon(
                            starNum <= _rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 36,
                            color: starNum <= _rating
                                ? AppColors.amber400
                                : AppColors.slate300,
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
                        widget.appState.addReview(
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
