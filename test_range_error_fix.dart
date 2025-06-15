import 'package:flutter/widgets.dart';
import 'lib/services/ai_agent_service.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  final aiAgent = AIAgentService();
  
  print('=== Testing RangeError Fix ===\n');
  
  // Test the specific case that was causing the RangeError
  final testCase = "I'm so energized after my morning coffee! ☕⚡";
  
  try {
    print('Testing: "$testCase"');
    
    // This was causing the RangeError before the fix
    final result = await aiAgent.generateHabitFromMoodText(testCase);
    
    print('✅ SUCCESS - No RangeError!');
    print('Detected Mood: ${result['moodAnalysis']['detectedMood']}');
    print('Habit Suggestion: ${result['habitSuggestion']['title']}');
    print('Category: ${result['habitSuggestion']['category']}');
    print('Duration: ${result['habitSuggestion']['duration']}');
    print('Difficulty: ${result['habitSuggestion']['difficulty']}');
    
  } catch (e) {
    print('❌ ERROR: $e');
    print('Stack trace: ${StackTrace.current}');
  }
  
  print('\n=== Test completed ===');
}