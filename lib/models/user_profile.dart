import 'habit.dart';

class UserProfile {
  final String id;
  final String name;
  final UserMood? currentMood;
  final List<HabitCategory> preferredCategories;
  final DateTime lastMoodUpdate;
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int totalHabitsCompleted;
  final int longestStreak;
  final int currentStreak;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    this.currentMood,
    this.preferredCategories = const [],
    required this.lastMoodUpdate,
    this.notificationsEnabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.totalHabitsCompleted = 0,
    this.longestStreak = 0,
    this.currentStreak = 0,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    UserMood? currentMood,
    List<HabitCategory>? preferredCategories,
    DateTime? lastMoodUpdate,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? totalHabitsCompleted,
    int? longestStreak,
    int? currentStreak,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      currentMood: currentMood ?? this.currentMood,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      lastMoodUpdate: lastMoodUpdate ?? this.lastMoodUpdate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
      longestStreak: longestStreak ?? this.longestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentMood': currentMood?.name,
      'preferredCategories': preferredCategories.map((cat) => cat.name).toList(),
      'lastMoodUpdate': lastMoodUpdate.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'totalHabitsCompleted': totalHabitsCompleted,
      'longestStreak': longestStreak,
      'currentStreak': currentStreak,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      currentMood: json['currentMood'] != null
          ? UserMood.values.firstWhere(
              (mood) => mood.name == json['currentMood'],
              orElse: () => UserMood.happy,
            )
          : null,
      preferredCategories: (json['preferredCategories'] as List<dynamic>)
          .map((catName) => HabitCategory.values.firstWhere(
                (cat) => cat.name == catName,
                orElse: () => HabitCategory.mindfulness,
              ))
          .toList(),
      lastMoodUpdate: DateTime.parse(json['lastMoodUpdate']),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      reminderHour: json['reminderHour'] ?? 9,
      reminderMinute: json['reminderMinute'] ?? 0,
      totalHabitsCompleted: json['totalHabitsCompleted'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}