import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _userProfileKey = 'user_profile';
  static const String _habitsKey = 'habits';
  static const String _isFirstLaunchKey = 'is_first_launch';

  // User Profile methods
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = jsonEncode(profile.toJson());
    await prefs.setString(_userProfileKey, profileJson);
  }

  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    
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
    await prefs.setString(_habitsKey, habitsJson);
  }

  Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(_habitsKey);
    
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
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
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
}