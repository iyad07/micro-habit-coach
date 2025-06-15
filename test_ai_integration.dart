import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/services/ai_agent_service.dart';
import 'lib/models/user_profile.dart';
import 'lib/models/habit.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🤖 Testing AI Service Integration with Habit Suggestion Card');
  print('=' * 60);
  
  final aiService = AIAgentService();
  
  // Test user profile
  final userProfile = UserProfile(
    id: 'test_user',
    name: 'Alex',
    email: 'alex@example.com',
    currentMood: UserMood.stressed,
    preferredCategories: [HabitCategory.mindfulness, HabitCategory.physical],
    screenTimeMinutes: 180, // 3 hours
    createdAt: DateTime.now(),
  );
  
  print('👤 User Profile:');
  print('   Name: ${userProfile.name}');
  print('   Current Mood: ${userProfile.currentMood?.displayName}');
  print('   Preferred Categories: ${userProfile.preferredCategories.map((c) => c.displayName).join(", ")}');
  print('   Screen Time: ${userProfile.screenTimeMinutes} minutes');
  print('');
  
  // Test completed habits
  final completedHabits = [
    Habit(
      id: 'habit1',
      title: 'Morning Meditation',
      description: '5 minutes of mindful breathing',
      category: HabitCategory.mindfulness,
      durationMinutes: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      completions: [DateTime.now().subtract(const Duration(days: 1))],
    ),
  ];
  
  print('✅ Completed Habits:');
  for (final habit in completedHabits) {
    print('   - ${habit.title} (${habit.category.displayName})');
  }
  print('');
  
  try {
    print('🧠 Generating Personalized AI Suggestion...');
    print('-' * 40);
    
    final suggestion = await aiService.generatePersonalizedHabitSuggestion(
      userProfile: userProfile,
      completedHabits: completedHabits,
      currentStreak: 1,
    );
    
    print('📋 AI Generated Suggestion:');
    print('   Title: ${suggestion['title']}');
    print('   Description: ${suggestion['description']}');
    print('   Category: ${suggestion['category']}');
    print('   Duration: ${suggestion['duration']} minutes');
    print('   Reasoning: ${suggestion['reasoning']}');
    print('');
    
    // Test mood analysis
    print('🎭 Testing Mood Analysis...');
    print('-' * 40);
    
    final moodTexts = [
      'I feel overwhelmed with work today',
      'I\'m excited and full of energy!',
      'Feeling tired and need some rest',
      'Happy and grateful for everything',
    ];
    
    for (final text in moodTexts) {
      final analyzedMood = await aiService.analyzeMoodFromText(text);
      print('   "$text"');
      print('   → Detected Mood: ${analyzedMood.displayName}');
      print('');
    }
    
    // Test next day suggestion
    print('🌅 Testing Next Day Suggestion...');
    print('-' * 40);
    
    final nextDaySuggestion = await aiService.generateNextDaySuggestion(
      completedHabit: completedHabits.first,
      userProfile: userProfile,
    );
    
    print('📅 Next Day Suggestion:');
    print('   Title: ${nextDaySuggestion['title']}');
    print('   Description: ${nextDaySuggestion['description']}');
    print('   Category: ${nextDaySuggestion['category']}');
    print('   Duration: ${nextDaySuggestion['duration']} minutes');
    print('   Reasoning: ${nextDaySuggestion['reasoning']}');
    print('');
    
    // Test habit suggestion card data structure
    print('🎨 Testing Habit Suggestion Card Data...');
    print('-' * 40);
    
    final cardData = {
      'title': suggestion['title'] ?? 'Default Title',
      'description': suggestion['description'] ?? 'Default Description',
      'category': suggestion['category'] ?? 'Mindfulness',
      'duration': suggestion['duration']?.toString() ?? '5',
      'reasoning': suggestion['reasoning'] ?? 'AI-generated suggestion',
    };
    
    print('💳 Card Data Structure:');
    cardData.forEach((key, value) {
      print('   $key: $value');
    });
    print('');
    
    // Test error handling
    print('⚠️  Testing Error Handling...');
    print('-' * 40);
    
    try {
      final invalidProfile = UserProfile(
        id: 'invalid',
        name: 'Test',
        email: 'test@example.com',
        currentMood: null, // This might cause issues
        preferredCategories: [],
        createdAt: DateTime.now(),
      );
      
      final fallbackSuggestion = await aiService.generatePersonalizedHabitSuggestion(
        userProfile: invalidProfile,
        completedHabits: [],
        currentStreak: 0,
      );
      
      print('✅ Fallback suggestion generated successfully:');
      print('   Title: ${fallbackSuggestion['title']}');
      
    } catch (e) {
      print('❌ Error handled gracefully: $e');
    }
    
    print('');
    print('🎉 AI Service Integration Test Completed Successfully!');
    print('=' * 60);
    
  } catch (e, stackTrace) {
    print('❌ Error during AI integration test: $e');
    print('Stack trace: $stackTrace');
  }
}