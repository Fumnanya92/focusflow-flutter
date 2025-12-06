import 'package:hive/hive.dart';

part 'user_data.g.dart';

@HiveType(typeId: 0)
class UserData extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String email;

  @HiveField(2)
  String? username;

  @HiveField(3)
  String? avatarUrl;

  @HiveField(4)
  late DateTime lastLoginAt;

  @HiveField(5)
  late bool rememberMe;

  @HiveField(6)
  int points;

  @HiveField(7)
  List<String> unlockedBadges;

  UserData({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    required this.lastLoginAt,
    this.rememberMe = false,
    this.points = 0,
    this.unlockedBadges = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'last_login_at': lastLoginAt.toIso8601String(),
      'remember_me': rememberMe,
      'points': points,
      'unlocked_badges': unlockedBadges,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      lastLoginAt: DateTime.parse(json['last_login_at']),
      rememberMe: json['remember_me'] ?? false,
      points: json['points'] ?? 0,
      unlockedBadges: List<String>.from(json['unlocked_badges'] ?? []),
    );
  }
}
