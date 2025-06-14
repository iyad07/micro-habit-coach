import 'dart:math';
import '../models/habit.dart';
import '../models/user_profile.dart';

class AIAgentService {
  static final AIAgentService _instance = AIAgentService._internal();
  factory AIAgentService() => _instance;
  AIAgentService._internal();

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

  // Generate habit suggestions based on mood and preferences
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
}