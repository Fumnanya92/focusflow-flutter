import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A back button that checks for tutorial return parameters and navigates appropriately
class TutorialBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? defaultRoute;

  const TutorialBackButton({
    super.key,
    this.onPressed,
    this.defaultRoute,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: onPressed ?? () => _handleBack(context),
    );
  }

  void _handleBack(BuildContext context) {
    // Get current route query parameters
    final uri = GoRouterState.of(context).uri;
    final returnTo = uri.queryParameters['returnTo'];
    final step = uri.queryParameters['step'];
    final explored = uri.queryParameters['explored'];
    
    debugPrint('🔙 [TUTORIAL_BACK] Current URL: ${uri.toString()}');
    debugPrint('🔙 [TUTORIAL_BACK] returnTo: $returnTo, step: $step, explored: $explored');
    
    if (returnTo != null && step != null) {
      // Return to tutorial with step information
      debugPrint('🔙 [TUTORIAL_BACK] Returning to tutorial: $returnTo?step=$step');
      context.go('$returnTo?step=$step');
    } else if (returnTo != null && explored != null) {
      // Return to dashboard showcase with exploration info
      debugPrint('🔙 [TUTORIAL_BACK] Returning with exploration: $returnTo?explored=$explored');
      context.go('$returnTo?explored=$explored');
    } else if (returnTo != null) {
      // Return to specified route
      debugPrint('🔙 [TUTORIAL_BACK] Returning to: $returnTo');
      context.go(returnTo);
    } else if (defaultRoute != null) {
      // Go to specified default route
      debugPrint('🔙 [TUTORIAL_BACK] Using default route: $defaultRoute');
      context.go(defaultRoute!);
    } else {
      // Standard back navigation
      debugPrint('🔙 [TUTORIAL_BACK] Standard back navigation');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    }
  }
}