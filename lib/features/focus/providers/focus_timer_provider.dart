import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../blocking/providers/app_blocking_provider.dart';

enum FocusMode { pomodoro, deepFocus }
enum TimerState { idle, running, paused, completed }

class FocusTimerProvider extends ChangeNotifier {
  // Timer configuration
  FocusMode _focusMode = FocusMode.pomodoro;
  TimerState _timerState = TimerState.idle;
  
  // Gamification integration
  GamificationProvider? _gamificationProvider;
  
  // App blocking integration
  AppBlockingProvider? _appBlockingProvider;
  
  // Callback for XP rewards (legacy support)
  Function(int xp, String reason)? _onXPEarned;
  Function(String badgeId, int progress)? _onBadgeProgress;
  
  // Pomodoro settings
  final int _pomodoroMinutes = 25;
  final int _shortBreakMinutes = 5;
  final int _longBreakMinutes = 15;
  final int _sessionsBeforeLongBreak = 4;
  int _currentSession = 1;
  
  // Deep focus settings
  final int _deepFocusMinutes = 60;
  
  // Current timer
  int _remainingSeconds = 0;
  int _initialSeconds = 0;
  Timer? _timer;
  Timer? _pointsTimer; // For awarding points per minute
  
  // Stats
  int _totalSessionsToday = 0;
  int _totalFocusMinutesToday = 0;
  DateTime? _lastSessionDate;
  DateTime? _sessionStartTime;
  
  // Getters
  FocusMode get focusMode => _focusMode;
  TimerState get timerState => _timerState;
  int get remainingSeconds => _remainingSeconds;
  int get currentSession => _currentSession;
  int get totalSessions => _sessionsBeforeLongBreak;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get totalSessionsToday => _totalSessionsToday;
  int get totalFocusMinutesToday => _totalFocusMinutesToday;
  
  double get progress {
    final totalSeconds = _getCurrentModeMinutes() * 60;
    return 1 - (_remainingSeconds / totalSeconds);
  }
  
  String get timeDisplay {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  FocusTimerProvider() {
    _loadFromStorage();
  }

  // Set gamification provider
  void setGamificationProvider(GamificationProvider gamificationProvider) {
    _gamificationProvider = gamificationProvider;
  }

  // Set app blocking provider
  void setAppBlockingProvider(AppBlockingProvider appBlockingProvider) {
    _appBlockingProvider = appBlockingProvider;
  }

  // Set reward callbacks (legacy support)
  void setRewardCallbacks({
    Function(int xp, String reason)? onXPEarned,
    Function(String badgeId, int progress)? onBadgeProgress,
  }) {
    _onXPEarned = onXPEarned;
    _onBadgeProgress = onBadgeProgress;
  }

  void setFocusMode(FocusMode mode) {
    if (_timerState == TimerState.running) return;
    _focusMode = mode;
    _resetTimer();
    notifyListeners();
  }
  
  void startTimer() {
    if (_timerState == TimerState.running) return;
    
    if (_timerState == TimerState.idle) {
      _remainingSeconds = _getCurrentModeMinutes() * 60;
      _initialSeconds = _remainingSeconds;
      _sessionStartTime = DateTime.now();
      
      // Start gamification tracking
      _gamificationProvider?.startFocusSession(_getCurrentModeMinutes());
    }
    
    _timerState = TimerState.running;
    _startTicking();
    _startPointsTracking();
    
    // Enable focus mode blocking
    _appBlockingProvider?.enableFocusMode();
    debugPrint('🎯 Focus mode ENABLED - Apps will be blocked during session');
    
    notifyListeners();
  }
  
  void pauseTimer() {
    if (_timerState != TimerState.running) return;
    _timerState = TimerState.paused;
    _timer?.cancel();
    _pointsTimer?.cancel();
    
    // Temporarily disable focus mode blocking while paused
    _appBlockingProvider?.disableFocusMode();
    debugPrint('⏸️ Focus mode PAUSED - Apps unblocked temporarily');
    
    notifyListeners();
  }
  
  void stopTimer() {
    // Handle early exit if session was in progress
    if (_timerState == TimerState.running || _timerState == TimerState.paused) {
      final actualMinutes = _getActualSessionMinutes();
      final plannedMinutes = _getCurrentModeMinutes();
      
      if (actualMinutes < plannedMinutes) {
        // This is an early exit - apply penalty
        _gamificationProvider?.exitSessionEarly(actualMinutes);
        debugPrint('🚨 Early exit detected: $actualMinutes/$plannedMinutes minutes');
      } else {
        // Session was completed normally
        _gamificationProvider?.completeSession(actualMinutes);
      }
    }
    
    _timerState = TimerState.idle;
    _timer?.cancel();
    _pointsTimer?.cancel();
    _resetTimer();
    notifyListeners();
  }
  
  /// Emergency stop (applies penalty)
  void emergencyStop() {
    _gamificationProvider?.emergencyStop();
    
    // Disable focus mode blocking immediately
    _appBlockingProvider?.disableFocusMode();
    debugPrint('🚨 Emergency stop - Focus mode DISABLED');
    
    _timerState = TimerState.idle;
    _timer?.cancel();
    _pointsTimer?.cancel();
    _resetTimer();
    notifyListeners();
  }
  
  /// Get current session duration for testing
  int get currentSessionMinutes => _getActualSessionMinutes();
  
  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeSession();
      }
    });
  }
  
  void _startPointsTracking() {
    _pointsTimer?.cancel();
    _pointsTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Award 1 point for every minute of focus
      _gamificationProvider?.awardFocusMinute();
    });
  }
  
  int _getActualSessionMinutes() {
    if (_sessionStartTime == null) return 0;
    final elapsed = (_initialSeconds - _remainingSeconds) ~/ 60;
    return elapsed.clamp(0, _getCurrentModeMinutes());
  }

  /// Get planned session minutes
  int getPlannedSessionMinutes() {
    return _getCurrentModeMinutes();
  }
  
  void _completeSession() {
    _timer?.cancel();
    _pointsTimer?.cancel();
    _timerState = TimerState.completed;
    
    // Update stats
    _updateSessionStats();
    
    // Complete session in gamification system
    final actualMinutes = _getCurrentModeMinutes(); // Full session completed
    _gamificationProvider?.completeSession(actualMinutes);
    
    // Disable focus mode blocking
    _appBlockingProvider?.disableFocusMode();
    debugPrint('✅ Session completed - Focus mode DISABLED');
    
    // Legacy XP system (for backward compatibility)
    final xpReward = actualMinutes * 2; // 2 XP per minute focused
    _onXPEarned?.call(xpReward, 'focus session ($actualMinutes min)');
    
    // Update badge progress
    _onBadgeProgress?.call('focus_rookie', _totalSessionsToday);
    _onBadgeProgress?.call('focus_master', _totalSessionsToday);
    
    // Move to next session
    if (_focusMode == FocusMode.pomodoro) {
      _currentSession++;
      if (_currentSession > _sessionsBeforeLongBreak) {
        _currentSession = 1;
      }
    }
    
    // Disable focus mode blocking
    _appBlockingProvider?.disableFocusMode();
    debugPrint('✅ Session completed - Focus mode DISABLED');
    
    _saveToStorage();
    notifyListeners();
  }
  
  void _updateSessionStats() {
    final now = DateTime.now();
    final lastDate = _lastSessionDate;
    
    // Reset daily stats if it's a new day
    if (lastDate == null || !_isSameDay(now, lastDate)) {
      _totalSessionsToday = 0;
      _totalFocusMinutesToday = 0;
    }
    
    _totalSessionsToday++;
    _totalFocusMinutesToday += _getCurrentModeMinutes();
    _lastSessionDate = now;
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  void _resetTimer() {
    _remainingSeconds = _getCurrentModeMinutes() * 60;
  }
  
  int _getCurrentModeMinutes() {
    return _focusMode == FocusMode.pomodoro 
        ? _pomodoroMinutes 
        : _deepFocusMinutes;
  }
  
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalSessionsToday = prefs.getInt('totalSessionsToday') ?? 0;
      _totalFocusMinutesToday = prefs.getInt('totalFocusMinutesToday') ?? 0;
      final lastDateStr = prefs.getString('lastSessionDate');
      if (lastDateStr != null) {
        _lastSessionDate = DateTime.parse(lastDateStr);
        
        // Reset if it's a new day
        if (!_isSameDay(DateTime.now(), _lastSessionDate!)) {
          _totalSessionsToday = 0;
          _totalFocusMinutesToday = 0;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading timer data: $e');
    }
  }
  
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('totalSessionsToday', _totalSessionsToday);
      await prefs.setInt('totalFocusMinutesToday', _totalFocusMinutesToday);
      if (_lastSessionDate != null) {
        await prefs.setString('lastSessionDate', _lastSessionDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving timer data: $e');
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pointsTimer?.cancel();
    super.dispose();
  }
}
