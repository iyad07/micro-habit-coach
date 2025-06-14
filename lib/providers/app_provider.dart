import 'package:flutter/material.dart';
import 'dart:math';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/ai_agent_service.dart';
import '../services/notification_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final AIAgentService _aiAgent = AIAgentService();
  final NotificationService _notifications = NotificationService();

  UserProfile? _userProfile;
  List<Habit> _habits = [];
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  Habit? _todaysHabit;
  Map<String, String>? _currentSuggestion;

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  bool get isFirstLaunch => _isFirstLaunch;
  Habit? get todaysHabit => _todaysHabit;
  Map<String, String>? get currentSuggestion => _currentSuggestion;
  AIAgentService get aiAgent => _aiAgent;

  // Initialize the app
  Future<void> initialize() async {
    _isLoading = true;

    try {
      // Initialize notifications with error handling
      try {
        await _notifications.initialize();
      } catch (notificationError) {
        print('Notification initialization failed: $notificationError');
        // Continue app initialization even if notifications fail
      }
      
      // Check if first launch
      _isFirstLaunch = await _storage.isFirstLaunch();
      
      // Load user profile and habits
      _userProfile = await _storage.getUserProfile();
      _habits = await _storage.getHabits();
      
      // Get today's habit if user exists
      if (_userProfile != null) {
        await _loadTodaysHabit();
        await _scheduleNotifications();
      }
    } catch (e) {
      print('Error initializing app: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding(String name, UserMood mood, List<HabitCategory> preferences) async {
    try {
      // Create user profile
      _userProfile = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        currentMood: mood,
        preferredCategories: preferences,
        lastMoodUpdate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      // Save profile
      await _storage.saveUserProfile(_userProfile!);
      await _storage.setFirstLaunchComplete();
      
      // Generate first habit suggestion
      await generateHabitSuggestion();
      
      // Schedule notifications
      await _scheduleNotifications();
      
      _isFirstLaunch = false;
      notifyListeners();
    } catch (e) {
      print('Error completing onboarding: $e');
    }
  }

  // Update user mood
  Future<void> updateMood(UserMood mood) async {
    if (_userProfile == null) return;
    
    try {
      _userProfile = _userProfile!.copyWith(
        currentMood: mood,
        lastMoodUpdate: DateTime.now(),
      );
      
      await _storage.saveUserProfile(_userProfile!);
      
      // Generate new suggestion based on mood
      await generateHabitSuggestion();
      
      notifyListeners();
    } catch (e) {
      print('Error updating mood: $e');
    }
  }

  // Update user preferences
  Future<void> updatePreferences(List<HabitCategory> preferences) async {
    if (_userProfile == null) return;
    
    try {
      _userProfile = _userProfile!.copyWith(
        preferredCategories: preferences,
      );
      
      await _storage.saveUserProfile(_userProfile!);
      
      // Generate new suggestion based on preferences
      await generateHabitSuggestion();
      
      notifyListeners();
    } catch (e) {
      print('Error updating preferences: $e');
    }
  }

  // Generate habit suggestion
  Future<void> generateHabitSuggestion() async {
    if (_userProfile?.currentMood == null) return;
    
    try {
      _currentSuggestion = _aiAgent.generateHabitSuggestion(
        _userProfile!.currentMood!,
        _userProfile!.preferredCategories,
      );
      
      notifyListeners();
    } catch (e) {
      print('Error generating habit suggestion: $e');
    }
  }

  // Accept habit suggestion and create habit
  Future<void> acceptHabitSuggestion() async {
    if (_currentSuggestion == null || _userProfile == null) return;
    
    try {
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _currentSuggestion!['title']!,
        description: _currentSuggestion!['description']!,
        category: _userProfile!.preferredCategories.isNotEmpty 
            ? _userProfile!.preferredCategories.first 
            : HabitCategory.mindfulness,
        durationMinutes: 5, // Default duration
        createdAt: DateTime.now(),
      );
      
      await _storage.addHabit(habit);
      _habits = await _storage.getHabits();
      _todaysHabit = habit;
      
      notifyListeners();
    } catch (e) {
      print('Error accepting habit suggestion: $e');
    }
  }

  // Complete today's habit
  Future<void> completeHabit(String habitId) async {
    try {
      await _storage.completeHabit(habitId);
      _habits = await _storage.getHabits();
      
      // Find the completed habit
      final completedHabit = _habits.firstWhere((h) => h.id == habitId);
      
      // Show completion notification
      await _notifications.showHabitCompletionNotification(
        completedHabit.title,
        completedHabit.currentStreak,
      );
      
      // Check for streak milestones
      if (completedHabit.currentStreak > 1) {
        await _notifications.showStreakMilestoneNotification(
          completedHabit.currentStreak,
        );
      }
      
      // Update user profile stats
      await _updateUserStats();
      
      // Load new today's habit
      await _loadTodaysHabit();
      
      notifyListeners();
    } catch (e) {
      print('Error completing habit: $e');
    }
  }

  // Load today's habit
  Future<void> _loadTodaysHabit() async {
    try {
      _todaysHabit = await _storage.getTodaysHabit();
      notifyListeners();
    } catch (e) {
      print('Error loading today\'s habit: $e');
    }
  }

  // Update user statistics
  Future<void> _updateUserStats() async {
    if (_userProfile == null) return;
    
    try {
      final stats = await _storage.getCompletionStats();
      
      _userProfile = _userProfile!.copyWith(
        totalHabitsCompleted: stats['totalCompletions']!,
        longestStreak: stats['longestStreak']!,
      );
      
      await _storage.saveUserProfile(_userProfile!);
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Schedule notifications
  Future<void> _scheduleNotifications() async {
    if (_userProfile != null) {
      try {
        await _notifications.scheduleDailyReminder(_userProfile!);
      } catch (e) {
        print('Failed to schedule notifications: $e');
        // Continue without notifications if scheduling fails
      }
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings(bool enabled, int hour, int minute) async {
    if (_userProfile == null) return;
    
    try {
      _userProfile = _userProfile!.copyWith(
        notificationsEnabled: enabled,
        reminderHour: hour,
        reminderMinute: minute,
      );
      
      await _storage.saveUserProfile(_userProfile!);
      
      if (enabled) {
        await _scheduleNotifications();
      } else {
        await _notifications.cancelDailyReminder();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }

  // Get completion statistics
  Future<Map<String, int>> getCompletionStats() async {
    return await _storage.getCompletionStats();
  }

  // Get motivational message based on progress
  String getMotivationalMessage() {
    if (_userProfile == null) return 'Welcome to your habit journey!';
    
    final totalCompleted = _userProfile!.totalHabitsCompleted;
    final longestStreak = _userProfile!.longestStreak;
    
    final messages = _aiAgent.getProgressMessages(totalCompleted, longestStreak);
    return _aiAgent.getRandomMessage(messages);
  }

  // Get completion message for a specific streak
  String getCompletionMessage(int streak) {
    final messages = _aiAgent.getCompletionMessages(streak);
    return _aiAgent.getRandomMessage(messages);
  }

  // Get missed habit message
  String getMissedHabitMessage() {
    return _aiAgent.getRandomMessage(_aiAgent.missedHabitMessages);
  }

  // Reset app data (for testing)
  Future<void> resetAppData() async {
    try {
      await _storage.clearAllData();
      await _notifications.cancelAllNotifications();
      
      _userProfile = null;
      _habits = [];
      _todaysHabit = null;
      _currentSuggestion = null;
      _isFirstLaunch = true;
      
      notifyListeners();
    } catch (e) {
      print('Error resetting app data: $e');
    }
  }
}