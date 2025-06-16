import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import 'storage_service.dart';
import 'app_usage_service.dart';

// Habit difficulty levels
enum HabitDifficulty { easy, moderate, challenging }

class AIAgentService {
  static final AIAgentService _instance = AIAgentService._internal();
  factory AIAgentService() => _instance;
  AIAgentService._internal();

  final StorageService _storageService = StorageService();
  final AppUsageService _appUsageService = AppUsageService.create();
  
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
        if (_appUsageService.isSupported()) {
          if (await _appUsageService.hasPermissions()) {
            actualScreenTime = screenTimeHours ?? await _appUsageService.getTodayScreenTime();
            actualAppUsage = appUsage ?? await _appUsageService.getTodayAppUsage();
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
              'supportMessage': _appUsageService.getSupportMessage(),
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

  // MOOD ANALYSIS USING SENTIMENT ANALYSIS
  
  // Novita AI API configuration
  static String get _novitaApiUrl => dotenv.env['NOVITA_API_URL'] ?? 'https://api.novita.ai/v3/openai/chat/completions';
  static String get _novitaApiKey => dotenv.env['NOVITA_API_KEY'] ?? 'YOUR_API_KEY_HERE';
  static String get _novitaModel => dotenv.env['NOVITA_MODEL'] ?? 'meta-llama/llama-3.1-8b-instruct'; // Recommended model for sentiment analysis
  
  // Emotion keywords for enhanced mood detection
  static const Map<String, List<String>> _emotionKeywords = {
    'happy': ['happy', 'joy', 'excited', 'cheerful', 'delighted', 'pleased', 'content', 'glad', 'elated', 'euphoric', 'fantastic', 'amazing', 'wonderful', 'great', 'awesome', 'brilliant', 'excellent', 'marvelous', 'terrific', 'superb', 'good', 'positive', 'upbeat', '😊', '😄', '😃', '🙂', '😁', '🥳', '🎉'],
    'stressed': ['stressed', 'anxious', 'worried', 'overwhelmed', 'pressure', 'tense', 'nervous', 'frantic', 'panic', 'burden', '😰', '😟', '😧', '😨', '😱', '💔', '😵'],
    'tired': ['tired', 'exhausted', 'fatigue', 'sleepy', 'drained', 'weary', 'worn out', 'lethargic', 'sluggish', 'depleted', '😴', '😪', '🥱', '😑', '😶', '💤'],
    'energized': ['energized', 'motivated', 'pumped', 'active', 'vibrant', 'dynamic', 'enthusiastic', 'invigorated', 'refreshed', 'charged', '⚡', '🔥', '💪', '🚀', '✨', '🌟']
  };

  /// Analyze user mood from text input using sentiment analysis
  /// 
  /// This method processes user text input to determine their emotional state
  /// and categorizes it into one of four mood categories: Happy, Stressed, Tired, Energized
  Future<Map<String, dynamic>> analyzeMoodFromText(String userInput) async {
    try {
      // Step 1: Extract emotion-related keywords and emojis
      final keywordAnalysis = _extractEmotionKeywords(userInput);
      
      // Step 2: Use Novita AI sentiment analysis (fallback to rule-based if API fails)
      Map<String, dynamic> sentimentResult;
      try {
        sentimentResult = await _callNovitaSentimentAnalysis(userInput);
      } catch (e) {
        // Fallback to rule-based analysis if API fails
        sentimentResult = _performRuleBasedSentimentAnalysis(userInput, keywordAnalysis);
      }
      
      // Step 3: Classify mood into target categories
      final moodClassification = _classifyMoodFromSentiment(sentimentResult, keywordAnalysis);
      
      // Step 4: Generate confidence score
      final confidenceScore = _calculateConfidenceScore(keywordAnalysis, sentimentResult);
      
      final result = {
        'originalText': userInput,
        'detectedMood': moodClassification['mood'],
        'confidence': confidenceScore,
        'keywordAnalysis': keywordAnalysis,
        'sentimentAnalysis': sentimentResult,
        'reasoning': moodClassification['reasoning'],
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Store analysis for pattern learning
      await _updateBehaviorPattern('mood_text_analysis', result);
      
      return result;
    } catch (e) {
      return {
        'error': 'Failed to analyze mood: ${e.toString()}',
        'detectedMood': 'happy', // Default fallback
        'confidence': 0.0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Generate habit suggestion based on analyzed mood from text
  Future<Map<String, dynamic>> generateHabitFromMoodText(String userInput) async {
    // Analyze mood from text
    final moodAnalysis = await analyzeMoodFromText(userInput);
    
    if (moodAnalysis.containsKey('error')) {
      return moodAnalysis;
    }
    
    // Convert detected mood string to UserMood enum
    final detectedMoodString = moodAnalysis['detectedMood'] as String;
    UserMood detectedMood;
    
    switch (detectedMoodString.toLowerCase()) {
      case 'happy':
        detectedMood = UserMood.happy;
        break;
      case 'stressed':
        detectedMood = UserMood.stressed;
        break;
      case 'tired':
        detectedMood = UserMood.tired;
        break;
      case 'energized':
        detectedMood = UserMood.energized;
        break;
      default:
        detectedMood = UserMood.happy; // Default fallback
    }
    
    // Get user preferences (default to all categories if none set)
    final profile = await _storageService.getUserProfile();
    final preferences = profile?.preferredCategories ?? [
      HabitCategory.mindfulness,
      HabitCategory.physical,
      HabitCategory.productivity
    ];
    
    // Generate personalized habit suggestion
    final habitSuggestion = await generatePersonalizedHabitSuggestion(
      mood: detectedMood,
      preferences: preferences,
    );
    
    return {
      'moodAnalysis': moodAnalysis,
      'habitSuggestion': habitSuggestion,
      'processingMessage': _generateProcessingMessage(detectedMood),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Extract emotion-related keywords and emojis from user input
  Map<String, dynamic> _extractEmotionKeywords(String text) {
    final lowercaseText = text.toLowerCase();
    final foundKeywords = <String, List<String>>{};
    int totalMatches = 0;
    
    for (final emotion in _emotionKeywords.keys) {
      final matches = <String>[];
      
      for (final keyword in _emotionKeywords[emotion]!) {
        if (lowercaseText.contains(keyword.toLowerCase())) {
          matches.add(keyword);
          totalMatches++;
        }
      }
      
      if (matches.isNotEmpty) {
        foundKeywords[emotion] = matches;
      }
    }
    
    return {
      'foundKeywords': foundKeywords,
      'totalMatches': totalMatches,
      'dominantEmotion': _getDominantEmotion(foundKeywords),
    };
  }

  /// Call Novita AI Sentiment Analysis using OpenAI-compatible LLM API
  Future<Map<String, dynamic>> _callNovitaSentimentAnalysis(String text) async {
    final headers = {
      'Authorization': 'Bearer $_novitaApiKey',
      'Content-Type': 'application/json',
    };
    
    // Create a detailed prompt for sentiment analysis
    final systemPrompt = '''
You are an expert sentiment analysis AI. Analyze the given text and classify the emotional state into one of these categories: happy, stressed, tired, or energized.

Provide your response in this exact JSON format:
{
  "sentiment": "positive|negative|neutral",
  "emotion": "happy|stressed|tired|energized",
  "confidence": 0.0-1.0,
  "reasoning": "brief explanation"
}

Guidelines:
- happy: joy, excitement, contentment, satisfaction
- stressed: anxiety, worry, overwhelm, pressure
- tired: exhaustion, fatigue, low energy, sleepiness
- energized: motivation, enthusiasm, high energy, vigor

Analyze the emotional tone, keywords, and context to make your classification.''';
    
    final body = json.encode({
      'model': _novitaModel,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        {
          'role': 'user',
          'content': 'Analyze this text: "$text"',
        }
      ],
      'max_tokens': 200,
      'temperature': 0.3, // Lower temperature for more consistent results
    });
    
    try {
      final response = await http.post(
        Uri.parse(_novitaApiUrl),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final content = result['choices']?[0]?['message']?['content'] ?? '';
        
        // Parse the JSON response from the LLM
        try {
          final analysisResult = json.decode(content) as Map<String, dynamic>;
          return {
            'sentiment': analysisResult['sentiment'] ?? 'neutral',
            'confidence': (analysisResult['confidence'] ?? 0.5).toDouble(),
            'emotions': {
              analysisResult['emotion'] ?? 'neutral': analysisResult['confidence'] ?? 0.5
            },
            'dominantEmotion': analysisResult['emotion'] ?? 'neutral',
            'reasoning': analysisResult['reasoning'] ?? 'AI analysis',
            'source': 'novita_ai',
          };
        } catch (parseError) {
          // Fallback if JSON parsing fails - extract emotion from text
          final emotion = _extractEmotionFromText(content);
          return {
            'sentiment': _mapEmotionToSentiment(emotion),
            'confidence': 0.6,
            'emotions': {emotion: 0.6},
            'dominantEmotion': emotion,
            'reasoning': 'Extracted from AI response',
            'source': 'novita_ai_fallback',
          };
        }
      } else {
        throw Exception('API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Novita AI API error: ${e.toString()}');
    }
  }

  /// Fallback rule-based sentiment analysis
  Map<String, dynamic> _performRuleBasedSentimentAnalysis(String text, Map<String, dynamic> keywordAnalysis) {
    final foundKeywords = keywordAnalysis['foundKeywords'] as Map<String, List<String>>;
    
    if (foundKeywords.isEmpty) {
      return {
        'sentiment': 'neutral',
        'confidence': 0.3,
        'emotions': {},
        'source': 'rule_based_fallback',
      };
    }
    
    // Calculate emotion scores based on keyword frequency
    final emotionScores = <String, double>{};
    
    for (final emotion in foundKeywords.keys) {
      emotionScores[emotion] = foundKeywords[emotion]!.length.toDouble();
    }
    
    // Find dominant emotion
    final dominantEmotion = emotionScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Map to sentiment
    String sentiment;
    switch (dominantEmotion) {
      case 'happy':
      case 'energized':
        sentiment = 'positive';
        break;
      case 'stressed':
        sentiment = 'negative';
        break;
      case 'tired':
        sentiment = 'neutral';
        break;
      default:
        sentiment = 'neutral';
    }
    
    return {
      'sentiment': sentiment,
      'confidence': 0.7,
      'emotions': emotionScores,
      'dominantEmotion': dominantEmotion,
      'source': 'rule_based',
    };
  }

  /// Classify mood from sentiment analysis results
  Map<String, dynamic> _classifyMoodFromSentiment(Map<String, dynamic> sentimentResult, Map<String, dynamic> keywordAnalysis) {
    final dominantEmotion = keywordAnalysis['dominantEmotion'] as String?;
    final sentiment = sentimentResult['sentiment'] as String;
    
    String mood;
    String reasoning;
    
    // Priority: keyword-based detection > sentiment-based detection
    if (dominantEmotion != null && dominantEmotion.isNotEmpty) {
      mood = dominantEmotion;
      reasoning = 'Classified based on emotion keywords: ${keywordAnalysis['foundKeywords'][dominantEmotion]}';
    } else {
      // Fallback to sentiment-based classification
      switch (sentiment.toLowerCase()) {
        case 'positive':
          mood = 'happy';
          reasoning = 'Classified as happy based on positive sentiment';
          break;
        case 'negative':
          mood = 'stressed';
          reasoning = 'Classified as stressed based on negative sentiment';
          break;
        case 'neutral':
        default:
          mood = 'tired';
          reasoning = 'Classified as tired based on neutral sentiment';
      }
    }
    
    return {
      'mood': mood,
      'reasoning': reasoning,
    };
  }

  /// Calculate confidence score for mood detection
  double _calculateConfidenceScore(Map<String, dynamic> keywordAnalysis, Map<String, dynamic> sentimentResult) {
    final totalMatches = keywordAnalysis['totalMatches'] as int;
    final sentimentConfidence = sentimentResult['confidence'] as double? ?? 0.5;
    
    // Base confidence on keyword matches and sentiment confidence
    double keywordConfidence = 0.0;
    if (totalMatches > 0) {
      keywordConfidence = (totalMatches / 5.0).clamp(0.0, 1.0); // Max confidence at 5+ matches
    }
    
    // Weighted average: 60% keywords, 40% sentiment
    return (keywordConfidence * 0.6 + sentimentConfidence * 0.4).clamp(0.0, 1.0);
  }

  /// Get dominant emotion from keyword analysis
  String _getDominantEmotion(Map<String, List<String>> foundKeywords) {
    if (foundKeywords.isEmpty) return '';
    
    return foundKeywords.entries
        .reduce((a, b) => a.value.length > b.value.length ? a : b)
        .key;
  }

  /// Generate processing message based on detected mood
  String _generateProcessingMessage(UserMood mood) {
    switch (mood) {
      case UserMood.stressed:
        return "I can sense you're feeling stressed. Let me suggest a relaxation habit like a 5-minute deep breathing exercise to help you unwind.";
      case UserMood.happy:
        return "I can feel your positive energy! Let's channel that happiness into a productive habit that keeps your spirits high.";
      case UserMood.tired:
        return "It sounds like you're feeling tired. I'll recommend a gentle, restorative habit to help re-energize you gradually.";
      case UserMood.energized:
        return "Your energy is contagious! Let's use that motivation for an active habit that makes the most of your current state.";
    }
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
    // Generate dynamic, personalized suggestions based on comprehensive analysis
    final suggestions = await _generateDynamicSuggestions(mood, preferences, screenTimeHours, currentStreak, recentCompletions, behaviorPattern);
    
    // Apply intelligent filtering and personalization
    final personalizedSuggestions = _applyPersonalizationFilters(suggestions, mood, preferences, screenTimeHours, currentStreak, recentCompletions, behaviorPattern);
    
    // Select the best suggestion using AI-driven selection
    final selectedSuggestion = _selectOptimalSuggestion(personalizedSuggestions, behaviorPattern, currentStreak);
    
    // Generate dynamic reasoning and customization
    final customizedSuggestion = _customizeSuggestionForUser(selectedSuggestion, mood, screenTimeHours, currentStreak, behaviorPattern);
    
    return customizedSuggestion;
  }
  
  /// Generate dynamic, personalized suggestions using AI algorithms
  Future<List<Map<String, dynamic>>> _generateDynamicSuggestions(
    UserMood mood,
    List<HabitCategory> preferences,
    double? screenTimeHours,
    int currentStreak,
    Map<String, int> recentCompletions,
    Map<String, dynamic> behaviorPattern,
  ) async {
    final suggestions = <Map<String, dynamic>>[];
    
    // Base suggestions from mood analysis
    final baseSuggestions = _getHabitSuggestions(mood, preferences);
    
    // Generate variations and personalized alternatives
    for (final base in baseSuggestions) {
      // Create multiple variations of each base suggestion
      suggestions.addAll(_generateSuggestionVariations(base, mood, currentStreak, behaviorPattern));
    }
    
    // Add contextual suggestions based on screen time
    if (screenTimeHours != null) {
      suggestions.addAll(_generateScreenTimeBasedSuggestions(screenTimeHours, mood));
    }
    
    // Add streak-based progressive suggestions
    suggestions.addAll(_generateStreakBasedSuggestions(currentStreak, mood, preferences));
    
    // Add time-of-day contextual suggestions
    suggestions.addAll(_generateTimeContextualSuggestions(mood, preferences));
    
    // Add behavioral pattern-based suggestions
    suggestions.addAll(_generateBehaviorBasedSuggestions(behaviorPattern, mood, preferences));
    
    return suggestions;
  }
  
  /// Generate multiple variations of a base suggestion
  List<Map<String, dynamic>> _generateSuggestionVariations(
    Map<String, String> baseSuggestion,
    UserMood mood,
    int currentStreak,
    Map<String, dynamic> behaviorPattern,
  ) {
    final variations = <Map<String, dynamic>>[];
    final baseTitle = baseSuggestion['title']!;
    final baseDescription = baseSuggestion['description']!;
    final category = baseSuggestion['category']!;
    final duration = int.parse(baseSuggestion['duration']!);
    
    // Create intensity variations
    variations.add({
      'title': 'Quick $baseTitle',
      'description': 'A shorter version: ${baseDescription.toLowerCase()}',
      'category': category,
      'duration': (duration * 0.5).round().clamp(1, 30),
      'intensity': 'light',
      'variation': 'quick',
    });
    
    variations.add({
      'title': 'Extended $baseTitle',
      'description': 'A longer session: ${baseDescription.toLowerCase()}',
      'category': category,
      'duration': (duration * 1.5).round().clamp(1, 30),
      'intensity': 'moderate',
      'variation': 'extended',
    });
    
    // Create mood-specific variations
    final moodVariation = _createMoodSpecificVariation(baseSuggestion, mood);
    if (moodVariation != null) {
      variations.add(moodVariation);
    }
    
    // Create streak-motivated variations
    if (currentStreak > 0) {
      variations.add({
        'title': 'Streak Builder: $baseTitle',
        'description': 'Continue your $currentStreak-day streak with ${baseDescription.toLowerCase()}',
        'category': category,
        'duration': duration,
        'intensity': 'moderate',
        'variation': 'streak_motivated',
        'motivationalBonus': true,
      });
    }
    
    return variations;
  }
  
  /// Create mood-specific variation of a suggestion
  Map<String, dynamic>? _createMoodSpecificVariation(Map<String, String> baseSuggestion, UserMood mood) {
    final title = baseSuggestion['title']!;
    final description = baseSuggestion['description']!;
    final category = baseSuggestion['category']!;
    final duration = int.parse(baseSuggestion['duration']!);
    
    switch (mood) {
      case UserMood.stressed:
        return {
          'title': 'Stress-Relief: $title',
          'description': 'Specially designed for stress relief: ${description.toLowerCase()}',
          'category': category,
          'duration': duration,
          'intensity': 'gentle',
          'variation': 'stress_focused',
          'moodBonus': 'stress_relief',
        };
      case UserMood.energized:
        return {
          'title': 'High-Energy: $title',
          'description': 'Channel your energy: ${description.toLowerCase()}',
          'category': category,
          'duration': (duration * 1.2).round(),
          'intensity': 'high',
          'variation': 'energy_focused',
          'moodBonus': 'energy_boost',
        };
      case UserMood.tired:
        return {
          'title': 'Gentle: $title',
          'description': 'A gentle approach: ${description.toLowerCase()}',
          'category': category,
          'duration': (duration * 0.8).round(),
          'intensity': 'very_light',
          'variation': 'gentle_focused',
          'moodBonus': 'energy_restoration',
        };
      case UserMood.happy:
        return {
          'title': 'Joyful: $title',
          'description': 'Celebrate your happiness: ${description.toLowerCase()}',
          'category': category,
          'duration': duration,
          'intensity': 'moderate',
          'variation': 'joy_focused',
          'moodBonus': 'happiness_amplifier',
        };
    }
  }
  
  /// Generate suggestions based on screen time analysis
  List<Map<String, dynamic>> _generateScreenTimeBasedSuggestions(double screenTimeHours, UserMood mood) {
    final suggestions = <Map<String, dynamic>>[];
    
    if (screenTimeHours >= _highScreenTimeThreshold) {
      suggestions.addAll([
        {
          'title': 'Digital Detox Walk',
          'description': 'Take a refreshing walk without any devices to reset your mind',
          'category': 'physical',
          'duration': 15,
          'intensity': 'moderate',
          'variation': 'screen_time_recovery',
          'screenTimeBonus': 'digital_detox',
        },
        {
          'title': 'Eye Rest & Stretch',
          'description': 'Give your eyes a break with gentle stretches and eye exercises',
          'category': 'physical',
          'duration': 5,
          'intensity': 'light',
          'variation': 'eye_care',
          'screenTimeBonus': 'eye_relief',
        },
        {
          'title': 'Mindful Breathing Away from Screens',
          'description': 'Practice deep breathing in a screen-free environment',
          'category': 'mindfulness',
          'duration': 8,
          'intensity': 'light',
          'variation': 'screen_free_mindfulness',
          'screenTimeBonus': 'mental_reset',
        },
      ]);
    } else if (screenTimeHours >= _moderateScreenTimeThreshold) {
      suggestions.addAll([
        {
          'title': 'Balance Break',
          'description': 'A quick offline activity to maintain digital balance',
          'category': 'physical',
          'duration': 10,
          'intensity': 'light',
          'variation': 'balance_focused',
          'screenTimeBonus': 'balance_maintenance',
        },
      ]);
    }
    
    return suggestions;
  }
  
  /// Generate suggestions based on current streak
  List<Map<String, dynamic>> _generateStreakBasedSuggestions(int currentStreak, UserMood mood, List<HabitCategory> preferences) {
    final suggestions = <Map<String, dynamic>>[];
    
    if (currentStreak == 0) {
      // Fresh start suggestions
      suggestions.addAll([
        {
          'title': 'Fresh Start: 2-Minute Habit',
          'description': 'Begin your journey with a simple 2-minute habit',
          'category': 'mindfulness',
          'duration': 2,
          'intensity': 'very_light',
          'variation': 'fresh_start',
          'streakBonus': 'new_beginning',
        },
        {
          'title': 'Foundation Builder',
          'description': 'Start building your habit foundation with this gentle activity',
          'category': 'productivity',
          'duration': 3,
          'intensity': 'light',
          'variation': 'foundation',
          'streakBonus': 'foundation_building',
        },
      ]);
    } else if (currentStreak >= 7) {
      // Advanced streak suggestions
      suggestions.addAll([
        {
          'title': 'Streak Master Challenge',
          'description': 'You\'re on fire! Take on this advanced challenge',
          'category': preferences.isNotEmpty ? preferences.first.name : 'physical',
          'duration': 20,
          'intensity': 'challenging',
          'variation': 'advanced_challenge',
          'streakBonus': 'mastery_level',
        },
        {
          'title': 'Habit Evolution',
          'description': 'Evolve your practice with this enhanced version',
          'category': preferences.isNotEmpty ? preferences.first.name : 'mindfulness',
          'duration': 15,
          'intensity': 'moderate',
          'variation': 'evolution',
          'streakBonus': 'skill_advancement',
        },
      ]);
    } else if (currentStreak >= 3) {
      // Momentum building suggestions
      suggestions.addAll([
        {
          'title': 'Momentum Builder',
          'description': 'Keep your momentum going with this engaging activity',
          'category': preferences.isNotEmpty ? preferences.first.name : 'physical',
          'duration': 10,
          'intensity': 'moderate',
          'variation': 'momentum',
          'streakBonus': 'momentum_building',
        },
      ]);
    }
    
    return suggestions;
  }
  
  /// Generate time-contextual suggestions
  List<Map<String, dynamic>> _generateTimeContextualSuggestions(UserMood mood, List<HabitCategory> preferences) {
    final suggestions = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 6 && hour < 10) {
      // Morning suggestions
      suggestions.addAll([
        {
          'title': 'Morning Energizer',
          'description': 'Start your day with this energizing activity',
          'category': 'physical',
          'duration': 8,
          'intensity': 'moderate',
          'variation': 'morning_boost',
          'timeBonus': 'morning_energy',
        },
        {
          'title': 'Dawn Mindfulness',
          'description': 'Begin your day with peaceful mindfulness',
          'category': 'mindfulness',
          'duration': 5,
          'intensity': 'light',
          'variation': 'morning_calm',
          'timeBonus': 'morning_clarity',
        },
      ]);
    } else if (hour >= 12 && hour < 14) {
      // Midday suggestions
      suggestions.addAll([
        {
          'title': 'Midday Reset',
          'description': 'Refresh yourself in the middle of your day',
          'category': 'mindfulness',
          'duration': 7,
          'intensity': 'light',
          'variation': 'midday_refresh',
          'timeBonus': 'afternoon_reset',
        },
      ]);
    } else if (hour >= 18 && hour < 22) {
      // Evening suggestions
      suggestions.addAll([
        {
          'title': 'Evening Wind-Down',
          'description': 'Transition peacefully into your evening',
          'category': 'mindfulness',
          'duration': 10,
          'intensity': 'light',
          'variation': 'evening_calm',
          'timeBonus': 'evening_peace',
        },
      ]);
    }
    
    return suggestions;
  }
  
  /// Generate suggestions based on behavioral patterns
  List<Map<String, dynamic>> _generateBehaviorBasedSuggestions(
    Map<String, dynamic> behaviorPattern,
    UserMood mood,
    List<HabitCategory> preferences,
  ) {
    final suggestions = <Map<String, dynamic>>[];
    
    // If no behavior pattern data, generate exploratory suggestions
    if (behaviorPattern.isEmpty) {
      suggestions.addAll([
        {
          'title': 'Discovery Session',
          'description': 'Explore what works best for you with this varied activity',
          'category': 'mindfulness',
          'duration': 5,
          'intensity': 'light',
          'variation': 'exploration',
          'behaviorBonus': 'pattern_discovery',
        },
        {
          'title': 'Preference Explorer',
          'description': 'Try something new to discover your preferences',
          'category': 'physical',
          'duration': 7,
          'intensity': 'light',
          'variation': 'preference_discovery',
          'behaviorBonus': 'preference_learning',
        },
      ]);
    }
    
    return suggestions;
  }
  
  /// Apply intelligent personalization filters to suggestions
  List<Map<String, dynamic>> _applyPersonalizationFilters(
    List<Map<String, dynamic>> suggestions,
    UserMood mood,
    List<HabitCategory> preferences,
    double? screenTimeHours,
    int currentStreak,
    Map<String, int> recentCompletions,
    Map<String, dynamic> behaviorPattern,
  ) {
    var filteredSuggestions = List<Map<String, dynamic>>.from(suggestions);
    
    // Filter by user preferences
    if (preferences.isNotEmpty) {
      filteredSuggestions = filteredSuggestions.where((suggestion) {
        final category = suggestion['category'] as String;
        return preferences.any((pref) => 
          pref.name.toLowerCase().contains(category.toLowerCase()) ||
          category.toLowerCase().contains(pref.name.toLowerCase())
        );
      }).toList();
    }
    
    // Filter by difficulty based on streak and recent performance
    final difficulty = _calculateHabitDifficulty(currentStreak, recentCompletions);
    filteredSuggestions = filteredSuggestions.where((suggestion) {
      final intensity = suggestion['intensity'] as String? ?? 'moderate';
      switch (difficulty) {
        case HabitDifficulty.easy:
          return ['very_light', 'light'].contains(intensity);
        case HabitDifficulty.moderate:
          return ['light', 'moderate'].contains(intensity);
        case HabitDifficulty.challenging:
          return true; // All intensities allowed
      }
    }).toList();
    
    // Filter by screen time context
    if (screenTimeHours != null && screenTimeHours >= _moderateScreenTimeThreshold) {
      // Prioritize offline activities
      filteredSuggestions = filteredSuggestions.where((suggestion) {
        final category = suggestion['category'] as String;
        return ['physical', 'mindfulness'].contains(category);
      }).toList();
    }
    
    // Ensure we have suggestions after filtering
    if (filteredSuggestions.isEmpty) {
      filteredSuggestions = suggestions.take(5).toList();
    }
    
    return filteredSuggestions;
  }
  
  /// Select optimal suggestion using AI-driven selection
  Map<String, dynamic> _selectOptimalSuggestion(
    List<Map<String, dynamic>> suggestions,
    Map<String, dynamic> behaviorPattern,
    int currentStreak,
  ) {
    if (suggestions.isEmpty) {
      // Fallback suggestion
      return {
        'title': 'Mindful Moment',
        'description': 'Take a moment to breathe and center yourself',
        'category': 'mindfulness',
        'duration': 3,
        'intensity': 'light',
        'variation': 'fallback',
      };
    }
    
    // Score each suggestion based on multiple factors
    final scoredSuggestions = suggestions.map((suggestion) {
      double score = 0.0;
      
      // Base score
      score += 1.0;
      
      // Bonus for variations that match user context
      final variation = suggestion['variation'] as String? ?? '';
      if (variation.contains('streak') && currentStreak > 0) score += 2.0;
      if (variation.contains('fresh_start') && currentStreak == 0) score += 2.0;
      if (variation.contains('morning') && DateTime.now().hour < 10) score += 1.5;
      if (variation.contains('evening') && DateTime.now().hour >= 18) score += 1.5;
      
      // Bonus for special features
      if (suggestion.containsKey('motivationalBonus')) score += 1.0;
      if (suggestion.containsKey('screenTimeBonus')) score += 1.0;
      if (suggestion.containsKey('timeBonus')) score += 0.5;
      
      // Randomization factor to ensure variety
      score += Random().nextDouble() * 0.5;
      
      return {'suggestion': suggestion, 'score': score};
    }).toList();
    
    // Sort by score and select the best one
    scoredSuggestions.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    return scoredSuggestions.first['suggestion'] as Map<String, dynamic>;
  }
  
  /// Customize suggestion for the specific user
  Map<String, dynamic> _customizeSuggestionForUser(
    Map<String, dynamic> suggestion,
    UserMood mood,
    double? screenTimeHours,
    int currentStreak,
    Map<String, dynamic> behaviorPattern,
  ) {
    final customized = Map<String, dynamic>.from(suggestion);
    
    // Generate personalized title variations
    final baseTitle = customized['title'] as String;
    final personalizedTitles = _generatePersonalizedTitles(baseTitle, mood, currentStreak);
    customized['title'] = personalizedTitles[Random().nextInt(personalizedTitles.length)];
    
    // Generate personalized descriptions
    final baseDescription = customized['description'] as String;
    customized['description'] = _generatePersonalizedDescription(baseDescription, mood, screenTimeHours, currentStreak);
    
    // Add dynamic reasoning
    customized['reasoning'] = _generateDynamicReasoning(customized, mood, screenTimeHours, currentStreak, behaviorPattern);
    
    // Add personalized encouragement
    customized['encouragement'] = _generatePersonalizedEncouragement(mood, currentStreak);
    
    // Add completion prediction
    customized['completionPrediction'] = _predictCompletionLikelihood(customized, behaviorPattern, currentStreak);
    
    return customized;
  }
  
  /// Generate personalized title variations
  List<String> _generatePersonalizedTitles(String baseTitle, UserMood mood, int currentStreak) {
    final titles = <String>[baseTitle];
    
    // Add mood-specific variations
    switch (mood) {
      case UserMood.stressed:
        titles.addAll([
          'Calming $baseTitle',
          'Stress-Relief: $baseTitle',
          'Peaceful $baseTitle',
        ]);
        break;
      case UserMood.energized:
        titles.addAll([
          'Energizing $baseTitle',
          'Power-Up: $baseTitle',
          'Dynamic $baseTitle',
        ]);
        break;
      case UserMood.tired:
        titles.addAll([
          'Gentle $baseTitle',
          'Restorative $baseTitle',
          'Easy $baseTitle',
        ]);
        break;
      case UserMood.happy:
        titles.addAll([
          'Joyful $baseTitle',
          'Uplifting $baseTitle',
          'Celebratory $baseTitle',
        ]);
        break;
    }
    
    // Add streak-specific variations
    if (currentStreak > 0) {
      titles.addAll([
        'Day ${currentStreak + 1}: $baseTitle',
        'Streak Builder: $baseTitle',
      ]);
    }
    
    return titles;
  }
  
  /// Generate personalized description
  String _generatePersonalizedDescription(String baseDescription, UserMood mood, double? screenTimeHours, int currentStreak) {
    final buffer = StringBuffer(baseDescription);
    
    // Add mood-specific context
    switch (mood) {
      case UserMood.stressed:
        buffer.write(' This will help you find calm and reduce stress.');
        break;
      case UserMood.energized:
        buffer.write(' Perfect for channeling your current energy positively.');
        break;
      case UserMood.tired:
        buffer.write(' A gentle way to restore your energy without overwhelming yourself.');
        break;
      case UserMood.happy:
        buffer.write(' Let\'s build on your positive mood and create momentum.');
        break;
    }
    
    // Add screen time context
    if (screenTimeHours != null && screenTimeHours >= _moderateScreenTimeThreshold) {
      buffer.write(' This offline activity will give your eyes and mind a healthy break from screens.');
    }
    
    // Add streak context
    if (currentStreak > 0) {
      buffer.write(' Continue building on your impressive $currentStreak-day streak!');
    } else {
      buffer.write(' A perfect way to start building a new healthy habit!');
    }
    
    return buffer.toString();
  }
  
  /// Generate dynamic reasoning for the suggestion
  String _generateDynamicReasoning(
    Map<String, dynamic> suggestion,
    UserMood mood,
    double? screenTimeHours,
    int currentStreak,
    Map<String, dynamic> behaviorPattern,
  ) {
    final reasons = <String>[];
    
    // Mood-based reasoning
    reasons.add('Selected based on your current ${mood.displayName.toLowerCase()} mood');
    
    // Screen time reasoning
    if (screenTimeHours != null) {
      if (screenTimeHours >= _highScreenTimeThreshold) {
        reasons.add('designed to counterbalance your high screen time (${screenTimeHours.toStringAsFixed(1)}h)');
      } else if (screenTimeHours >= _moderateScreenTimeThreshold) {
        reasons.add('complementing your moderate screen time usage');
      }
    }
    
    // Streak reasoning
    if (currentStreak > 0) {
      reasons.add('building on your successful $currentStreak-day streak');
    } else {
      reasons.add('designed as an ideal starting point for habit building');
    }
    
    // Variation-specific reasoning
    final variation = suggestion['variation'] as String? ?? '';
    if (variation.contains('morning')) {
      reasons.add('optimized for morning energy and focus');
    } else if (variation.contains('evening')) {
      reasons.add('perfect for evening wind-down');
    }
    
    // Learning phase reasoning
    if (behaviorPattern['learning_phase'] == true) {
      reasons.add('part of your personalized learning journey to discover what works best for you');
    }
    
    return 'This suggestion was ${reasons.join(", ")}.';
  }
  
  /// Generate personalized encouragement
  String _generatePersonalizedEncouragement(UserMood mood, int currentStreak) {
    final encouragements = <String>[];
    
    // Mood-specific encouragement
    switch (mood) {
      case UserMood.stressed:
        encouragements.addAll([
          'Take a deep breath - you\'ve got this! 🌸',
          'This moment of self-care will help you feel more centered 🧘‍♀️',
          'You deserve this peaceful break 💙',
        ]);
        break;
      case UserMood.energized:
        encouragements.addAll([
          'Your energy is amazing - let\'s use it wisely! ⚡',
          'Channel that positive energy into something great! 🚀',
          'You\'re radiating good vibes - keep it flowing! ✨',
        ]);
        break;
      case UserMood.tired:
        encouragements.addAll([
          'Be gentle with yourself - small steps count 🌱',
          'This gentle activity will help restore your energy 🌙',
          'You\'re doing great by taking care of yourself 💚',
        ]);
        break;
      case UserMood.happy:
        encouragements.addAll([
          'Your positive energy is contagious! Keep shining! 🌟',
          'What a great mood to build a healthy habit! 😊',
          'Let\'s celebrate this moment with a meaningful activity! 🎉',
        ]);
        break;
    }
    
    // Streak-specific encouragement
    if (currentStreak >= 7) {
      encouragements.addAll([
        'You\'re a habit champion with $currentStreak days! 🏆',
        'Your consistency is truly inspiring! 💪',
      ]);
    } else if (currentStreak >= 3) {
      encouragements.addAll([
        'You\'re building great momentum with $currentStreak days! 📈',
        'Your dedication is paying off! 🎯',
      ]);
    } else if (currentStreak > 0) {
      encouragements.addAll([
        'Every day counts - you\'re doing amazing! 🌈',
        'Building habits one day at a time! 🧱',
      ]);
    } else {
      encouragements.addAll([
        'Every journey begins with a single step! 👣',
        'Today is the perfect day to start something great! 🌅',
      ]);
    }
    
    return encouragements[Random().nextInt(encouragements.length)];
  }
  
  /// Predict completion likelihood
  Map<String, dynamic> _predictCompletionLikelihood(
    Map<String, dynamic> suggestion,
    Map<String, dynamic> behaviorPattern,
    int currentStreak,
  ) {
    double likelihood = 0.5; // Base 50% likelihood
    final factors = <String>[];
    
    // Adjust based on duration
    final duration = suggestion['duration'] as int? ?? 5;
    if (duration <= 3) {
      likelihood += 0.3;
      factors.add('short duration');
    } else if (duration <= 7) {
      likelihood += 0.1;
      factors.add('moderate duration');
    } else {
      likelihood -= 0.1;
      factors.add('longer duration');
    }
    
    // Adjust based on intensity
    final intensity = suggestion['intensity'] as String? ?? 'moderate';
    switch (intensity) {
      case 'very_light':
        likelihood += 0.2;
        factors.add('very gentle approach');
        break;
      case 'light':
        likelihood += 0.1;
        factors.add('gentle approach');
        break;
      case 'moderate':
        // No change
        break;
      case 'challenging':
        likelihood -= 0.1;
        factors.add('challenging level');
        break;
    }
    
    // Adjust based on current streak
    if (currentStreak >= 7) {
      likelihood += 0.2;
      factors.add('strong habit momentum');
    } else if (currentStreak >= 3) {
      likelihood += 0.1;
      factors.add('building momentum');
    }
    
    // Clamp likelihood between 0.1 and 0.9
    likelihood = likelihood.clamp(0.1, 0.9);
    
    return {
      'likelihood': likelihood,
      'percentage': (likelihood * 100).round(),
      'factors': factors,
      'confidence': likelihood > 0.7 ? 'high' : likelihood > 0.4 ? 'moderate' : 'low',
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
    
    // Update learning metrics
    _userBehaviorPattern['last_updated'] = DateTime.now().toIso8601String();
    
    if (key == 'completion_success') {
      _userBehaviorPattern['successful_completions'] = 
        (_userBehaviorPattern['successful_completions'] ?? 0) + 1;
    }
    
    _userBehaviorPattern['suggestions_tried'] = 
      (_userBehaviorPattern['suggestions_tried'] ?? 0) + 1;
    
    // Analyze patterns for learning
    _analyzeAndUpdateLearningPatterns();
    
    // Persist to storage
    try {
      await _storageService.saveBehaviorPattern(_userBehaviorPattern);
    } catch (e) {
      print('Error saving behavior pattern: $e');
    }
  }
  
  /// Analyze patterns and update learning data
  void _analyzeAndUpdateLearningPatterns() {
    final successfulCompletions = _userBehaviorPattern['successful_completions'] ?? 0;
    final suggestionsTried = _userBehaviorPattern['suggestions_tried'] ?? 0;
    
    // Calculate success rate
    final successRate = suggestionsTried > 0 ? successfulCompletions / suggestionsTried : 0.0;
    _userBehaviorPattern['success_rate'] = successRate;
    
    // Determine if still in learning phase
    _userBehaviorPattern['learning_phase'] = suggestionsTried < 10;
    
    // Analyze preferred categories from completion data
    if (_userBehaviorPattern.containsKey('completion_success')) {
      final completions = _userBehaviorPattern['completion_success'] as List;
      final categoryCount = <String, int>{};
      
      for (final completion in completions) {
        if (completion is Map<String, dynamic> && completion.containsKey('category')) {
          final category = completion['category'] as String;
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }
      
      // Update preferred categories
      final sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _userBehaviorPattern['preferred_categories'] = 
        sortedCategories.take(3).map((e) => e.key).toList();
    }
    
    // Analyze preferred times
    if (_userBehaviorPattern.containsKey('completion_success')) {
      final completions = _userBehaviorPattern['completion_success'] as List;
      final hourCount = <int, int>{};
      
      for (final completion in completions) {
        if (completion is Map<String, dynamic> && completion.containsKey('timestamp')) {
          try {
            final timestamp = DateTime.parse(completion['timestamp'] as String);
            final hour = timestamp.hour;
            hourCount[hour] = (hourCount[hour] ?? 0) + 1;
          } catch (e) {
            // Skip invalid timestamps
          }
        }
      }
      
      // Update preferred times
      final sortedHours = hourCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _userBehaviorPattern['preferred_times'] = 
        sortedHours.take(3).map((e) => e.key).toList();
    }
  }

  Future<Map<String, dynamic>> _getUserBehaviorPattern() async {
    // Try to load from storage first
    try {
      final storedPattern = await _storageService.getBehaviorPattern();
      if (storedPattern != null && storedPattern.isNotEmpty) {
        _userBehaviorPattern.addAll(storedPattern);
        return _userBehaviorPattern;
      }
    } catch (e) {
      print('Error loading behavior pattern: $e');
    }
    
    // If no stored pattern, initialize with default learning data
    if (_userBehaviorPattern.isEmpty) {
      _userBehaviorPattern.addAll({
        'learning_phase': true,
        'suggestions_tried': 0,
        'successful_completions': 0,
        'success_rate': 0.0,
        'preferred_times': [],
        'preferred_categories': [],
        'difficulty_preference': 'adaptive',
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
    
    return _userBehaviorPattern;
  }
  
  // Screen Time Management Methods
  
  /// Check if screen time tracking is supported on this device
  bool isScreenTimeSupported() {
    return _appUsageService.isSupported();
  }
  
  /// Check if the app has screen time permissions
  Future<bool> hasScreenTimePermissions() async {
    return await _appUsageService.hasPermissions();
  }
  
  /// Request screen time permissions from the user
  Future<bool> requestScreenTimePermissions() async {
    return await _appUsageService.requestPermissions();
  }
  
  /// Get a user-friendly message about screen time support
  String getScreenTimeSupportMessage() {
    return _appUsageService.getSupportMessage();
  }
  
  /// Get comprehensive screen time analysis for today
  Future<Map<String, dynamic>> getTodayScreenTimeAnalysis() async {
    try {
      return await _appUsageService.getScreenTimeAnalysis();
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
  
  /// Generate AI-powered personalized habit suggestions using Novita AI
  /// This method integrates mood analysis, screen time data, and user preferences
  /// to create the most suitable habit recommendation using advanced AI processing
  Future<Map<String, dynamic>> generateAIPersonalizedHabitSuggestion({
    required String moodText,
    required List<HabitCategory> preferences,
    double? screenTimeHours,
    int? currentStreak,
    Map<String, int>? recentCompletions,
  }) async {
    try {
      // Step 1: Analyze mood from text using Novita AI
      final moodAnalysis = await analyzeMoodFromText(moodText);
      final detectedMood = _mapStringToUserMood(moodAnalysis['mood'] as String);
      
      // Step 2: Get screen time data if not provided
      final actualScreenTimeHours = screenTimeHours ?? 
          (await analyzeScreenTimeAndUsage())['screenTimeHours'] as double?;
      
      // Step 3: Get user behavior patterns for personalization
      final behaviorPattern = await _getUserBehaviorPattern();
      
      // Step 4: Create comprehensive context for Novita AI
      final aiContext = _buildAIContext(
        moodAnalysis: moodAnalysis,
        preferences: preferences,
        screenTimeHours: actualScreenTimeHours,
        currentStreak: currentStreak ?? 0,
        recentCompletions: recentCompletions ?? {},
        behaviorPattern: behaviorPattern,
      );
      
      // Step 5: Generate AI-powered habit suggestion using Novita AI
      final aiSuggestion = await _generateNovitaAIHabitSuggestion(aiContext);
      
      // Step 6: Enhance suggestion with local intelligence
      final enhancedSuggestion = await _enhanceAISuggestionWithLocalData(
        aiSuggestion,
        detectedMood,
        preferences,
        actualScreenTimeHours,
        currentStreak ?? 0,
        behaviorPattern,
      );
      
      // Step 7: Store interaction for learning
      await _updateBehaviorPattern('ai_suggestion_generated', {
        'moodText': moodText,
        'detectedMood': detectedMood.name,
        'screenTimeHours': actualScreenTimeHours,
        'preferences': preferences.map((p) => p.name).toList(),
        'suggestionTitle': enhancedSuggestion['title'],
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return {
        'success': true,
        'suggestion': enhancedSuggestion,
        'moodAnalysis': moodAnalysis,
        'screenTimeAnalysis': actualScreenTimeHours != null ? {
          'hours': actualScreenTimeHours,
          'category': _categorizeScreenTime(actualScreenTimeHours),
          'recommendation': _getScreenTimeRecommendation(actualScreenTimeHours),
        } : null,
        'aiReasoning': aiSuggestion['reasoning'],
        'personalizationFactors': {
          'mood': detectedMood.name,
          'preferences': preferences.map((p) => p.name).toList(),
          'screenTime': actualScreenTimeHours,
          'streak': currentStreak,
          'learningPhase': behaviorPattern['learning_phase'],
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // Fallback to standard suggestion generation if AI fails
      print('AI suggestion generation failed: $e');
      return await generateSmartHabitSuggestion(
        mood: UserMood.happy, // Default fallback mood
        preferences: preferences,
        currentStreak: currentStreak,
        recentCompletions: recentCompletions,
      );
    }
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
 
   /// Extract emotion from AI response text when JSON parsing fails
  String _extractEmotionFromText(String text) {
    final lowercaseText = text.toLowerCase();
    
    // Check for emotion keywords in the response
    if (lowercaseText.contains('happy') || lowercaseText.contains('joy') || lowercaseText.contains('positive')) {
      return 'happy';
    } else if (lowercaseText.contains('stressed') || lowercaseText.contains('anxious') || lowercaseText.contains('worried')) {
      return 'stressed';
    } else if (lowercaseText.contains('tired') || lowercaseText.contains('exhausted') || lowercaseText.contains('fatigue')) {
      return 'tired';
    } else if (lowercaseText.contains('energized') || lowercaseText.contains('motivated') || lowercaseText.contains('enthusiastic')) {
      return 'energized';
    }
    
    return 'neutral';
  }

  /// Map emotion to sentiment category
  String _mapEmotionToSentiment(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'energized':
        return 'positive';
      case 'stressed':
        return 'negative';
      case 'tired':
      case 'neutral':
      default:
        return 'neutral';
    }
  }
  
  /// Map string mood to UserMood enum
  UserMood _mapStringToUserMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return UserMood.happy;
      case 'stressed':
        return UserMood.stressed;
      case 'tired':
        return UserMood.tired;
      case 'energized':
        return UserMood.energized;
      default:
        return UserMood.happy; // Default fallback
    }
  }
  
  /// Build comprehensive AI context for habit suggestion generation
  Map<String, dynamic> _buildAIContext({
    required Map<String, dynamic> moodAnalysis,
    required List<HabitCategory> preferences,
    double? screenTimeHours,
    required int currentStreak,
    required Map<String, int> recentCompletions,
    required Map<String, dynamic> behaviorPattern,
  }) {
    return {
      'mood': {
        'detected': moodAnalysis['mood'],
        'confidence': moodAnalysis['confidence'],
        'reasoning': moodAnalysis['reasoning'],
        'sentiment': moodAnalysis.containsKey('sentiment') ? moodAnalysis['sentiment'] : 'neutral',
      },
      'preferences': preferences.map((p) => p.name).toList(),
      'screenTime': {
        'hours': screenTimeHours ?? 0.0,
        'category': screenTimeHours != null ? _categorizeScreenTime(screenTimeHours) : 'unknown',
        'isHigh': screenTimeHours != null && screenTimeHours >= _highScreenTimeThreshold,
        'isModerate': screenTimeHours != null && screenTimeHours >= _moderateScreenTimeThreshold,
      },
      'userProgress': {
        'currentStreak': currentStreak,
        'recentCompletions': recentCompletions,
        'totalCompletions': recentCompletions.values.fold(0, (sum, count) => sum + count),
      },
      'behaviorPattern': {
        'learningPhase': behaviorPattern['learning_phase'] ?? true,
        'successRate': behaviorPattern['success_rate'] ?? 0.0,
        'preferredCategories': behaviorPattern['preferred_categories'] ?? [],
        'preferredTimes': behaviorPattern['preferred_times'] ?? [],
        'difficultyPreference': behaviorPattern['difficulty_preference'] ?? 'adaptive',
      },
      'timeContext': {
        'hour': DateTime.now().hour,
        'dayOfWeek': DateTime.now().weekday,
        'timeOfDay': _getTimeOfDay(),
      },
    };
  }
  
  /// Generate habit suggestion using Novita AI with comprehensive context
  Future<Map<String, dynamic>> _generateNovitaAIHabitSuggestion(Map<String, dynamic> context) async {
    final headers = {
      'Authorization': 'Bearer $_novitaApiKey',
      'Content-Type': 'application/json',
    };
    
    // Create detailed prompt for habit suggestion
    final systemPrompt = '''
You are an expert AI habit coach specializing in personalized wellness recommendations. Your task is to suggest the perfect micro-habit based on comprehensive user analysis.

Analyze the provided context and suggest ONE specific, actionable micro-habit that:
1. Matches the user's current mood and emotional state
2. Considers their screen time patterns and digital wellness
3. Aligns with their stated preferences
4. Is appropriate for their current streak and motivation level
5. Takes into account their behavioral patterns and success history

Provide your response in this exact JSON format:
{
  "title": "Specific habit title (max 50 characters)",
  "description": "Clear, actionable description (max 150 characters)",
  "duration": "Duration in minutes (number only)",
  "category": "physical|mindfulness|productivity|relaxation",
  "difficulty": "easy|moderate|challenging",
  "reasoning": "Why this habit is perfect for the user right now (max 200 characters)",
  "motivation": "Encouraging message to inspire action (max 100 characters)",
  "tips": ["tip1", "tip2", "tip3"]
}

Guidelines:
- For stressed mood + high screen time: Suggest offline relaxation activities
- For energized mood + low screen time: Suggest active or productive habits
- For tired mood: Suggest gentle, restorative activities
- For happy mood: Suggest engaging, positive reinforcement activities
- Consider user preferences but prioritize mood and screen time balance
- Adapt difficulty based on current streak (easier for beginners, progressive for advanced)
- Keep suggestions micro-sized (2-15 minutes) for better completion rates''';
    
    final userPrompt = '''
User Context Analysis:

MOOD: ${context['mood']['detected']} (confidence: ${context['mood']['confidence']})
Reasoning: ${context['mood']['reasoning']}

SCREEN TIME: ${context['screenTime']['hours']} hours (${context['screenTime']['category']})
High screen time: ${context['screenTime']['isHigh']}

PREFERENCES: ${context['preferences'].join(', ')}

PROGRESS:
- Current streak: ${context['userProgress']['currentStreak']} days
- Recent completions: ${context['userProgress']['totalCompletions']}

BEHAVIOR PATTERNS:
- Learning phase: ${context['behaviorPattern']['learningPhase']}
- Success rate: ${(context['behaviorPattern']['successRate'] * 100).toStringAsFixed(1)}%
- Preferred categories: ${context['behaviorPattern']['preferredCategories'].join(', ')}
- Preferred times: ${context['behaviorPattern']['preferredTimes'].join(', ')}

TIME CONTEXT:
- Current time: ${context['timeContext']['timeOfDay']}
- Day of week: ${context['timeContext']['dayOfWeek']}

Based on this comprehensive analysis, suggest the perfect micro-habit for this user right now.''';
    
    final body = json.encode({
      'model': _novitaModel,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        {
          'role': 'user',
          'content': userPrompt,
        }
      ],
      'max_tokens': 500,
      'temperature': 0.7, // Balanced creativity and consistency
    });
    
    try {
      final response = await http.post(
        Uri.parse(_novitaApiUrl),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final content = result['choices']?[0]?['message']?['content'] ?? '';
        
        // Parse the JSON response from the LLM
        try {
          final suggestionResult = json.decode(content) as Map<String, dynamic>;
          return {
            'title': suggestionResult['title'] ?? 'Mindful Moment',
            'description': suggestionResult['description'] ?? 'Take a moment to breathe and center yourself',
            'duration': suggestionResult['duration'] ?? '5',
            'category': suggestionResult['category'] ?? 'mindfulness',
            'difficulty': suggestionResult['difficulty'] ?? 'easy',
            'reasoning': suggestionResult['reasoning'] ?? 'AI-generated suggestion based on your current state',
            'motivation': suggestionResult['motivation'] ?? 'You\'ve got this! Small steps lead to big changes.',
            'tips': suggestionResult['tips'] ?? ['Start small', 'Be consistent', 'Celebrate progress'],
            'source': 'novita_ai',
          };
        } catch (parseError) {
          // Fallback if JSON parsing fails
          return _generateFallbackAISuggestion(context);
        }
      } else {
        throw Exception('API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Novita AI API error: ${e.toString()}');
    }
  }
  
  /// Generate fallback suggestion when AI fails
  Map<String, dynamic> _generateFallbackAISuggestion(Map<String, dynamic> context) {
    final mood = context['mood']['detected'] as String;
    final isHighScreenTime = context['screenTime']['isHigh'] as bool;
    final preferences = context['preferences'] as List<dynamic>;
    
    if (mood == 'stressed' && isHighScreenTime) {
      return {
        'title': 'Digital Detox Walk',
        'description': 'Take a 10-minute walk without your phone to reduce stress and screen fatigue',
        'duration': '10',
        'category': 'physical',
        'difficulty': 'easy',
        'reasoning': 'High screen time and stress detected - offline movement will help reset both',
        'motivation': 'Fresh air and movement are exactly what you need right now!',
        'tips': ['Leave your phone behind', 'Focus on your surroundings', 'Take deep breaths'],
        'source': 'fallback_ai',
      };
    } else if (mood == 'energized') {
      return {
        'title': 'Power Productivity Sprint',
        'description': 'Channel your energy into a focused 15-minute task or goal',
        'duration': '15',
        'category': 'productivity',
        'difficulty': 'moderate',
        'reasoning': 'Your high energy is perfect for tackling something meaningful',
        'motivation': 'Your energy is contagious! Let\'s make something happen!',
        'tips': ['Pick one specific task', 'Set a timer', 'Celebrate completion'],
        'source': 'fallback_ai',
      };
    } else {
      return {
        'title': '5-Minute Mindful Reset',
        'description': 'Take five minutes to breathe deeply and center yourself',
        'duration': '5',
        'category': 'mindfulness',
        'difficulty': 'easy',
        'reasoning': 'A gentle reset is perfect for your current state',
        'motivation': 'Small moments of mindfulness create big changes!',
        'tips': ['Find a quiet space', 'Focus on your breath', 'Be kind to yourself'],
        'source': 'fallback_ai',
      };
    }
  }
  
  /// Enhance AI suggestion with local intelligence and personalization
  Future<Map<String, dynamic>> _enhanceAISuggestionWithLocalData(
    Map<String, dynamic> aiSuggestion,
    UserMood mood,
    List<HabitCategory> preferences,
    double? screenTimeHours,
    int currentStreak,
    Map<String, dynamic> behaviorPattern,
  ) async {
    final enhanced = Map<String, dynamic>.from(aiSuggestion);
    
    // Add personalized title enhancement
    enhanced['personalizedTitle'] = _generatePersonalizedTitle(
      aiSuggestion['title'] as String,
      mood,
      currentStreak,
    );
    
    // Add dynamic description with context
    enhanced['dynamicDescription'] = _generateDynamicDescription(
      aiSuggestion['description'] as String,
      mood,
      screenTimeHours,
      currentStreak,
    );
    
    // Add completion prediction - fix parameter types
    enhanced['completionPrediction'] = _predictCompletionLikelihood(
      aiSuggestion,
      behaviorPattern,
      currentStreak,
    );
    
    // Add streak-based encouragement
    enhanced['streakEncouragement'] = _generateStreakEncouragement(currentStreak);
    
    // Add next-level suggestion for progression
    enhanced['nextLevelSuggestion'] = _generateNextLevelSuggestion(
      aiSuggestion,
      behaviorPattern,
    );
    
    return enhanced;
  }
  
  /// Generate personalized title based on mood and streak
  String _generatePersonalizedTitle(String baseTitle, UserMood mood, int currentStreak) {
    final moodPrefixes = {
      UserMood.happy: ['Joyful', 'Uplifting', 'Energizing'],
      UserMood.stressed: ['Calming', 'Soothing', 'Relaxing'],
      UserMood.tired: ['Gentle', 'Restorative', 'Refreshing'],
      UserMood.energized: ['Dynamic', 'Invigorating', 'Powerful'],
    };
    
    String prefix = '';
    if (moodPrefixes.containsKey(mood)) {
      final prefixes = moodPrefixes[mood]!;
      prefix = '${prefixes[Random().nextInt(prefixes.length)]} ';
    }
    
    String suffix = '';
    if (currentStreak >= 30) {
      suffix = ' (Month Champion!)';
    } else if (currentStreak >= 14) {
      suffix = ' (Two Weeks!)';
    } else if (currentStreak >= 7) {
      suffix = ' (Week Strong!)';
    } else if (currentStreak >= 3) {
      suffix = ' (Momentum!)';
    } else if (currentStreak == 2) {
      suffix = ' (Building!)';
    } else if (currentStreak == 1) {
      suffix = ' (Day 1!)';
    }
    
    return '$prefix$baseTitle$suffix';
  }
  
  /// Generate dynamic description with context
  String _generateDynamicDescription(
    String baseDescription,
    UserMood mood,
    double? screenTimeHours,
    int currentStreak,
  ) {
    final buffer = StringBuffer(baseDescription);
    
    // Add mood context
    switch (mood) {
      case UserMood.stressed:
        buffer.write(' This will help you find calm and reduce tension.');
        break;
      case UserMood.tired:
        buffer.write(' Perfect for gently restoring your energy.');
        break;
      case UserMood.energized:
        buffer.write(' Great way to channel your positive energy!');
        break;
      case UserMood.happy:
        buffer.write(' Keep that positive momentum going!');
        break;
    }
    
    // Add screen time context
    if (screenTimeHours != null && screenTimeHours >= _highScreenTimeThreshold) {
      buffer.write(' After ${screenTimeHours.toStringAsFixed(1)} hours of screen time, this offline activity will help reset your focus.');
    } else if (screenTimeHours != null && screenTimeHours >= _moderateScreenTimeThreshold) {
      buffer.write(' A nice balance to your ${screenTimeHours.toStringAsFixed(1)} hours of screen time today.');
    }
    
    // Add streak context
    if (currentStreak >= 7) {
      buffer.write(' Your $currentStreak-day streak shows incredible dedication!');
    } else if (currentStreak >= 3) {
      buffer.write(' Building on your $currentStreak-day streak!');
    } else if (currentStreak > 0) {
      buffer.write(' Day $currentStreak of building this habit!');
    }
    
    return buffer.toString();
  }
  
  /// Generate streak-based encouragement
  String _generateStreakEncouragement(int currentStreak) {
    if (currentStreak >= 30) {
      return '🏆 Incredible! 30+ days of consistency - you\'re a true habit master!';
    } else if (currentStreak >= 14) {
      return '⭐ Amazing! Two weeks strong - you\'re building something powerful!';
    } else if (currentStreak >= 7) {
      return '🔥 Fantastic! One week completed - you\'re on fire!';
    } else if (currentStreak >= 3) {
      return '💪 Great momentum! $currentStreak days in a row!';
    } else if (currentStreak > 0) {
      return '🌟 You\'re building something great! Day $currentStreak!';
    } else {
      return '🚀 Ready to start your streak? Every journey begins with day one!';
    }
  }
  
  /// Generate next-level suggestion for progression
  Map<String, dynamic> _generateNextLevelSuggestion(
    Map<String, dynamic> currentSuggestion,
    Map<String, dynamic> behaviorPattern,
  ) {
    final category = currentSuggestion['category'] as String? ?? 'mindfulness';
    final currentDuration = int.tryParse(currentSuggestion['duration'] as String? ?? '5') ?? 5;
    final successRate = behaviorPattern['successRate'] as double? ?? 0.5;
    
    // Suggest progression based on success rate
    if (successRate >= 0.8) {
      // High success rate - suggest more challenging version
      final nextDuration = (currentDuration * 1.5).round();
      return {
        'title': 'Extended ${currentSuggestion['title']}',
        'description': 'Ready for a longer session? Try ${nextDuration} minutes.',
        'duration': nextDuration.toString(),
        'category': category,
        'difficulty': 'moderate',
        'reasoning': 'Your high success rate suggests you\'re ready for more challenge!',
      };
    } else if (successRate >= 0.6) {
      // Moderate success rate - suggest variation
      return {
        'title': 'Variation: ${currentSuggestion['title']}',
        'description': 'Try a different approach to ${category.toLowerCase()}.',
        'duration': currentDuration.toString(),
        'category': category,
        'difficulty': 'easy',
        'reasoning': 'A fresh variation might help maintain your interest!',
      };
    } else {
      // Lower success rate - suggest easier version
      final easierDuration = (currentDuration * 0.7).round().clamp(1, 10);
      return {
        'title': 'Gentle ${currentSuggestion['title']}',
        'description': 'Let\'s try a shorter, easier version for ${easierDuration} minutes.',
        'duration': easierDuration.toString(),
        'category': category,
        'difficulty': 'easy',
        'reasoning': 'Starting smaller can help build consistency!',
      };
    }
  }
  
  /// Get time of day context
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }
}