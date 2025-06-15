import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String title;
  final String description;
  final HabitCategory category;
  final int durationMinutes;
  final DateTime createdAt;
  final List<DateTime> completedDates;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationMinutes,
    required this.createdAt,
    this.completedDates = const [],
  });

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    
    final today = DateTime.now();
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime checkDate = DateTime(today.year, today.month, today.day);
    
    for (final date in sortedDates) {
      final completedDate = DateTime(date.year, date.month, date.day);
      if (completedDate.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (completedDate.isBefore(checkDate)) {
        break;
      }
    }
    
    return streak;
  }

  bool get isCompletedToday {
    final today = DateTime.now();
    return completedDates.any((date) => 
        date.year == today.year && 
        date.month == today.month && 
        date.day == today.day);
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    HabitCategory? category,
    int? durationMinutes,
    DateTime? createdAt,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'durationMinutes': durationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates.map((date) => date.toIso8601String()).toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: HabitCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => HabitCategory.mindfulness,
      ),
      durationMinutes: json['durationMinutes'],
      createdAt: DateTime.parse(json['createdAt']),
      completedDates: (json['completedDates'] as List<dynamic>)
          .map((dateStr) => DateTime.parse(dateStr))
          .toList(),
    );
  }
}

enum HabitCategory {
  physical('Physical Activity', '🏃‍♂️'),
  mindfulness('Mindfulness', '🧘‍♀️'),
  relaxation('Relaxation', '😌'),
  productivity('Productivity', '📝');

  const HabitCategory(this.displayName, this.emoji);
  
  final String displayName;
  final String emoji;
  
  Color get color {
    switch (this) {
      case HabitCategory.physical:
        return const Color(0xFF4CAF50);
      case HabitCategory.mindfulness:
        return const Color(0xFF6C63FF);
      case HabitCategory.relaxation:
        return const Color(0xFF00BCD4);
      case HabitCategory.productivity:
        return const Color(0xFFFF9800);
    }
  }
}

enum UserMood {
  happy('Happy', '😊'),
  stressed('Stressed', '😰'),
  tired('Tired', '😴'),
  energized('Energized', '⚡');

  const UserMood(this.displayName, this.emoji);
  
  final String displayName;
  final String emoji;
}