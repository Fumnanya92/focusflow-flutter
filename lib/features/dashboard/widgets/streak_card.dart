import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  final int streakDays;
  final String title;
  final String subtitle;
  final String label;

  const StreakCard({
    super.key,
    required this.streakDays,
    required this.title,
    required this.subtitle,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1A3224) : const Color(0xFFF4F5F4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? const Color(0xFF93C8A8)
                          : const Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? const Color(0xFF93C8A8)
                          : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Background Pattern
          Expanded(
            flex: 1,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF2D7A79),
                          const Color(0xFF19E66B),
                        ]
                      : [
                          const Color(0xFF93C8A8),
                          const Color(0xFF19E66B),
                        ],
                ),
              ),
              child: const Center(
                child: Text(
                  '🔥',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
