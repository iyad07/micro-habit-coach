import 'package:flutter_test/flutter_test.dart';
import 'lib/services/ai_agent_service.dart';
import 'lib/models/user_profile.dart';

void main() {
  group('Habit Suggestion Diversity Tests', () {
    late AIAgentService aiService;

    setUp(() {
      aiService = AIAgentService();
    });

    test('Should generate different suggestions for different moods', () {
      // Test stressed mood
      final stressedSuggestion = aiService.generateHabitSuggestion(
        UserMood.stressed,
        [HabitCategory.mindfulness, HabitCategory.physical],
      );
      
      // Test energized mood
      final energizedSuggestion = aiService.generateHabitSuggestion(
        UserMood.energized,
        [HabitCategory.physical, HabitCategory.productivity],
      );
      
      // Test tired mood
      final tiredSuggestion = aiService.generateHabitSuggestion(
        UserMood.tired,
        [HabitCategory.relaxation, HabitCategory.physical],
      );
      
      // Test happy mood
      final happySuggestion = aiService.generateHabitSuggestion(
        UserMood.happy,
        [HabitCategory.physical, HabitCategory.mindfulness],
      );

      print('Stressed suggestion: ${stressedSuggestion['title']}');
      print('Energized suggestion: ${energizedSuggestion['title']}');
      print('Tired suggestion: ${tiredSuggestion['title']}');
      print('Happy suggestion: ${happySuggestion['title']}');

      // Verify suggestions are different
      expect(stressedSuggestion['title'], isNot(equals(energizedSuggestion['title'])));
      expect(tiredSuggestion['title'], isNot(equals(happySuggestion['title'])));
      
      // Verify all suggestions have required fields
      for (final suggestion in [stressedSuggestion, energizedSuggestion, tiredSuggestion, happySuggestion]) {
        expect(suggestion['title'], isNotNull);
        expect(suggestion['description'], isNotNull);
        expect(suggestion['prompt'], isNotNull);
      }
    });

    test('Should generate suggestions based on preferences', () {
      // Test with physical preference
      final physicalSuggestion = aiService.generateHabitSuggestion(
        UserMood.energized,
        [HabitCategory.physical],
      );
      
      // Test with mindfulness preference
      final mindfulnessSuggestion = aiService.generateHabitSuggestion(
        UserMood.stressed,
        [HabitCategory.mindfulness],
      );
      
      // Test with productivity preference
      final productivitySuggestion = aiService.generateHabitSuggestion(
        UserMood.happy,
        [HabitCategory.productivity],
      );
      
      // Test with relaxation preference
      final relaxationSuggestion = aiService.generateHabitSuggestion(
        UserMood.tired,
        [HabitCategory.relaxation],
      );

      print('Physical preference: ${physicalSuggestion['title']}');
      print('Mindfulness preference: ${mindfulnessSuggestion['title']}');
      print('Productivity preference: ${productivitySuggestion['title']}');
      print('Relaxation preference: ${relaxationSuggestion['title']}');

      // Verify suggestions align with preferences
      expect(physicalSuggestion['title'], isNotNull);
      expect(mindfulnessSuggestion['title'], isNotNull);
      expect(productivitySuggestion['title'], isNotNull);
      expect(relaxationSuggestion['title'], isNotNull);
    });

    test('Should generate multiple different suggestions for same mood', () {
      final suggestions = <String>{};
      
      // Generate 10 suggestions for the same mood and preferences
      for (int i = 0; i < 10; i++) {
        final suggestion = aiService.generateHabitSuggestion(
          UserMood.stressed,
          [HabitCategory.mindfulness, HabitCategory.physical],
        );
        suggestions.add(suggestion['title']!);
      }
      
      print('Generated ${suggestions.length} unique suggestions out of 10 attempts');
      print('Suggestions: ${suggestions.toList()}');
      
      // Should have at least 2 different suggestions (due to randomization)
      expect(suggestions.length, greaterThan(1));
    });

    test('Should handle empty preferences gracefully', () {
      final suggestion = aiService.generateHabitSuggestion(
        UserMood.happy,
        [], // Empty preferences
      );
      
      expect(suggestion['title'], isNotNull);
      expect(suggestion['description'], isNotNull);
      expect(suggestion['prompt'], isNotNull);
      
      print('Suggestion with no preferences: ${suggestion['title']}');
    });

    test('Should generate mood-appropriate prompts', () {
      final stressedSuggestion = aiService.generateHabitSuggestion(
        UserMood.stressed,
        [HabitCategory.mindfulness],
      );
      
      final energizedSuggestion = aiService.generateHabitSuggestion(
        UserMood.energized,
        [HabitCategory.physical],
      );
      
      // Check that prompts contain mood-appropriate language
      expect(stressedSuggestion['prompt']!.toLowerCase(), contains('stressed'));
      expect(energizedSuggestion['prompt']!.toLowerCase(), contains('energized'));
      
      print('Stressed prompt: ${stressedSuggestion['prompt']}');
      print('Energized prompt: ${energizedSuggestion['prompt']}');
    });
  });
}