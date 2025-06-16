import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyHabits = 'habits';
  static const String _keyDemoMode = 'demo_mode';
  static const String _keyBehaviorPattern = 'behavior_pattern';

  // User Profile methods
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = jsonEncode(profile.toJson());
    await prefs.setString(_keyUserProfile, profileJson);
  }

  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_keyUserProfile);
    
    if (profileJson == null) return null;
    
    try {
      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
      return UserProfile.fromJson(profileMap);
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }

  // Habits methods
  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = jsonEncode(habits.map((habit) => habit.toJson()).toList());
    await prefs.setString(_keyHabits, habitsJson);
  }

  Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(_keyHabits);
    
    if (habitsJson == null) return [];
    
    try {
      final habitsList = jsonDecode(habitsJson) as List<dynamic>;
      return habitsList
          .map((habitMap) => Habit.fromJson(habitMap as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading habits: $e');
      return [];
    }
  }

  Future<void> addHabit(Habit habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await saveHabits(habits);
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final habits = await getHabits();
    final index = habits.indexWhere((habit) => habit.id == updatedHabit.id);
    
    if (index != -1) {
      habits[index] = updatedHabit;
      await saveHabits(habits);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final habits = await getHabits();
    habits.removeWhere((habit) => habit.id == habitId);
    await saveHabits(habits);
  }

  // Complete a habit for today
  Future<void> completeHabit(String habitId) async {
    final habits = await getHabits();
    final habitIndex = habits.indexWhere((habit) => habit.id == habitId);
    
    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      final today = DateTime.now();
      
      // Check if already completed today
      final isAlreadyCompleted = habit.completedDates.any((date) => 
          date.year == today.year && 
          date.month == today.month && 
          date.day == today.day);
      
      if (!isAlreadyCompleted) {
        final updatedHabit = habit.copyWith(
          completedDates: [...habit.completedDates, today],
        );
        habits[habitIndex] = updatedHabit;
        await saveHabits(habits);
        
        // Update user profile stats
        await _updateUserStats();
      }
    }
  }

  // Update user statistics
  Future<void> _updateUserStats() async {
    final profile = await getUserProfile();
    if (profile == null) return;
    
    final habits = await getHabits();
    int totalCompleted = 0;
    int longestStreak = 0;
    
    for (final habit in habits) {
      totalCompleted += habit.completedDates.length;
      if (habit.currentStreak > longestStreak) {
        longestStreak = habit.currentStreak;
      }
    }
    
    final updatedProfile = profile.copyWith(
      totalHabitsCompleted: totalCompleted,
      longestStreak: longestStreak,
    );
    
    await saveUserProfile(updatedProfile);
  }

  // First launch methods
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }
  
  // Demo mode methods
  Future<bool> getDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDemoMode) ?? false;
  }
  
  Future<void> setDemoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDemoMode, enabled);
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Get today's suggested habit
  Future<Habit?> getTodaysHabit() async {
    final habits = await getHabits();
    final today = DateTime.now();
    
    // Find a habit that hasn't been completed today
    for (final habit in habits) {
      final isCompletedToday = habit.completedDates.any((date) => 
          date.year == today.year && 
          date.month == today.month && 
          date.day == today.day);
      
      if (!isCompletedToday) {
        return habit;
      }
    }
    
    return null;
  }

  // Get completion statistics
  Future<Map<String, int>> getCompletionStats() async {
    final habits = await getHabits();
    int totalHabits = habits.length;
    int completedToday = 0;
    int totalCompletions = 0;
    int longestStreak = 0;
    
    final today = DateTime.now();
    
    for (final habit in habits) {
      totalCompletions += habit.completedDates.length;
      
      if (habit.isCompletedToday) {
        completedToday++;
      }
      
      if (habit.currentStreak > longestStreak) {
        longestStreak = habit.currentStreak;
      }
    }
    
    return {
      'totalHabits': totalHabits,
      'completedToday': completedToday,
      'totalCompletions': totalCompletions,
      'longestStreak': longestStreak,
    };
  }

  // Behavior Pattern methods for AI learning
  Future<void> saveBehaviorPattern(Map<String, dynamic> behaviorPattern) async {
    final prefs = await SharedPreferences.getInstance();
    final patternJson = jsonEncode(behaviorPattern);
    await prefs.setString(_keyBehaviorPattern, patternJson);
  }

  Future<Map<String, dynamic>?> getBehaviorPattern() async {
    final prefs = await SharedPreferences.getInstance();
    final patternJson = prefs.getString(_keyBehaviorPattern);
    
    if (patternJson == null) return null;
    
    try {
      final patternMap = jsonDecode(patternJson) as Map<String, dynamic>;
      return patternMap;
    } catch (e) {
      print('Error loading behavior pattern: $e');
      return null;
    }
  }

  Future<void> clearBehaviorPattern() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBehaviorPattern);
  }

  // Enhanced analytics for AI learning
  Future<Map<String, dynamic>> getDetailedAnalytics() async {
    final habits = await getHabits();
    final profile = await getUserProfile();
    final behaviorPattern = await getBehaviorPattern();
    
    final analytics = <String, dynamic>{
      'total_habits': habits.length,
      'active_habits': habits.length,
      'completion_rate': _calculateOverallCompletionRate(habits),
      'streak_distribution': _getStreakDistribution(habits),
      'category_performance': _getCategoryPerformance(habits),
      'time_patterns': _getTimePatterns(habits),
      'difficulty_preferences': _getDifficultyPreferences(habits),
      'user_profile': profile?.toJson(),
      'behavior_insights': behaviorPattern,
    };
    
    return analytics;
  }

  double _calculateOverallCompletionRate(List<Habit> habits) {
    if (habits.isEmpty) return 0.0;
    
    int totalPossibleCompletions = 0;
    int actualCompletions = 0;
    
    final now = DateTime.now();
    
    for (final habit in habits) {
      final daysSinceCreation = now.difference(habit.createdAt).inDays + 1;
      totalPossibleCompletions += daysSinceCreation;
      actualCompletions += habit.completedDates.length;
    }
    
    return totalPossibleCompletions > 0 ? actualCompletions / totalPossibleCompletions : 0.0;
  }

  Map<String, int> _getStreakDistribution(List<Habit> habits) {
    final distribution = <String, int>{
      '0': 0,
      '1-3': 0,
      '4-7': 0,
      '8-14': 0,
      '15+': 0,
    };
    
    for (final habit in habits) {
      final streak = habit.currentStreak;
      if (streak == 0) {
        distribution['0'] = distribution['0']! + 1;
      } else if (streak <= 3) {
        distribution['1-3'] = distribution['1-3']! + 1;
      } else if (streak <= 7) {
        distribution['4-7'] = distribution['4-7']! + 1;
      } else if (streak <= 14) {
        distribution['8-14'] = distribution['8-14']! + 1;
      } else {
        distribution['15+'] = distribution['15+']! + 1;
      }
    }
    
    return distribution;
  }

  Map<String, dynamic> _getCategoryPerformance(List<Habit> habits) {
    final categoryStats = <String, Map<String, dynamic>>{};
    
    for (final habit in habits) {
      final category = habit.category.name;
      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = {
          'count': 0,
          'total_completions': 0,
          'average_streak': 0.0,
          'completion_rate': 0.0,
        };
      }
      
      categoryStats[category]!['count'] = categoryStats[category]!['count'] + 1;
      categoryStats[category]!['total_completions'] = 
          categoryStats[category]!['total_completions'] + habit.completedDates.length;
    }
    
    // Calculate averages
    for (final category in categoryStats.keys) {
      final stats = categoryStats[category]!;
      final count = stats['count'] as int;
      if (count > 0) {
        final habitsInCategory = habits.where((h) => h.category.name == category).toList();
        final totalStreak = habitsInCategory.fold(0, (sum, h) => sum + h.currentStreak);
        stats['average_streak'] = totalStreak / count;
        
        // Calculate completion rate for this category
        final totalPossible = habitsInCategory.fold(0, (sum, h) => 
            sum + DateTime.now().difference(h.createdAt).inDays + 1);
        final totalCompleted = stats['total_completions'] as int;
        stats['completion_rate'] = totalPossible > 0 ? totalCompleted / totalPossible : 0.0;
      }
    }
    
    return categoryStats;
  }

  Map<String, int> _getTimePatterns(List<Habit> habits) {
    final timePatterns = <String, int>{
      'morning': 0,
      'afternoon': 0,
      'evening': 0,
      'night': 0,
    };
    
    for (final habit in habits) {
      for (final completionDate in habit.completedDates) {
        final hour = completionDate.hour;
        if (hour >= 6 && hour < 12) {
          timePatterns['morning'] = timePatterns['morning']! + 1;
        } else if (hour >= 12 && hour < 17) {
          timePatterns['afternoon'] = timePatterns['afternoon']! + 1;
        } else if (hour >= 17 && hour < 22) {
          timePatterns['evening'] = timePatterns['evening']! + 1;
        } else {
          timePatterns['night'] = timePatterns['night']! + 1;
        }
      }
    }
    
    return timePatterns;
  }

  Map<String, dynamic> _getDifficultyPreferences(List<Habit> habits) {
    final difficultyStats = <String, int>{
      'easy': 0,
      'moderate': 0,
      'challenging': 0,
    };
    
    for (final habit in habits) {
      // Estimate difficulty based on duration and completion rate
      final completionRate = habit.completedDates.length / 
          (DateTime.now().difference(habit.createdAt).inDays + 1);
      
      if (completionRate > 0.8) {
        difficultyStats['easy'] = difficultyStats['easy']! + 1;
      } else if (completionRate > 0.5) {
        difficultyStats['moderate'] = difficultyStats['moderate']! + 1;
      } else {
        difficultyStats['challenging'] = difficultyStats['challenging']! + 1;
      }
    }
    
    return {
      'distribution': difficultyStats,
      'preferred_difficulty': _getPreferredDifficulty(difficultyStats),
    };
  }

  String _getPreferredDifficulty(Map<String, int> difficultyStats) {
    String preferred = 'moderate';
    int maxCount = 0;
    
    for (final entry in difficultyStats.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        preferred = entry.key;
      }
    }
    
    return preferred;
  }
}