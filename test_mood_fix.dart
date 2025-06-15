import 'package:flutter/widgets.dart';
import 'lib/services/ai_agent_service.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  final aiAgent = AIAgentService();
  
  print('=== Testing Mood Classification Fixes ===\n');
  
  // Test cases that were problematic
  final testCases = [
    "Today was amazing, I feel fantastic!",
    "I'm feeling stressed and anxious about my presentation tomorrow",
    "I'm so happy and excited about my new project! 🎉",
    "I'm exhausted and just want to sleep 😴",
  ];
  
  for (final testCase in testCases) {
    print('Testing: "$testCase"');
    
    try {
      // Test mood analysis
      final moodResult = await aiAgent.analyzeMoodFromText(testCase);
      print('Mood: ${moodResult['detectedMood']} (${(moodResult['confidence'] * 100).toStringAsFixed(1)}%)');
      print('Keywords: ${moodResult['keywordAnalysis']['foundKeywords']}');
      
      // Test habit generation (this was causing the binding error)
      final habitResult = await aiAgent.generateHabitFromMoodText(testCase);
      print('Habit: ${habitResult['habitSuggestion']['suggestion']}');
      print('Category: ${habitResult['habitSuggestion']['category']}');
      
    } catch (e) {
      print('Error: $e');
    }
    
    print('---\n');
  }
  
  print('Test completed successfully!');
}