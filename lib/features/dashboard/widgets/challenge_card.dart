import 'package:flutter/material.dart';

class ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final double progress;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1A3224) : const Color(0xFFF4F5F4),
      ),
      child: Row(
        children: [
          // Text and Progress
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? const Color(0xFF93C8A8)
                        : const Color(0xFF71717A),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? const Color(0xFF71717A)
                        : const Color(0xFFE4E4E7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF19E66B),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF19E66B).withAlpha((0.3 * 255).round()),
                  const Color(0xFF2D7A79).withAlpha((0.3 * 255).round()),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.phone_disabled,
                size: 40,
                color: Color(0xFF19E66B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
