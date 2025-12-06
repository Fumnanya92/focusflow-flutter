import 'package:uuid/uuid.dart';

enum ChallengeStatus { waiting, active, completed }

class Participant {
  final String id;
  final String name;
  final bool isEliminated;
  final DateTime? eliminatedAt;

  Participant({
    String? id,
    required this.name,
    this.isEliminated = false,
    this.eliminatedAt,
  }) : id = id ?? const Uuid().v4();

  Participant copyWith({
    String? id,
    String? name,
    bool? isEliminated,
    DateTime? eliminatedAt,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      isEliminated: isEliminated ?? this.isEliminated,
      eliminatedAt: eliminatedAt ?? this.eliminatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isEliminated': isEliminated,
      'eliminatedAt': eliminatedAt?.toIso8601String(),
    };
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      name: json['name'],
      isEliminated: json['isEliminated'] ?? false,
      eliminatedAt: json['eliminatedAt'] != null
          ? DateTime.parse(json['eliminatedAt'])
          : null,
    );
  }
}

class Challenge {
  final String id;
  final String name;
  final int durationMinutes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<Participant> participants;
  final ChallengeStatus status;
  final String? winnerId;
  final int xpReward;

  Challenge({
    String? id,
    required this.name,
    required this.durationMinutes,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    List<Participant>? participants,
    this.status = ChallengeStatus.waiting,
    this.winnerId,
    this.xpReward = 50,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        participants = participants ?? [];

  Challenge copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<Participant>? participants,
    ChallengeStatus? status,
    String? winnerId,
    int? xpReward,
  }) {
    return Challenge(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  int get activeParticipantsCount =>
      participants.where((p) => !p.isEliminated).length;

  Participant? get winner =>
      winnerId != null
          ? participants.firstWhere((p) => p.id == winnerId)
          : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'status': status.name,
      'winnerId': winnerId,
      'xpReward': xpReward,
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      name: json['name'],
      durationMinutes: json['durationMinutes'],
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p))
          .toList(),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChallengeStatus.waiting,
      ),
      winnerId: json['winnerId'],
      xpReward: json['xpReward'] ?? 50,
    );
  }
}
