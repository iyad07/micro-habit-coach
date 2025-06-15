import '../models/habit.dart';
import '../models/user_profile.dart';
import '../services/ai_agent_service.dart';

/// Example usage of the enhanced AI Agent Service
/// This demonstrates all the backend AI functionality for the micro habit tracker
class AIAgentUsageExample {
  final AIAgentService _aiAgent = AIAgentService();

  /// TASK 1 EXAMPLE: Analyzing User Mood and Preferences
  Future<void> demonstrateMoodAnalysis() async {
    print('=== TASK 1: Mood and Preference Analysis ===');
    
    // Example: User is stressed and prefers mindfulness activities
    final moodAnalysis = await _aiAgent.analyzeMoodAndPreferences(
      UserMood.stressed,
      [HabitCategory.mindfulness, HabitCategory.relaxation],
    );
    
    print('Mood Analysis Result:');
    print('- Mood: ${moodAnalysis['mood']}');
    print('- Analysis: ${moodAnalysis['moodAnalysis']}');
    print('- Emotional State: ${moodAnalysis['emotionalState']}');
    print('- Recommended Categories: ${moodAnalysis['recommendedCategories']}');
    print('');
  }

  /// TASK 2 EXAMPLE: Analyzing Screen Time & Usage Patterns
  Future<void> demonstrateScreenTimeAnalysis() async {
    print('=== TASK 2: Screen Time Analysis ===');
    
    // Example: User has high screen time (7 hours)
    final screenAnalysis = await _aiAgent.analyzeScreenTimeAndUsage(
      7.5, // 7.5 hours of screen time
      {
        'Instagram': 3.2,
        'YouTube': 2.1,
        'Chrome': 1.8,
        'WhatsApp': 0.4,
      },
    );
    
    print('Screen Time Analysis Result:');
    print('- Screen Time: ${screenAnalysis['screenTimeHours']} hours');
    print('- Level: ${screenAnalysis['screenTimeLevel']}');
    print('- Recommendation: ${screenAnalysis['recommendation']}');
    print('- Balance Needed: ${screenAnalysis['balanceNeeded']}');
    print('- Suggested Break: ${screenAnalysis['suggestedBreakDuration']} minutes');
    
    if (screenAnalysis['appUsageAnalysis'] != null) {
      final appAnalysis = screenAnalysis['appUsageAnalysis'];
      print('- Top App: ${appAnalysis['topApp']} (${appAnalysis['topAppUsage']} hours)');
      print('- Social Media Heavy: ${appAnalysis['socialMediaHeavy']}');
    }
    print('');
  }

  /// TASK 3 EXAMPLE: Generating Personalized Habit Suggestions
  Future<void> demonstratePersonalizedSuggestions() async {
    print('=== TASK 3: Personalized Habit Suggestions ===');
    
    // Example: Energized user with moderate screen time and existing streak
    final suggestion = await _aiAgent.generatePersonalizedHabitSuggestion(
      mood: UserMood.energized,
      preferences: [HabitCategory.physical, HabitCategory.productivity],
      screenTimeHours: 4.5,
      currentStreak: 5,
      recentCompletions: {
        'physical': 4,
        'mindfulness': 2,
        'productivity': 3,
      },
    );
    
    print('Personalized Suggestion Result:');
    final habitSuggestion = suggestion['suggestion'];
    print('- Title: ${habitSuggestion['title']}');
    print('- Description: ${habitSuggestion['description']}');
    print('- Category: ${habitSuggestion['category']}');
    print('- Duration: ${habitSuggestion['duration']} minutes');
    print('- Difficulty: ${habitSuggestion['difficulty']}');
    print('- Reasoning: ${suggestion['reasoning']}');
    print('- Detailed Reasoning: ${habitSuggestion['reasoning']}');
    print('');
  }

  /// TASK 4 EXAMPLE: Habit Completion and Streak Tracking
  Future<void> demonstrateHabitCompletion() async {
    print('=== TASK 4: Habit Completion Tracking ===');
    
    // Example: User completes a habit
    print('--- Successful Completion ---');
    final completionResult = await _aiAgent.processHabitCompletion(
      'habit_123',
      true, // completed
    );
    
    print('Completion Result:');
    print('- Habit ID: ${completionResult['habitId']}');
    print('- Completed: ${completionResult['completed']}');
    if (completionResult['completed']) {
      print('- New Streak: ${completionResult['newStreak']}');
      print('- Total Completions: ${completionResult['totalCompletions']}');
      print('- Celebration: ${completionResult['celebrationMessage']}');
      
      final nextSuggestion = completionResult['nextSuggestion'];
      if (nextSuggestion != null) {
        print('- Next Day Suggestion: ${nextSuggestion['title']}');
        print('  ${nextSuggestion['message']}');
      }
    }
    
    print('');
    
    // Example: User misses a habit
    print('--- Missed Habit ---');
    final missedResult = await _aiAgent.processHabitCompletion(
      'habit_456',
      false, // not completed
    );
    
    print('Missed Habit Result:');
    print('- Encouragement: ${missedResult['encouragementMessage']}');
    
    final easierSuggestion = missedResult['easierSuggestion'];
    if (easierSuggestion != null) {
      print('- Easier Suggestion: ${easierSuggestion['title']}');
      print('  ${easierSuggestion['message']}');
    }
    print('');
  }

  /// TASK 5 EXAMPLE: Optimizing Habit Suggestions
  Future<void> demonstrateHabitOptimization() async {
    print('=== TASK 5: Habit Optimization ===');
    
    final optimization = await _aiAgent.optimizeHabitSuggestions();
    
    if (optimization.containsKey('error')) {
      print('Error: ${optimization['error']}');
      return;
    }
    
    print('Optimization Analysis:');
    
    final performance = optimization['userPerformance'];
    if (performance != null) {
      print('- Performance Level: ${performance['performance']}');
      print('- Total Completions: ${performance['totalCompletions']}');
      print('- Average Streak: ${performance['averageStreak']}');
      print('- Completion Rate: ${performance['completionRate']}%');
    }
    
    final preferredCategories = optimization['preferredCategories'];
    if (preferredCategories != null) {
      print('- Preferred Categories:');
      preferredCategories.forEach((category, count) {
        print('  * $category: $count completions');
      });
    }
    
    final timing = optimization['optimalTiming'];
    if (timing != null) {
      print('- Best Day: ${timing['bestDayOfWeek']}');
      print('- Best Time: ${timing['bestTimeOfDay']}');
      print('- Timing Recommendation: ${timing['recommendation']}');
    }
    
    print('- Difficulty Adjustment: ${optimization['difficultyAdjustment']}');
    
    final recommendations = optimization['recommendations'];
    if (recommendations != null && recommendations.isNotEmpty) {
      print('- Optimization Recommendations:');
      for (final rec in recommendations) {
        print('  * $rec');
      }
    }
    print('');
  }

  /// Comprehensive example showing the complete AI workflow
  Future<void> demonstrateCompleteWorkflow() async {
    print('\n🤖 === COMPLETE AI AGENT WORKFLOW DEMONSTRATION === 🤖\n');
    
    // Step 1: Analyze user's current state
    print('📊 Step 1: Analyzing user mood and screen time...');
    await demonstrateMoodAnalysis();
    await demonstrateScreenTimeAnalysis();
    
    // Step 2: Generate personalized suggestion
    print('💡 Step 2: Generating personalized habit suggestion...');
    await demonstratePersonalizedSuggestions();
    
    // Step 3: Process habit completion
    print('✅ Step 3: Processing habit completion...');
    await demonstrateHabitCompletion();
    
    // Step 4: Optimize future suggestions
    print('🚀 Step 4: Optimizing future suggestions...');
    await demonstrateHabitOptimization();
    
    print('🎉 Complete workflow demonstration finished!');
  }

  /// Example of real-time habit suggestion based on current context
  Future<Map<String, dynamic>> getRealTimeHabitSuggestion({
    required UserMood currentMood,
    required List<HabitCategory> preferences,
    double? todayScreenTime,
    int? currentStreak,
  }) async {
    print('🔄 Generating real-time habit suggestion...');
    
    // Analyze current context
    final moodAnalysis = await _aiAgent.analyzeMoodAndPreferences(
      currentMood,
      preferences,
    );
    
    Map<String, dynamic>? screenAnalysis;
    if (todayScreenTime != null) {
      screenAnalysis = await _aiAgent.analyzeScreenTimeAndUsage(
        todayScreenTime,
        null,
      );
    }
    
    // Generate optimized suggestion
    final suggestion = await _aiAgent.generatePersonalizedHabitSuggestion(
      mood: currentMood,
      preferences: preferences,
      screenTimeHours: todayScreenTime,
      currentStreak: currentStreak,
    );
    
    return {
      'contextAnalysis': {
        'mood': moodAnalysis,
        'screenTime': screenAnalysis,
      },
      'suggestion': suggestion,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Example of processing a week's worth of habit data
  Future<void> demonstrateWeeklyAnalysis() async {
    print('📅 === WEEKLY HABIT ANALYSIS EXAMPLE ===\n');
    
    // Simulate a week of different moods and completions
    final weekData = [
      {'day': 'Monday', 'mood': UserMood.energized, 'completed': true, 'screenTime': 3.5},
      {'day': 'Tuesday', 'mood': UserMood.happy, 'completed': true, 'screenTime': 4.2},
      {'day': 'Wednesday', 'mood': UserMood.stressed, 'completed': false, 'screenTime': 6.8},
      {'day': 'Thursday', 'mood': UserMood.tired, 'completed': true, 'screenTime': 5.1},
      {'day': 'Friday', 'mood': UserMood.happy, 'completed': true, 'screenTime': 4.7},
      {'day': 'Saturday', 'mood': UserMood.energized, 'completed': true, 'screenTime': 2.9},
      //{'day': 'Sunday', 'mood': UserMood.relaxed, 'completed': true, 'screenTime': 3.8},
    ];
    
    print('Processing weekly data...');
    
    for (final dayData in weekData) {
      print('\n--- ${dayData['day']} ---');
      
      // Analyze mood and screen time
      final mood = dayData['mood'] as UserMood;
      final screenTime = dayData['screenTime'] as double;
      final completed = dayData['completed'] as bool;
      
      // Get suggestion for the day
      final suggestion = await _aiAgent.generatePersonalizedHabitSuggestion(
        mood: mood,
        preferences: [HabitCategory.physical, HabitCategory.mindfulness],
        screenTimeHours: screenTime,
      );
      
      print('Mood: ${mood.displayName}');
      print('Screen Time: ${screenTime}h');
      print('Suggested: ${suggestion['suggestion']['title']}');
      print('Completed: ${completed ? "✅" : "❌"}');
      
      // Process completion
      if (completed) {
        final result = await _aiAgent.processHabitCompletion('habit_week', true);
        print('Result: ${result['celebrationMessage']}');
      }
    }
    
    print('\n📈 Weekly analysis complete!');
  }
}

/// Usage example function
Future<void> runAIAgentExamples() async {
  final example = AIAgentUsageExample();
  
  // Run individual examples
  await example.demonstrateMoodAnalysis();
  await example.demonstrateScreenTimeAnalysis();
  await example.demonstratePersonalizedSuggestions();
  await example.demonstrateHabitCompletion();
  await example.demonstrateHabitOptimization();
  
  // Run complete workflow
  await example.demonstrateCompleteWorkflow();
  
  // Run weekly analysis
  await example.demonstrateWeeklyAnalysis();
  
  // Example of real-time suggestion
  final realTimeSuggestion = await example.getRealTimeHabitSuggestion(
    currentMood: UserMood.stressed,
    preferences: [HabitCategory.mindfulness],
    todayScreenTime: 5.5,
    currentStreak: 3,
  );
  
  print('\n🔥 Real-time suggestion generated!');
  print('Context: ${realTimeSuggestion['contextAnalysis']}');
  print('Suggestion: ${realTimeSuggestion['suggestion']}');
}