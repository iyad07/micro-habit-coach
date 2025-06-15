import 'dart:math';
import 'dart:convert';
import '../models/habit.dart';
import '../models/user_profile.dart';
import 'storage_service.dart';
import 'screen_time_service.dart';

// Habit difficulty levels
enum HabitDifficulty { easy, moderate, challenging }

class AIAgentService {
  static final AIAgentService _instance = AIAgentService._internal();
  factory AIAgentService() => _instance;
  AIAgentService._internal();

  final StorageService _storageService = StorageService();
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  
  // Screen time thresholds (in hours)
  static const double _highScreenTimeThreshold = 6.0;
  static const double _moderateScreenTimeThreshold = 3.0;
  
  // User behavior patterns
  final Map<String, dynamic> _userBehaviorPattern = {};

  // Welcome messages for onboarding
  List<String> get welcomeMessages => [
    "Welcome to Micro-Habit Tracker! Let's get started by understanding how you're feeling today.",
    "Hello there! I'm your personal habit companion. Let's begin this journey together!",
    "Great to see you! I'm here to help you build amazing micro-habits. Let's start!",
  ];

  // Mood collection prompts
  String get moodPrompt => "How do you feel right now? Please select an option:";

  // Preference collection prompts
  String get preferencePrompt => "Great! Now, tell me what kind of habit you'd like to focus on today:";

  // TASK 1: Analyzing User Mood and Preferences
  Future<Map<String, dynamic>> analyzeMoodAndPreferences(UserMood mood, List<HabitCategory> preferences) async {
    final analysis = {
      'mood': mood.name,
      'moodAnalysis': _getMoodAnalysis(mood),
      'preferences': preferences.map((p) => p.name).toList(),
      'recommendedCategories': _getRecommendedCategories(mood, preferences),
      'emotionalState': _analyzeEmotionalState(mood),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Store analysis for pattern learning
    await _updateBehaviorPattern('mood_analysis', analysis);
    
    return analysis;
  }

  // TASK 2: Analyzing Screen Time & Usage Patterns
  Future<Map<String, dynamic>> analyzeScreenTimeAndUsage([double? screenTimeHours, Map<String, double>? appUsage]) async {
    double actualScreenTime;
    Map<String, double>? actualAppUsage;
    
    // If no data provided, try to collect it automatically
    if (screenTimeHours == null || appUsage == null) {
      try {
        if (_screenTimeService.isSupported()) {
          if (await _screenTimeService.hasPermissions()) {
            actualScreenTime = screenTimeHours ?? await _screenTimeService.getTodayScreenTime();
            actualAppUsage = appUsage ?? await _screenTimeService.getTodayAppUsage();
          } else {
            // Return analysis indicating permission needed
            return {
              'screenTimeHours': 0.0,
              'screenTimeLevel': 'unknown',
              'recommendation': 'Please grant screen time permissions to get personalized suggestions',
              'balanceNeeded': false,
              'suggestedBreakDuration': 0,
              'appUsageAnalysis': null,
              'timestamp': DateTime.now().toIso8601String(),
              'permissionRequired': true,
              'supportMessage': _screenTimeService.getSupportMessage(),
            };
          }
        } else {
          // Platform not supported, use provided data or defaults
          actualScreenTime = screenTimeHours ?? 0.0;
          actualAppUsage = appUsage;
        }
      } catch (e) {
        // Fallback to provided data or defaults
        actualScreenTime = screenTimeHours ?? 0.0;
        actualAppUsage = appUsage;
      }
    } else {
      actualScreenTime = screenTimeHours;
      actualAppUsage = appUsage;
    }
    
    final analysis = {
      'screenTimeHours': actualScreenTime,
      'screenTimeLevel': _categorizeScreenTime(actualScreenTime),
      'recommendation': _getScreenTimeRecommendation(actualScreenTime),
      'balanceNeeded': actualScreenTime > _moderateScreenTimeThreshold,
      'suggestedBreakDuration': _calculateBreakDuration(actualScreenTime),
      'appUsageAnalysis': actualAppUsage != null ? _analyzeAppUsage(actualAppUsage) : null,
      'timestamp': DateTime.now().toIso8601String(),
      'dataSource': screenTimeHours == null ? 'automatic' : 'manual',
    };
    
    // Store analysis for pattern learning
    await _updateBehaviorPattern('screen_time_analysis', analysis);
    
    return analysis;
  }

  // TASK 3: Generating Personalized Habit Suggestions
  Future<Map<String, dynamic>> generatePersonalizedHabitSuggestion({
    required UserMood mood,
    required List<HabitCategory> preferences,
    double? screenTimeHours,
    int? currentStreak,
    Map<String, int>? recentCompletions,
  }) async {
    // Analyze all input data
    final moodAnalysis = await analyzeMoodAndPreferences(mood, preferences);
    final screenAnalysis = screenTimeHours != null 
        ? await analyzeScreenTimeAndUsage(screenTimeHours, null)
        : null;
    
    // Get user behavior patterns
    final behaviorPattern = await _getUserBehaviorPattern();
    
    // Generate suggestion based on comprehensive analysis
    final suggestion = await _generateOptimizedSuggestion(
      mood: mood,
      preferences: preferences,
      screenTimeHours: screenTimeHours,
      currentStreak: currentStreak ?? 0,
      recentCompletions: recentCompletions ?? {},
      behaviorPattern: behaviorPattern,
    );
    
    return {
      'suggestion': suggestion,
      'moodAnalysis': moodAnalysis,
      'screenAnalysis': screenAnalysis,
      'reasoning': _generateSuggestionReasoning(mood, preferences, screenTimeHours, currentStreak),
      'difficulty': _calculateHabitDifficulty(currentStreak ?? 0, recentCompletions ?? {}),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // TASK 4: Habit Completion and Streak Tracking
  Future<Map<String, dynamic>> processHabitCompletion(String habitId, bool completed) async {
    final result = {
      'habitId': habitId,
      'completed': completed,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (completed) {
      // Mark habit as complete
      await _storageService.completeHabit(habitId);
      
      // Get updated habit data
      final habits = await _storageService.getHabits();
      final habit = habits.firstWhere((h) => h.id == habitId);
      
      result.addAll({
        'newStreak': habit.currentStreak,
        'totalCompletions': habit.completedDates.length,
        'celebrationMessage': _generateCelebrationMessage(habit.currentStreak),
        'nextSuggestion': await _generateNextDaySuggestion(habit),
      });
      
      // Update behavior pattern with successful completion
      await _updateBehaviorPattern('completion_success', {
        'habitCategory': habit.category.name,
        'streak': habit.currentStreak,
        'dayOfWeek': DateTime.now().weekday,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      // Handle missed habit
      result.addAll({
        'encouragementMessage': _generateEncouragementMessage(),
        'easierSuggestion': await _generateEasierHabitSuggestion(),
        'streakReset': true,
      });
      
      // Update behavior pattern with missed habit
      await _updateBehaviorPattern('completion_missed', {
        'habitId': habitId,
        'dayOfWeek': DateTime.now().weekday,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    return result;
  }

  // TASK 5: Optimizing Habit Suggestions
  Future<Map<String, dynamic>> optimizeHabitSuggestions() async {
    final behaviorPattern = await _getUserBehaviorPattern();
    final habits = await _storageService.getHabits();
    final profile = await _storageService.getUserProfile();
    
    if (profile == null) {
      return {'error': 'User profile not found'};
    }
    
    final analysis = {
      'userPerformance': _analyzeUserPerformance(habits),
      'preferredCategories': _identifyPreferredCategories(habits),
      'optimalTiming': _identifyOptimalTiming(behaviorPattern),
      'difficultyAdjustment': _calculateDifficultyAdjustment(habits),
      'recommendations': await _generateOptimizationRecommendations(habits, behaviorPattern),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    return analysis;
  }

  // Generate habit suggestions based on mood and preferences (Legacy method)
  Map<String, String> generateHabitSuggestion(UserMood mood, List<HabitCategory> preferences) {
    final suggestions = _getHabitSuggestions(mood, preferences);
    final random = Random();
    final suggestion = suggestions[random.nextInt(suggestions.length)];
    
    return {
      'title': suggestion['title']!,
      'description': suggestion['description']!,
      'prompt': _generateSuggestionPrompt(mood, suggestion),
    };
  }

  // Generate motivational prompts for habit suggestions
  String _generateSuggestionPrompt(UserMood mood, Map<String, String> suggestion) {
    switch (mood) {
      case UserMood.stressed:
        return "You're feeling stressed. I recommend ${suggestion['title']!.toLowerCase()} to help you relax. Would you like to proceed?";
      case UserMood.energized:
        return "You're feeling energized! How about ${suggestion['title']!.toLowerCase()}? It'll give you a great boost!";
      case UserMood.tired:
        return "I can see you're feeling tired. Let's try ${suggestion['title']!.toLowerCase()} to gently re-energize yourself.";
      case UserMood.happy:
        return "You're in a great mood! Perfect time for ${suggestion['title']!.toLowerCase()}. Let's keep that positive energy flowing!";
    }
  }

  // Completion celebration messages
  List<String> getCompletionMessages(int streak) {
    if (streak == 1) {
      return [
        "You've completed your habit for today! Well done! Your current streak is 1 day. Would you like to continue tomorrow?",
        "Fantastic start! You've completed your first habit. Let's build on this momentum!",
        "Great job! You've taken the first step. Your journey to better habits begins now!",
      ];
    } else if (streak <= 3) {
      return [
        "Amazing! You've kept up your $streak-day streak! Keep it up, you're doing great!",
        "Wonderful progress! $streak days in a row. You're building something special!",
        "Excellent work! Your $streak-day streak shows real commitment!",
      ];
    } else if (streak <= 7) {
      return [
        "Incredible! You've maintained a $streak-day streak! You're on fire!",
        "Outstanding! $streak days of consistency. You're becoming unstoppable!",
        "Phenomenal! Your $streak-day streak is truly impressive!",
      ];
    } else {
      return [
        "Absolutely amazing! $streak days of pure dedication! You're a habit master!",
        "Legendary! Your $streak-day streak is inspiring. You've built something incredible!",
        "Extraordinary! $streak consecutive days! You're proof that small habits create big changes!",
      ];
    }
  }

  // Encouragement messages for missed habits
  List<String> get missedHabitMessages => [
    "It looks like you missed today's habit. No worries, let's get back on track tomorrow. You've still got this!",
    "Don't worry about missing today! Tomorrow is a fresh start. Your journey continues!",
    "Missing a day happens to everyone. What matters is getting back up. Ready for tomorrow?",
    "One missed day doesn't define your journey. Let's refocus and continue building those amazing habits!",
  ];

  // Reminder messages for notifications
  List<String> get reminderMessages => [
    "Hey there! Just a friendly reminder to complete your habit for today. Let's keep the momentum going!",
    "Time for your daily habit! Today's a great day to continue your streak!",
    "Your habit is waiting for you! A few minutes now will make your day even better!",
    "Gentle reminder: Your future self will thank you for completing today's habit!",
  ];

  // Progress check messages
  List<String> getProgressMessages(int totalCompleted, int longestStreak) {
    return [
      "You're doing great! You've completed $totalCompleted habits total with your longest streak being $longestStreak days!",
      "Amazing progress! $totalCompleted habits completed and a personal best of $longestStreak days in a row!",
      "Look at you go! $totalCompleted total completions and an impressive $longestStreak-day streak record!",
    ];
  }

  // Preference adjustment prompts
  List<String> get adjustPreferencesMessages => [
    "You're doing great! Do you want to tweak your preferences for tomorrow's habit?",
    "How are you feeling about your current habit focus? Want to try something different tomorrow?",
    "Ready to explore new habit categories? Let's adjust your preferences!",
  ];

  // Get random motivational message
  String getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

  // Private method to get habit suggestions based on mood and preferences
  List<Map<String, String>> _getHabitSuggestions(UserMood mood, List<HabitCategory> preferences) {
    final allSuggestions = <Map<String, String>>[];
    
    // Add suggestions based on mood
    switch (mood) {
      case UserMood.stressed:
        allSuggestions.addAll([
          {'title': '5-Minute Deep Breathing', 'description': 'Take slow, deep breaths to calm your mind', 'category': 'mindfulness', 'duration': '5'},
          {'title': 'Quick Meditation', 'description': 'A brief mindfulness session to center yourself', 'category': 'mindfulness', 'duration': '3'},
          {'title': 'Gentle Stretching', 'description': 'Light stretches to release tension', 'category': 'physical', 'duration': '5'},
          {'title': 'Gratitude Journaling', 'description': 'Write down three things you\'re grateful for', 'category': 'productivity', 'duration': '3'},
        ]);
        break;
      case UserMood.energized:
        allSuggestions.addAll([
          {'title': '10-Minute Walk', 'description': 'A brisk walk to channel your energy', 'category': 'physical', 'duration': '10'},
          {'title': 'Quick Workout', 'description': 'High-energy exercises to boost your mood', 'category': 'physical', 'duration': '15'},
          {'title': 'Creative Writing', 'description': 'Channel your energy into creative expression', 'category': 'productivity', 'duration': '10'},
          {'title': 'Learning Session', 'description': 'Read or learn something new', 'category': 'productivity', 'duration': '15'},
        ]);
        break;
      case UserMood.tired:
        allSuggestions.addAll([
          {'title': 'Power Nap Preparation', 'description': 'Gentle relaxation to prepare for rest', 'category': 'relaxation', 'duration': '5'},
          {'title': 'Hydration Break', 'description': 'Drink a glass of water mindfully', 'category': 'physical', 'duration': '2'},
          {'title': 'Gentle Yoga', 'description': 'Restorative poses to re-energize gently', 'category': 'physical', 'duration': '10'},
          {'title': 'Calming Music', 'description': 'Listen to soothing music for a few minutes', 'category': 'relaxation', 'duration': '5'},
        ]);
        break;
      case UserMood.happy:
        allSuggestions.addAll([
          {'title': 'Dance Break', 'description': 'Move to your favorite song', 'category': 'physical', 'duration': '5'},
          {'title': 'Gratitude Practice', 'description': 'Celebrate what makes you happy', 'category': 'mindfulness', 'duration': '5'},
          {'title': 'Social Connection', 'description': 'Send a positive message to someone', 'category': 'productivity', 'duration': '3'},
          {'title': 'Goal Visualization', 'description': 'Visualize achieving your dreams', 'category': 'mindfulness', 'duration': '5'},
        ]);
        break;
    }
    
    // Filter by preferences if any are set
    if (preferences.isNotEmpty) {
      final preferredSuggestions = allSuggestions.where((suggestion) {
        final category = suggestion['category']!;
        return preferences.any((pref) => pref.name.toLowerCase().contains(category));
      }).toList();
      
      if (preferredSuggestions.isNotEmpty) {
        return preferredSuggestions;
      }
    }
    
    return allSuggestions;
  }

  // Private helper methods for AI analysis
  
  String _getMoodAnalysis(UserMood mood) {
    switch (mood) {
      case UserMood.stressed:
        return "User is experiencing stress. Recommend calming, relaxation-focused activities to reduce cortisol levels and promote mental well-being.";
      case UserMood.energized:
        return "User has high energy levels. Ideal time for physical activities or challenging tasks that can channel this energy productively.";
      case UserMood.tired:
        return "User is experiencing fatigue. Suggest gentle, restorative activities that don't overwhelm and can help re-energize gradually.";
      case UserMood.happy:
        return "User is in a positive emotional state. Great opportunity for habit reinforcement and trying new, engaging activities.";
    }
  }

  List<HabitCategory> _getRecommendedCategories(UserMood mood, List<HabitCategory> preferences) {
    final moodBasedCategories = <HabitCategory>[];
    
    switch (mood) {
      case UserMood.stressed:
        moodBasedCategories.addAll([HabitCategory.mindfulness, HabitCategory.relaxation]);
        break;
      case UserMood.energized:
        moodBasedCategories.addAll([HabitCategory.physical, HabitCategory.productivity]);
        break;
      case UserMood.tired:
        moodBasedCategories.addAll([HabitCategory.relaxation, HabitCategory.mindfulness]);
        break;
      case UserMood.happy:
        moodBasedCategories.addAll([HabitCategory.physical, HabitCategory.productivity]);
        break;
    }
    
    // Combine with user preferences
    final combined = [...preferences, ...moodBasedCategories];
    return combined.toSet().toList();
  }

  String _analyzeEmotionalState(UserMood mood) {
    switch (mood) {
      case UserMood.stressed:
        return "High stress levels detected. Priority: stress reduction and emotional regulation.";
      case UserMood.energized:
        return "High energy and motivation detected. Optimal for challenging activities.";
      case UserMood.tired:
        return "Low energy levels detected. Focus on gentle, restorative activities.";
      case UserMood.happy:
        return "Positive emotional state detected. Excellent for habit building and reinforcement.";
    }
  }

  String _categorizeScreenTime(double hours) {
    if (hours >= _highScreenTimeThreshold) {
      return "high";
    } else if (hours >= _moderateScreenTimeThreshold) {
      return "moderate";
    } else {
      return "low";
    }
  }

  String _getScreenTimeRecommendation(double hours) {
    if (hours >= _highScreenTimeThreshold) {
      return "Screen time is excessive. Strongly recommend offline activities to reduce digital fatigue and eye strain.";
    } else if (hours >= _moderateScreenTimeThreshold) {
      return "Screen time is moderate. Consider balancing with some offline activities for better well-being.";
    } else {
      return "Screen time is low. Good balance maintained. Can include both digital and offline activities.";
    }
  }

  int _calculateBreakDuration(double screenTimeHours) {
    if (screenTimeHours >= _highScreenTimeThreshold) {
      return 15; // 15-minute break
    } else if (screenTimeHours >= _moderateScreenTimeThreshold) {
      return 10; // 10-minute break
    } else {
      return 5; // 5-minute break
    }
  }

  Map<String, dynamic> _analyzeAppUsage(Map<String, double> appUsage) {
    final sortedApps = appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topApp = sortedApps.first;
    final socialMediaApps = ['instagram', 'facebook', 'twitter', 'tiktok', 'snapchat'];
    final isSocialMediaHeavy = socialMediaApps.any((app) => 
        topApp.key.toLowerCase().contains(app) && topApp.value > 2.0);
    
    return {
      'topApp': topApp.key,
      'topAppUsage': topApp.value,
      'socialMediaHeavy': isSocialMediaHeavy,
      'recommendation': isSocialMediaHeavy 
          ? "High social media usage detected. Consider mindfulness or physical activities."
          : "Balanced app usage. Continue with current patterns."
    };
  }

  Future<Map<String, dynamic>> _generateOptimizedSuggestion({
    required UserMood mood,
    required List<HabitCategory> preferences,
    double? screenTimeHours,
    required int currentStreak,
    required Map<String, int> recentCompletions,
    required Map<String, dynamic> behaviorPattern,
  }) async {
    final suggestions = _getHabitSuggestions(mood, preferences);
    
    // Filter based on screen time if provided
    List<Map<String, String>> filteredSuggestions = suggestions;
    if (screenTimeHours != null && screenTimeHours >= _moderateScreenTimeThreshold) {
      filteredSuggestions = suggestions.where((s) => 
          s['category'] == 'physical' || s['category'] == 'mindfulness').toList();
    }
    
    // Adjust difficulty based on streak
    final difficulty = _calculateHabitDifficulty(currentStreak, recentCompletions);
    filteredSuggestions = _adjustSuggestionsByDifficulty(filteredSuggestions, difficulty);
    
    // Select best suggestion
    final random = Random();
    final suggestion = filteredSuggestions[random.nextInt(filteredSuggestions.length)];
    
    return {
      'title': suggestion['title']!,
      'description': suggestion['description']!,
      'category': suggestion['category']!,
      'duration': int.parse(suggestion['duration']!),
      'difficulty': difficulty.name,
      'reasoning': _generateDetailedReasoning(mood, screenTimeHours, currentStreak),
    };
  }

  HabitDifficulty _calculateHabitDifficulty(int currentStreak, Map<String, int> recentCompletions) {
    final totalRecentCompletions = recentCompletions.values.fold(0, (sum, count) => sum + count);
    
    if (currentStreak >= 7 && totalRecentCompletions >= 5) {
      return HabitDifficulty.challenging;
    } else if (currentStreak >= 3 && totalRecentCompletions >= 3) {
      return HabitDifficulty.moderate;
    } else {
      return HabitDifficulty.easy;
    }
  }

  List<Map<String, String>> _adjustSuggestionsByDifficulty(List<Map<String, String>> suggestions, HabitDifficulty difficulty) {
    switch (difficulty) {
      case HabitDifficulty.easy:
        return suggestions.where((s) => int.parse(s['duration']!) <= 5).toList();
      case HabitDifficulty.moderate:
        return suggestions.where((s) => int.parse(s['duration']!) <= 10).toList();
      case HabitDifficulty.challenging:
        return suggestions; // All suggestions available
    }
    return suggestions; // Default fallback
  }

  String _generateSuggestionReasoning(UserMood mood, List<HabitCategory> preferences, double? screenTimeHours, int? currentStreak) {
    final reasons = <String>[];
    
    reasons.add("Based on your ${mood.displayName.toLowerCase()} mood");
    
    if (preferences.isNotEmpty) {
      reasons.add("aligned with your preference for ${preferences.first.displayName.toLowerCase()}");
    }
    
    if (screenTimeHours != null && screenTimeHours >= _moderateScreenTimeThreshold) {
      reasons.add("considering your ${screenTimeHours.toStringAsFixed(1)} hours of screen time today");
    }
    
    if (currentStreak != null && currentStreak > 0) {
      reasons.add("building on your $currentStreak-day streak");
    }
    
    return "${reasons.join(", ")}.";
  }

  String _generateDetailedReasoning(UserMood mood, double? screenTimeHours, int currentStreak) {
    final buffer = StringBuffer();
    
    buffer.write("This suggestion is tailored for your current ${mood.displayName.toLowerCase()} state. ");
    
    if (screenTimeHours != null && screenTimeHours >= _moderateScreenTimeThreshold) {
      buffer.write("Given your ${screenTimeHours.toStringAsFixed(1)} hours of screen time, ");
      buffer.write("this offline activity will help balance your digital consumption. ");
    }
    
    if (currentStreak > 0) {
      buffer.write("Your $currentStreak-day streak shows great commitment, ");
      buffer.write("and this habit will help maintain your momentum.");
    } else {
      buffer.write("This is a great starting point to build a new habit streak.");
    }
    
    return buffer.toString();
  }

  String _generateCelebrationMessage(int streak) {
    if (streak == 1) {
      return "🎉 Fantastic start! You've completed your first habit. Every journey begins with a single step!";
    } else if (streak <= 3) {
      return "🔥 Amazing! $streak days in a row! You're building real momentum here!";
    } else if (streak <= 7) {
      return "⭐ Incredible! $streak-day streak! You're developing a powerful habit pattern!";
    } else if (streak <= 14) {
      return "🏆 Outstanding! $streak consecutive days! You're becoming a habit master!";
    } else {
      return "👑 Legendary! $streak days of pure dedication! You're an inspiration!";
    }
  }

  String _generateEncouragementMessage() {
    final messages = [
      "No worries! Every habit journey has ups and downs. Tomorrow is a fresh start! 💪",
      "Missing one day doesn't define your journey. Let's get back on track tomorrow! 🌟",
      "It's okay! What matters is getting back up. You've got this! 🚀",
      "Don't be hard on yourself. Consistency is built over time, not perfection! ❤️",
    ];
    return getRandomMessage(messages);
  }

  Future<Map<String, String>> _generateNextDaySuggestion(Habit completedHabit) async {
    // Generate a suggestion for tomorrow based on today's completed habit
    final category = completedHabit.category;
    final suggestions = _getHabitSuggestions(UserMood.happy, [category]);
    final random = Random();
    final suggestion = suggestions[random.nextInt(suggestions.length)];
    
    return {
      'title': suggestion['title']!,
      'description': suggestion['description']!,
      'message': "Ready for tomorrow? Here's a great follow-up habit!",
    };
  }

  Future<Map<String, String>> _generateEasierHabitSuggestion() async {
    final easySuggestions = [
      {'title': '2-Minute Breathing', 'description': 'Just two minutes of deep breathing'},
      {'title': 'Drink Water', 'description': 'Mindfully drink a glass of water'},
      {'title': 'Gentle Stretch', 'description': 'One simple stretch for 30 seconds'},
      {'title': 'Gratitude Moment', 'description': 'Think of one thing you\'re grateful for'},
    ];
    
    final random = Random();
    final suggestion = easySuggestions[random.nextInt(easySuggestions.length)];
    
    return {
      'title': suggestion['title']!,
      'description': suggestion['description']!,
      'message': "Let's start small tomorrow. Here's an easy habit to get back on track!",
    };
  }

  Map<String, dynamic> _analyzeUserPerformance(List<Habit> habits) {
    if (habits.isEmpty) {
      return {'status': 'no_data', 'message': 'No habits to analyze yet'};
    }
    
    final totalCompletions = habits.fold(0, (sum, habit) => sum + habit.completedDates.length);
    final averageStreak = habits.fold(0, (sum, habit) => sum + habit.currentStreak) / habits.length;
    final completionRate = habits.where((h) => h.isCompletedToday).length / habits.length;
    
    String performance;
    if (completionRate >= 0.8) {
      performance = 'excellent';
    } else if (completionRate >= 0.6) {
      performance = 'good';
    } else if (completionRate >= 0.4) {
      performance = 'fair';
    } else {
      performance = 'needs_improvement';
    }
    
    return {
      'totalCompletions': totalCompletions,
      'averageStreak': averageStreak.round(),
      'completionRate': (completionRate * 100).round(),
      'performance': performance,
      'totalHabits': habits.length,
    };
  }

  Map<String, int> _identifyPreferredCategories(List<Habit> habits) {
    final categoryCompletions = <String, int>{};
    
    for (final habit in habits) {
      final category = habit.category.name;
      categoryCompletions[category] = (categoryCompletions[category] ?? 0) + habit.completedDates.length;
    }
    
    return categoryCompletions;
  }

  Map<String, dynamic> _identifyOptimalTiming(Map<String, dynamic> behaviorPattern) {
    // Analyze completion patterns (this would be populated from stored behavior data)
    // For now, return default recommendations
    return {
      'bestDayOfWeek': 'Monday', // Most successful day
      'bestTimeOfDay': 'Morning', // Most successful time
      'consistency': 'moderate',
      'recommendation': 'Try scheduling habits in the morning for better consistency',
    };
  }

  String _calculateDifficultyAdjustment(List<Habit> habits) {
    final recentPerformance = habits.where((h) => h.currentStreak > 0).length / habits.length;
    
    if (recentPerformance >= 0.8) {
      return 'increase'; // User is doing well, can handle more challenging habits
    } else if (recentPerformance <= 0.3) {
      return 'decrease'; // User is struggling, need easier habits
    } else {
      return 'maintain'; // Current difficulty is appropriate
    }
  }

  Future<List<String>> _generateOptimizationRecommendations(List<Habit> habits, Map<String, dynamic> behaviorPattern) async {
    final recommendations = <String>[];
    
    final performance = _analyzeUserPerformance(habits);
    final difficultyAdjustment = _calculateDifficultyAdjustment(habits);
    
    if (performance['performance'] == 'excellent') {
      recommendations.add("🌟 You're doing amazing! Consider adding a new habit category to expand your routine.");
    } else if (performance['performance'] == 'needs_improvement') {
      recommendations.add("💪 Let's focus on easier, shorter habits to rebuild momentum.");
    }
    
    if (difficultyAdjustment == 'increase') {
      recommendations.add("🚀 Ready for a challenge? Try longer duration habits or new categories.");
    } else if (difficultyAdjustment == 'decrease') {
      recommendations.add("🌱 Let's simplify. Shorter, easier habits will help you get back on track.");
    }
    
    // Add category-specific recommendations
    final preferredCategories = _identifyPreferredCategories(habits);
    if (preferredCategories.isNotEmpty) {
      final topCategory = preferredCategories.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      recommendations.add("✨ You excel at $topCategory habits! Consider exploring related activities.");
    }
    
    return recommendations;
  }

  Future<void> _updateBehaviorPattern(String key, Map<String, dynamic> data) async {
    if (!_userBehaviorPattern.containsKey(key)) {
      _userBehaviorPattern[key] = [];
    }
    
    (_userBehaviorPattern[key] as List).add(data);
    
    // Keep only last 30 entries to prevent excessive memory usage
    if ((_userBehaviorPattern[key] as List).length > 30) {
      (_userBehaviorPattern[key] as List).removeAt(0);
    }
    
    // In a real app, this would be persisted to storage
    // await _storageService.saveBehaviorPattern(_userBehaviorPattern);
  }

  Future<Map<String, dynamic>> _getUserBehaviorPattern() async {
    // In a real app, this would load from storage
    // return await _storageService.getBehaviorPattern() ?? {};
    return _userBehaviorPattern;
  }
  
  // Screen Time Management Methods
  
  /// Check if screen time tracking is supported on this device
  bool isScreenTimeSupported() {
    return _screenTimeService.isSupported();
  }
  
  /// Check if the app has screen time permissions
  Future<bool> hasScreenTimePermissions() async {
    return await _screenTimeService.hasPermissions();
  }
  
  /// Request screen time permissions from the user
  Future<bool> requestScreenTimePermissions() async {
    return await _screenTimeService.requestPermissions();
  }
  
  /// Get a user-friendly message about screen time support
  String getScreenTimeSupportMessage() {
    return _screenTimeService.getSupportMessage();
  }
  
  /// Get comprehensive screen time analysis for today
  Future<Map<String, dynamic>> getTodayScreenTimeAnalysis() async {
    try {
      return await _screenTimeService.getScreenTimeAnalysis();
    } catch (e) {
      return {
        'totalHours': 0.0,
        'category': 'unknown',
        'topApps': [],
        'appCount': 0,
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
  
  /// Generate habit suggestions with automatic screen time integration
  Future<Map<String, dynamic>> generateSmartHabitSuggestion({
    required UserMood mood,
    required List<HabitCategory> preferences,
    int? currentStreak,
    Map<String, int>? recentCompletions,
  }) async {
    // First, try to get screen time data automatically
    final screenTimeAnalysis = await analyzeScreenTimeAndUsage();
    
    // Extract screen time hours from analysis
    final screenTimeHours = screenTimeAnalysis['screenTimeHours'] as double?;
    
    // Generate personalized suggestion with screen time data
    return await generatePersonalizedHabitSuggestion(
      mood: mood,
      preferences: preferences,
      screenTimeHours: screenTimeHours,
      currentStreak: currentStreak,
      recentCompletions: recentCompletions,
    );
  }
  
  /// Get screen time insights and recommendations
  Future<Map<String, dynamic>> getScreenTimeInsights() async {
    final analysis = await getTodayScreenTimeAnalysis();
    final screenTimeHours = analysis['totalHours'] as double;
    
    final insights = {
      'analysis': analysis,
      'recommendations': [],
      'habitSuggestions': [],
    };
    
    // Generate recommendations based on screen time
    final recommendations = <String>[];
    final habitSuggestions = <String>[];
    
    if (screenTimeHours >= _highScreenTimeThreshold) {
      recommendations.add('📱 Your screen time is quite high today. Consider taking regular breaks.');
      recommendations.add('🚶‍♂️ Try the 20-20-20 rule: Every 20 minutes, look at something 20 feet away for 20 seconds.');
      habitSuggestions.add('Take a 10-minute walk without your phone');
      habitSuggestions.add('Practice 5 minutes of deep breathing');
      habitSuggestions.add('Do some stretching exercises');
    } else if (screenTimeHours >= _moderateScreenTimeThreshold) {
      recommendations.add('⚖️ Your screen time is moderate. Great balance!');
      recommendations.add('🎯 Consider adding some offline activities to your routine.');
      habitSuggestions.add('Read a few pages of a book');
      habitSuggestions.add('Practice mindful breathing for 3 minutes');
      habitSuggestions.add('Do a quick tidy-up of your space');
    } else {
      recommendations.add('✨ Excellent screen time balance today!');
      recommendations.add('🌟 You\'re doing great at managing your digital consumption.');
      habitSuggestions.add('Continue your balanced approach');
      habitSuggestions.add('Maybe try a new creative hobby');
    }
    
    insights['recommendations'] = recommendations;
    insights['habitSuggestions'] = habitSuggestions;
    
    return insights;
  }
}