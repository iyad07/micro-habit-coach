import '../services/ai_agent_service.dart';
import 'package:flutter/widgets.dart';
import '../models/user_profile.dart';

/// Example usage of the mood analysis functionality
/// This demonstrates how to analyze user mood from text input
/// and generate personalized habit suggestions
class MoodAnalysisExample {
  final AIAgentService _aiAgent = AIAgentService();

  /// Example 1: Analyze mood from text input
  Future<void> analyzeMoodExample() async {
    // Example user inputs
    final List<String> userInputs = [
      "I'm feeling really stressed today with all this work 😰",
      "I'm so happy and excited about my new project! 🎉",
      "I'm exhausted and just want to sleep 😴",
      "I'm feeling energized and ready to take on the world! ⚡",
      "Feeling overwhelmed with everything going on",
      "Today was amazing, I feel fantastic!",
    ];

    print('=== Mood Analysis Examples ===\n');

    for (final input in userInputs) {
      print('User Input: "$input"');
      
      // Analyze mood from text
      final moodAnalysis = await _aiAgent.analyzeMoodFromText(input);
      
      if (moodAnalysis.containsKey('error')) {
        print('Error: ${moodAnalysis['error']}');
      } else {
        print('Detected Mood: ${moodAnalysis['detectedMood']}');
        print('Confidence: ${(moodAnalysis['confidence'] * 100).toStringAsFixed(1)}%');
        print('Reasoning: ${moodAnalysis['reasoning']}');
        
        final keywordAnalysis = moodAnalysis['keywordAnalysis'];
        if (keywordAnalysis['totalMatches'] > 0) {
          print('Found Keywords: ${keywordAnalysis['foundKeywords']}');
        }
      }
      
      print('---\n');
    }
  }

  /// Example 2: Generate habit suggestions based on mood text
  Future<void> generateHabitFromMoodExample() async {
    final List<String> moodTexts = [
      "I'm feeling stressed and anxious about my presentation tomorrow",
      "I'm so energized after my morning coffee! ☕⚡",
      "Feeling tired and drained after a long day",
      "I'm in such a good mood today! Everything is going well 😊",
    ];

    print('=== Habit Generation from Mood Text Examples ===\n');

    for (final moodText in moodTexts) {
      print('User Input: "$moodText"');
      
      // Generate habit suggestion based on mood text
      final result = await _aiAgent.generateHabitFromMoodText(moodText);
      
      if (result.containsKey('error')) {
        print('Error: ${result['error']}');
      } else {
        final moodAnalysis = result['moodAnalysis'];
        final habitSuggestion = result['habitSuggestion'];
        final processingMessage = result['processingMessage'];
        
        print('Detected Mood: ${moodAnalysis['detectedMood']}');
        print('Processing Message: $processingMessage');
        print('Habit Suggestion: ${habitSuggestion['suggestion']}');
        print('Category: ${habitSuggestion['category']}');
        print('Duration: ${habitSuggestion['estimatedDuration']}');
        print('Difficulty: ${habitSuggestion['difficulty']}');
      }
      
      print('---\n');
    }
  }

  /// Example 3: Test different emotion keywords
  Future<void> testEmotionKeywordsExample() async {
    final Map<String, String> testCases = {
      'Happy Keywords': 'I am so happy and joyful today! 😊😄',
      'Stressed Keywords': 'I feel anxious, worried, and overwhelmed 😰',
      'Tired Keywords': 'I am exhausted, fatigued, and sleepy 😴',
      'Energized Keywords': 'I feel motivated, pumped, and dynamic! ⚡🔥',
      'Mixed Emotions': 'I am happy but also a bit stressed about work',
      'No Clear Emotion': 'I went to the store and bought some groceries',
    };

    print('=== Emotion Keywords Testing ===\n');

    for (final entry in testCases.entries) {
      print('Test Case: ${entry.key}');
      print('Input: "${entry.value}"');
      
      final analysis = await _aiAgent.analyzeMoodFromText(entry.value);
      
      print('Result: ${analysis['detectedMood']} (${(analysis['confidence'] * 100).toStringAsFixed(1)}% confidence)');
      print('Keywords Found: ${analysis['keywordAnalysis']['foundKeywords']}');
      print('---\n');
    }
  }

  /// Run all examples
  Future<void> runAllExamples() async {
    await analyzeMoodExample();
    await generateHabitFromMoodExample();
    await testEmotionKeywordsExample();
  }
}

/// Main function to run the examples
void main() async {
  // Initialize Flutter bindings to fix SharedPreferences issue
  WidgetsFlutterBinding.ensureInitialized();
  
  final example = MoodAnalysisExample();
  await example.runAllExamples();
}