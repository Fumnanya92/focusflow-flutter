import 'package:flutter/material.dart';

class FocusFlowBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const FocusFlowBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF112117).withAlpha((0.8 * 255).round())
            : const Color(0xFFF4F5F4).withAlpha((0.8 * 255).round()),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF346548)
                : const Color(0xFFE4E4E7),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap?.call(0),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.emoji_events_outlined,
                label: 'Challenges',
                isSelected: currentIndex == 1,
                onTap: () => onTap?.call(1),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.workspace_premium_outlined,
                label: 'Rewards',
                isSelected: currentIndex == 2,
                onTap: () => onTap?.call(2),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.bar_chart,
                label: 'Stats',
                isSelected: currentIndex == 3,
                onTap: () => onTap?.call(3),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFF19E66B)
        : (isDark ? const Color(0xFF93C8A8) : const Color(0xFF71717A));

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? _getFilledIcon(icon) : icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFilledIcon(IconData icon) {
    if (icon == Icons.home) return Icons.home;
    if (icon == Icons.emoji_events_outlined) return Icons.emoji_events;
    if (icon == Icons.workspace_premium_outlined) {
      return Icons.workspace_premium;
    }
    if (icon == Icons.bar_chart) return Icons.bar_chart;
    return icon;
  }
}
