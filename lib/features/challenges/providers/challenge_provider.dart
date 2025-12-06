import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/challenge_model.dart';

class ChallengeProvider extends ChangeNotifier {
  List<Challenge> _challenges = [];
  Challenge? _currentChallenge;
  StreamSubscription? _accelerometerSubscription;
  Timer? _challengeTimer;
  int _remainingSeconds = 0;
  
  // Movement detection threshold
  static const double movementThreshold = 15.0;
  static const int movementWindowMs = 500;
  DateTime? _lastMovementCheck;

  List<Challenge> get challenges => _challenges;
  Challenge? get currentChallenge => _currentChallenge;
  int get remainingSeconds => _remainingSeconds;
  bool get isChallengeActive => _currentChallenge?.status == ChallengeStatus.active;
  
  String get timeRemaining {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ChallengeProvider() {
    _loadChallenges();
  }

  Future<void> createChallenge(String name, int durationMinutes) async {
    final challenge = Challenge(
      name: name,
      durationMinutes: durationMinutes,
    );
    
    _challenges.add(challenge);
    _currentChallenge = challenge;
    await _saveChallenges();
    notifyListeners();
  }

  Future<void> addParticipant(String participantName) async {
    if (_currentChallenge == null) return;

    final participant = Participant(name: participantName);
    final updatedParticipants = List<Participant>.from(_currentChallenge!.participants)
      ..add(participant);

    _currentChallenge = _currentChallenge!.copyWith(
      participants: updatedParticipants,
    );

    await _updateCurrentChallenge();
    notifyListeners();
  }

  Future<void> removeParticipant(String participantId) async {
    if (_currentChallenge == null) return;

    final updatedParticipants = _currentChallenge!.participants
        .where((p) => p.id != participantId)
        .toList();

    _currentChallenge = _currentChallenge!.copyWith(
      participants: updatedParticipants,
    );

    await _updateCurrentChallenge();
    notifyListeners();
  }

  Future<void> startChallenge() async {
    if (_currentChallenge == null || 
        _currentChallenge!.status != ChallengeStatus.waiting) {
      return;
    }

    _currentChallenge = _currentChallenge!.copyWith(
      status: ChallengeStatus.active,
      startedAt: DateTime.now(),
    );

    _remainingSeconds = _currentChallenge!.durationMinutes * 60;

    // Start countdown timer
    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeChallenge();
      }
    });

    // Start movement detection
    _startMovementDetection();

    await _updateCurrentChallenge();
    notifyListeners();
  }

  void _startMovementDetection() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      final lastCheck = _lastMovementCheck;

      // Throttle checks to avoid too frequent processing
      if (lastCheck != null &&
          now.difference(lastCheck).inMilliseconds < movementWindowMs) {
        return;
      }

      _lastMovementCheck = now;

      // Calculate magnitude of acceleration
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Subtract gravity (approximately 9.8 m/s²)
      final netAcceleration = (magnitude - 9.8).abs();

      if (netAcceleration > movementThreshold) {
        _eliminateCurrentUser();
      }
    });
  }

  void _eliminateCurrentUser() {
    if (_currentChallenge == null || !isChallengeActive) return;

    // For demo purposes, we'll mark the first non-eliminated participant
    // In a real app, this would be the current user
    final currentUserIndex = _currentChallenge!.participants
        .indexWhere((p) => !p.isEliminated);

    if (currentUserIndex == -1) return;

    final updatedParticipants = List<Participant>.from(_currentChallenge!.participants);
    updatedParticipants[currentUserIndex] = updatedParticipants[currentUserIndex]
        .copyWith(
          isEliminated: true,
          eliminatedAt: DateTime.now(),
        );

    _currentChallenge = _currentChallenge!.copyWith(
      participants: updatedParticipants,
    );

    // Check if only one participant remains
    if (_currentChallenge!.activeParticipantsCount <= 1) {
      _completeChallenge();
    } else {
      _updateCurrentChallenge();
      notifyListeners();
    }
  }

  Future<void> _completeChallenge() async {
    if (_currentChallenge == null) return;

    _challengeTimer?.cancel();
    _accelerometerSubscription?.cancel();

    // Determine winner (last non-eliminated participant)
    final winner = _currentChallenge!.participants
        .firstWhere((p) => !p.isEliminated, orElse: () => _currentChallenge!.participants.first);

    _currentChallenge = _currentChallenge!.copyWith(
      status: ChallengeStatus.completed,
      completedAt: DateTime.now(),
      winnerId: winner.id,
    );

    await _updateCurrentChallenge();
    notifyListeners();
  }

  Future<void> cancelChallenge() async {
    _challengeTimer?.cancel();
    _accelerometerSubscription?.cancel();
    
    if (_currentChallenge != null) {
      _challenges.removeWhere((c) => c.id == _currentChallenge!.id);
    }
    
    _currentChallenge = null;
    _remainingSeconds = 0;
    
    await _saveChallenges();
    notifyListeners();
  }

  Future<void> _updateCurrentChallenge() async {
    if (_currentChallenge == null) return;

    final index = _challenges.indexWhere((c) => c.id == _currentChallenge!.id);
    if (index != -1) {
      _challenges[index] = _currentChallenge!;
    }

    await _saveChallenges();
  }

  Future<void> _loadChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = prefs.getString('challenges');

      if (challengesJson != null) {
        final List<dynamic> decoded = jsonDecode(challengesJson);
        _challenges = decoded.map((json) => Challenge.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    }
  }

  Future<void> _saveChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = jsonEncode(_challenges.map((c) => c.toJson()).toList());
      await prefs.setString('challenges', challengesJson);
    } catch (e) {
      debugPrint('Error saving challenges: $e');
    }
  }

  @override
  void dispose() {
    _challengeTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}
