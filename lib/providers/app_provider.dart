import 'package:flutter/material.dart';
import 'dart:math';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/ai_agent_service.dart';
import '../services/notification_service.dart';
import '../services/app_usage_service.dart';
import 'demo_mode_provider.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final AIAgentService _aiAgentService = AIAgentService();
  final NotificationService _notificationService = NotificationService();
  final DemoModeProvider _demoModeProvider = DemoModeProvider();
  late final AppUsageService _appUsageService;

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
  AIAgentService get aiAgent => _aiAgentService;
  StorageService get storageService => _storageService;
  NotificationService get notificationService => _notificationService;
  AppUsageService get appUsageService => _appUsageService;
  DemoModeProvider get demoModeProvider => _demoModeProvider;

  // Initialize the app
  Future<void> initialize() async {
    _isLoading = true;

    try {
      // Initialize demo mode provider
      // Skip demo mode initialization since method doesn't exist
      _demoModeProvider; // Access provider to ensure it's instantiated
      
      // Initialize app usage service with demo mode context
      _appUsageService = AppUsageService.create(demoModeProvider: _demoModeProvider);
      
      // Initialize notifications with error handling
      try {
        await _notificationService.initialize();
      } catch (notificationError) {
        print('Notification initialization failed: $notificationError');
        // Continue app initialization even if notifications fail
      }
      
      // Check if first launch
      _isFirstLaunch = await _storageService.isFirstLaunch();
      
      // Load user profile and habits
      _userProfile = await _storageService.getUserProfile();
      _habits = await _storageService.getHabits();
      
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
      await _storageService.saveUserProfile(_userProfile!);
      await _storageService.setFirstLaunchComplete();
      
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
      
      await _storageService.saveUserProfile(_userProfile!);
      
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
      
      await _storageService.saveUserProfile(_userProfile!);
      
      // Generate new suggestion based on preferences
      await generateHabitSuggestion();
      
      notifyListeners();
    } catch (e) {
      print('Error updating preferences: $e');
    }
  }

  // Generate habit suggestion using AI analysis
  Future<void> generateHabitSuggestion() async {
    if (_userProfile?.currentMood == null) return;
    
    try {
      print('Generating AI suggestion for mood: ${_userProfile!.currentMood}, preferences: ${_userProfile!.preferredCategories}');
      
      // Use AI service to generate personalized suggestion
      final suggestion = await _aiAgentService.generatePersonalizedHabitSuggestion(
        mood: _userProfile!.currentMood!,
        preferences: _userProfile!.preferredCategories,
        currentStreak: _todaysHabit?.currentStreak ?? 0,
        recentCompletions: _getRecentCompletions(),
      );
      
      print('AI suggestion received: $suggestion');
      
      final suggestionData = suggestion['suggestion'] as Map<String, dynamic>;
      _currentSuggestion = {
        'title': suggestionData['title'] ?? 'Mindful Breathing',
        'description': suggestionData['description'] ?? 'Take 5 minutes to focus on your breathing',
        'category': suggestionData['category'] ?? 'Mindfulness',
        'duration': suggestionData['duration']?.toString() ?? '5',
        'reasoning': suggestion['reasoning'] ?? 'Based on your current mood and preferences',
      };
      
      print('Final suggestion set: $_currentSuggestion');
      notifyListeners();
    } catch (e) {
      print('Error generating AI habit suggestion: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Fallback to basic suggestion with proper data mapping
      final basicSuggestion = _aiAgentService.generateHabitSuggestion(
        _userProfile!.currentMood!,
        _userProfile!.preferredCategories,
      );
      
      print('Using basic suggestion fallback: $basicSuggestion');
      
      _currentSuggestion = {
        'title': basicSuggestion['title'] ?? 'Mindful Breathing',
        'description': basicSuggestion['description'] ?? 'Take 5 minutes to focus on your breathing',
        'category': _getCategoryFromBasicSuggestion(basicSuggestion),
        'duration': _getDurationFromBasicSuggestion(basicSuggestion),
        'reasoning': basicSuggestion['prompt'] ?? 'Based on your current mood and preferences',
      };
      notifyListeners();
    }
  }

  // Accept habit suggestion and create habit
  Future<void> acceptHabitSuggestion() async {
    if (_currentSuggestion == null || _userProfile == null) return;
    
    try {
      // Parse category from suggestion
      HabitCategory category = HabitCategory.mindfulness;
      try {
        category = HabitCategory.values.firstWhere(
          (cat) => cat.displayName.toLowerCase() == _currentSuggestion!['category']?.toLowerCase(),
          orElse: () => HabitCategory.mindfulness,
        );
      } catch (e) {
        print('Error parsing category, using default: $e');
      }
      
      // Parse duration from suggestion
      int duration = 5;
      try {
        duration = int.tryParse(_currentSuggestion!['duration'] ?? '5') ?? 5;
      } catch (e) {
        print('Error parsing duration, using default: $e');
      }
      
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _currentSuggestion!['title']!,
        description: _currentSuggestion!['description']!,
        category: category,
        durationMinutes: duration,
        createdAt: DateTime.now(),
      );
      
      await _storageService.addHabit(habit);
      _habits = await _storageService.getHabits();
      _todaysHabit = habit;
      
      // Clear current suggestion after acceptance
      _currentSuggestion = null;
      
      notifyListeners();
    } catch (e) {
      print('Error accepting habit suggestion: $e');
    }
  }

  // Get recent completions for AI analysis
  Map<String, int> _getRecentCompletions() {
    final completions = <String, int>{};
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    for (final habit in _habits) {
      final recentCompletions = habit.completedDates
          .where((completion) => completion.isAfter(sevenDaysAgo))
          .length;
      if (recentCompletions > 0) {
        completions[habit.category.displayName] = recentCompletions;
      }
    }
    
    return completions;
  }

  // Helper method to extract category from basic suggestion
  String _getCategoryFromBasicSuggestion(Map<String, String> suggestion) {
    final title = suggestion['title']?.toLowerCase() ?? '';
    final description = suggestion['description']?.toLowerCase() ?? '';
    
    // Map keywords to categories
    if (title.contains('breathing') || title.contains('meditation') || 
        title.contains('mindful') || title.contains('gratitude')) {
      return 'Mindfulness';
    } else if (title.contains('walk') || title.contains('exercise') || 
               title.contains('stretch') || title.contains('yoga') || 
               title.contains('dance') || title.contains('workout')) {
      return 'Physical';
    } else if (title.contains('nap') || title.contains('music') || 
               title.contains('relax') || title.contains('calm')) {
      return 'Relaxation';
    } else if (title.contains('writing') || title.contains('learning') || 
               title.contains('journal') || title.contains('read')) {
      return 'Productivity';
    }
    
    return 'Mindfulness'; // Default fallback
  }

  // Helper method to extract duration from basic suggestion
  String _getDurationFromBasicSuggestion(Map<String, String> suggestion) {
    final title = suggestion['title'] ?? '';
    final description = suggestion['description'] ?? '';
    
    // Extract numbers from title or description
    final regex = RegExp(r'(\d+)');
    final titleMatch = regex.firstMatch(title);
    if (titleMatch != null) {
      return titleMatch.group(1)!;
    }
    
    final descMatch = regex.firstMatch(description);
    if (descMatch != null) {
      return descMatch.group(1)!;
    }
    
    return '5'; // Default duration
  }

  // Generate next day suggestion based on completed habit
  Future<void> generateNextDaySuggestion() async {
    if (_userProfile == null || _todaysHabit == null) return;
    
    try {
      // Try to use the advanced AI method first
      final suggestion = await _aiAgentService.generatePersonalizedHabitSuggestion(
        mood: _userProfile!.currentMood!,
        preferences: _userProfile!.preferredCategories,
        currentStreak: _todaysHabit?.currentStreak ?? 0,
        recentCompletions: _getRecentCompletions(),
      );
      
      final suggestionData = suggestion['suggestion'] as Map<String, dynamic>;
      _currentSuggestion = {
        'title': suggestionData['title'] ?? 'Continue Your Journey',
        'description': suggestionData['description'] ?? 'Build on today\'s success',
        'category': suggestionData['category'] ?? 'Mindfulness',
        'duration': suggestionData['duration']?.toString() ?? '5',
        'reasoning': suggestion['reasoning'] ?? 'Based on your completed habit',
      };
      
      notifyListeners();
    } catch (e) {
      print('Error generating next day suggestion: $e');
      // Fallback to basic suggestion with proper mapping
      final basicSuggestion = _aiAgentService.generateHabitSuggestion(
        _userProfile!.currentMood!,
        _userProfile!.preferredCategories,
      );
      
      _currentSuggestion = {
        'title': basicSuggestion['title'] ?? 'Continue Your Journey',
        'description': basicSuggestion['description'] ?? 'Build on today\'s success',
        'category': _getCategoryFromBasicSuggestion(basicSuggestion),
        'duration': _getDurationFromBasicSuggestion(basicSuggestion),
        'reasoning': basicSuggestion['prompt'] ?? 'Based on your completed habit',
      };
      notifyListeners();
    }
  }
  
  // Complete today's habit
  Future<void> completeHabit(String habitId) async {
    try {
      await _storageService.completeHabit(habitId);
      _habits = await _storageService.getHabits();
      
      // Find the completed habit
      final completedHabit = _habits.firstWhere((h) => h.id == habitId);
      
      // Show completion notification
      await _notificationService.showHabitCompletionNotification(
        completedHabit.title,
        completedHabit.currentStreak,
      );
      
      // Check for streak milestones
      if (completedHabit.currentStreak > 1) {
        await _notificationService.showStreakMilestoneNotification(
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
      _todaysHabit = await _storageService.getTodaysHabit();
      notifyListeners();
    } catch (e) {
      print('Error loading today\'s habit: $e');
    }
  }

  // Update user statistics
  Future<void> _updateUserStats() async {
    if (_userProfile == null) return;
    
    try {
      final stats = await _storageService.getCompletionStats();
      
      _userProfile = _userProfile!.copyWith(
        totalHabitsCompleted: stats['totalCompletions']!,
        longestStreak: stats['longestStreak']!,
      );
      
      await _storageService.saveUserProfile(_userProfile!);
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Schedule notifications
  Future<void> _scheduleNotifications() async {
    if (_userProfile != null) {
      try {
        await _notificationService.scheduleDailyReminder(_userProfile!);
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
      
      await _storageService.saveUserProfile(_userProfile!);
      
      if (enabled) {
        await _scheduleNotifications();
      } else {
        await _notificationService.cancelDailyReminder();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }

  // Get completion statistics
  Future<Map<String, int>> getCompletionStats() async {
    return await _storageService.getCompletionStats();
  }

  // Get motivational message based on progress
  String getMotivationalMessage() {
    if (_userProfile == null) return 'Welcome to your habit journey!';
    
    final totalCompleted = _userProfile!.totalHabitsCompleted;
    final longestStreak = _userProfile!.longestStreak;
    
    final messages = _aiAgentService.getProgressMessages(totalCompleted, longestStreak);
    return _aiAgentService.getRandomMessage(messages);
  }

  // Get completion message for a specific streak
  String getCompletionMessage(int streak) {
    final messages = _aiAgentService.getCompletionMessages(streak);
    return _aiAgentService.getRandomMessage(messages);
  }

  // Get missed habit message
  String getMissedHabitMessage() {
    return _aiAgentService.getRandomMessage(_aiAgentService.missedHabitMessages);
  }

  // Reset app data (for testing)
  Future<void> resetAppData() async {
    try {
      await _storageService.clearAllData();
      await _notificationService.cancelAllNotifications();
      
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