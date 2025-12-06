class User {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final DateTime joinedDate;
  final int level;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final List<String> badges;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.joinedDate,
    this.level = 1,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badges = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    DateTime? joinedDate,
    int? level,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    List<String>? badges,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      joinedDate: joinedDate ?? this.joinedDate,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'joinedDate': joinedDate.toIso8601String(),
      'level': level,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'badges': badges,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImage: json['profileImage'],
      joinedDate: DateTime.parse(json['joinedDate']),
      level: json['level'] ?? 1,
      totalXP: json['totalXP'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
    );
  }
}
