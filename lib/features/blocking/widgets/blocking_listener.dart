import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_blocking_provider.dart';

/// Widget that listens for app blocking events and shows staged overlays
class BlockingListener extends StatefulWidget {
  final Widget child;

  const BlockingListener({
    super.key,
    required this.child,
  });

  @override
  State<BlockingListener> createState() => _BlockingListenerState();
}

class _BlockingListenerState extends State<BlockingListener> {
  String? _lastBlockedApp;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppBlockingProvider>(
      builder: (context, blockingProvider, child) {
        // Check if there's a newly blocked app
        final currentlyBlocked = blockingProvider.currentlyBlockedApp;
        
        if (currentlyBlocked != null && currentlyBlocked != _lastBlockedApp) {
          _lastBlockedApp = currentlyBlocked;
          
          // Schedule showing the overlay after the current build cycle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showStagedBlocking(currentlyBlocked);
          });
        }
        
        return widget.child;
      },
    );
  }

  Future<void> _showStagedBlocking(String appName) async {
    if (!mounted) return;
    
    try {
      final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
      
      // Android native service handles the blocking overlay completely
      // Just clear the blocked app state since the native overlay is shown
      blockingProvider.clearCurrentlyBlockedApp();
      _lastBlockedApp = null;
      debugPrint('✅ Blocking handled by native Android service for: $appName');
    } catch (e) {
      debugPrint('❌ Error clearing blocked app state: $e');
    }
  }
}
