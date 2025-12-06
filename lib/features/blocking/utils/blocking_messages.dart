import 'dart:math';

/// Different stages of app blocking attempts
enum BlockingStage {
  firstTime,        // First attempt - show grace period option
  graceExpired,     // Grace expired - more strict messaging
  immediate,        // Quick retry - simple lock message
  repeated,         // Multiple attempts - firmer messaging
}

/// Simple utility class for blocking messages - no animations or complex logic
class BlockingMessages {
  static const Map<BlockingStage, List<String>> stageMessages = {
    BlockingStage.firstTime: [
      'Focus time is active! You have one 2-minute grace period available.',
      'Time to focus! Need a quick break? Use your 2-minute grace period.',
      'Focus mode engaged. One grace period available if needed.',
    ],
    
    BlockingStage.graceExpired: [
      'Time\'s up. Back to focus!',
      'Let\'s stay disciplined.',
      'Come on, you\'ve got this!',
      'Grace period over. Focus time!',
      'No more delays. Back to work!',
    ],
    
    BlockingStage.immediate: [
      'This app is locked during focus time.',
      'Focus mode is still active.',
      'App blocked. Check your focus timer.',
      'Stay focused! App access denied.',
    ],
    
    BlockingStage.repeated: [
      'Whoa! Slow down. Stay focused!',
      'Let\'s not do this again.',
      'Focus mode still active!',
      'Too many attempts! Time to focus.',
      'Still blocked. Please focus.',
      'Seriously? Back to work!',
      'You know the drill. Focus time!',
      'Persistent, aren\'t we? Stay on task!',
    ],
  };
  
  /// Get a random message for the specified blocking stage
  static String getRandomMessage(BlockingStage stage) {
    final messages = stageMessages[stage] ?? stageMessages[BlockingStage.immediate]!;
    if (messages.isEmpty) {
      return 'Focus time is active';
    }
    final index = Random().nextInt(messages.length);
    return messages[index];
  }
  
  /// Get a specific message by index for testing purposes
  static String getMessageByIndex(BlockingStage stage, int index) {
    final messages = stageMessages[stage] ?? stageMessages[BlockingStage.immediate]!;
    if (messages.isEmpty) {
      return 'Focus time is active';
    }
    final safeIndex = index % messages.length;
    return messages[safeIndex];
  }
  
  /// Get all messages for a stage (useful for UI previews)
  static List<String> getAllMessages(BlockingStage stage) {
    return stageMessages[stage] ?? stageMessages[BlockingStage.immediate]!;
  }
  
  /// Determine what stage this blocking attempt should be based on simple criteria
  /// This is a simplified version - you can enhance it based on your needs
  static BlockingStage determineStage({
    bool hasUsedGracePeriod = false,
    bool isQuickRetry = false,
    int attemptCount = 1,
  }) {
    if (attemptCount >= 4) {
      return BlockingStage.repeated;
    } else if (hasUsedGracePeriod && attemptCount > 1) {
      return BlockingStage.graceExpired;
    } else if (isQuickRetry) {
      return BlockingStage.immediate;
    } else {
      return BlockingStage.firstTime;
    }
  }
}