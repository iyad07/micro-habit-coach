import 'package:flutter/material.dart';
import '../lib/models/user_mood.dart';
import '../lib/models/habit_category.dart';
import '../lib/services/ai_agent_service.dart';
import '../lib/services/storage_service.dart';
import '../lib/services/screen_time_service.dart';

/// Demonstration of the AI-powered habit suggestion system
/// This example shows how to integrate mood analysis, screen time data, and user preferences
/// to generate personalized habit suggestions using Novita AI
class AIHabitSuggestionDemo {
  late final AIAgentService _aiAgentService;
  
  AIHabitSuggestionDemo() {
    final storageService = StorageService();
    final screenTimeService = ScreenTimeService();
    _aiAgentService = AIAgentService(storageService, screenTimeService);
  }
  
  /// Example 1: Generate AI-powered suggestion from mood text
  Future<void> demonstrateAIMoodBasedSuggestion() async {
    print('=== AI-Powered Mood-Based Habit Suggestion Demo ===\n');
    
    // Example user inputs
    final examples = [
      {
        'moodText': 'I\'m feeling really stressed today with work deadlines',
        'preferences': [HabitCategory.mindfulness, HabitCategory.relaxation],
        'screenTimeHours': 6.5,
        'currentStreak': 3,
      },
      {
        'moodText': 'I\'m so energized and motivated to get things done!',
        'preferences': [HabitCategory.physical, HabitCategory.productivity],
        'screenTimeHours': 2.0,
        'currentStreak': 7,
      },
      {
        'moodText': 'Feeling tired and drained after a long day',
        'preferences': [HabitCategory.relaxation, HabitCategory.mindfulness],
        'screenTimeHours': 4.0,
        'currentStreak': 1,
      },
    ];
    
    for (int i = 0; i < examples.length; i++) {
      final example = examples[i];
      print('Example ${i + 1}:');
      print('Mood Text: "${example['moodText']}"');
      print('Preferences: ${(example['preferences'] as List<HabitCategory>).map((p) => p.name).join(', ')}');
      print('Screen Time: ${example['screenTimeHours']} hours');
      print('Current Streak: ${example['currentStreak']} days\n');
      
      try {
        final result = await _aiAgentService.generateAIPersonalizedHabitSuggestion(
          moodText: example['moodText'] as String,
          preferences: example['preferences'] as List<HabitCategory>,
          screenTimeHours: example['screenTimeHours'] as double,
          currentStreak: example['currentStreak'] as int,
        );
        
        if (result['success'] == true) {
          final suggestion = result['suggestion'] as Map<String, dynamic>;
          final moodAnalysis = result['moodAnalysis'] as Map<String, dynamic>;
          final screenAnalysis = result['screenTimeAnalysis'] as Map<String, dynamic>?;
          
          print('🎯 AI SUGGESTION:');
          print('Title: ${suggestion['title']}');
          print('Description: ${suggestion['description']}');
          print('Duration: ${suggestion['duration']} minutes');
          print('Category: ${suggestion['category']}');
          print('Difficulty: ${suggestion['difficulty']}');
          print('\n💡 AI REASONING:');
          print('${suggestion['reasoning']}');
          print('\n🎉 MOTIVATION:');
          print('${suggestion['motivation']}');
          print('\n📊 ANALYSIS:');
          print('Detected Mood: ${moodAnalysis['mood']} (${(moodAnalysis['confidence'] * 100).toStringAsFixed(1)}% confidence)');
          if (screenAnalysis != null) {
            print('Screen Time Category: ${screenAnalysis['category']}');
            print('Screen Time Recommendation: ${screenAnalysis['recommendation']}');
          }
          print('\n💪 TIPS:');
          final tips = suggestion['tips'] as List<dynamic>;
          for (int j = 0; j < tips.length; j++) {
            print('${j + 1}. ${tips[j]}');
          }
        } else {
          print('❌ Failed to generate AI suggestion');
        }
      } catch (e) {
        print('❌ Error: $e');
      }
      
      print('\n' + '=' * 60 + '\n');
    }
  }
  
  /// Example 2: Compare AI vs Standard suggestions
  Future<void> compareAIvsStandardSuggestions() async {
    print('=== AI vs Standard Suggestion Comparison ===\n');
    
    final moodText = 'I\'ve been staring at my computer screen all day and feeling overwhelmed';
    final preferences = [HabitCategory.mindfulness, HabitCategory.physical];
    final screenTimeHours = 8.0;
    final currentStreak = 5;
    
    print('User Input:');
    print('Mood: "$moodText"');
    print('Preferences: ${preferences.map((p) => p.name).join(', ')}');
    print('Screen Time: $screenTimeHours hours');
    print('Current Streak: $currentStreak days\n');
    
    try {
      // Generate AI-powered suggestion
      print('🤖 AI-POWERED SUGGESTION:');
      final aiResult = await _aiAgentService.generateAIPersonalizedHabitSuggestion(
        moodText: moodText,
        preferences: preferences,
        screenTimeHours: screenTimeHours,
        currentStreak: currentStreak,
      );
      
      if (aiResult['success'] == true) {
        final aiSuggestion = aiResult['suggestion'] as Map<String, dynamic>;
        print('${aiSuggestion['title']} (${aiSuggestion['duration']} min)');
        print('${aiSuggestion['description']}');
        print('Reasoning: ${aiSuggestion['reasoning']}');
        print('Source: ${aiSuggestion['source']}\n');
      }
      
      // Generate standard suggestion for comparison
      print('📋 STANDARD SUGGESTION:');
      final standardResult = await _aiAgentService.generateSmartHabitSuggestion(
        mood: UserMood.stressed, // Manually determined mood
        preferences: preferences,
        currentStreak: currentStreak,
      );
      
      final standardSuggestion = standardResult['suggestion'] as Map<String, dynamic>;
      print('${standardSuggestion['title']} (${standardSuggestion['duration']} min)');
      print('${standardSuggestion['description']}');
      print('Reasoning: ${standardSuggestion['reasoning']}');
      print('Source: Standard algorithm\n');
      
      print('🔍 KEY DIFFERENCES:');
      print('• AI considers natural language mood input vs predefined enum');
      print('• AI provides contextual reasoning based on comprehensive analysis');
      print('• AI adapts suggestions based on screen time patterns');
      print('• AI learns from user behavior patterns over time');
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
  
  /// Example 3: Screen time integration scenarios
  Future<void> demonstrateScreenTimeIntegration() async {
    print('=== Screen Time Integration Scenarios ===\n');
    
    final scenarios = [
      {
        'name': 'High Screen Time + Stress',
        'moodText': 'Feeling stressed and my eyes are tired from too much screen time',
        'screenTimeHours': 9.0,
        'preferences': [HabitCategory.relaxation],
      },
      {
        'name': 'Moderate Screen Time + Energy',
        'moodText': 'I\'m feeling energetic and ready to be productive',
        'screenTimeHours': 4.0,
        'preferences': [HabitCategory.productivity],
      },
      {
        'name': 'Low Screen Time + Happy',
        'moodText': 'Having a great day and feeling positive!',
        'screenTimeHours': 1.5,
        'preferences': [HabitCategory.physical, HabitCategory.mindfulness],
      },
    ];
    
    for (final scenario in scenarios) {
      print('📱 SCENARIO: ${scenario['name']}');
      print('Mood: "${scenario['moodText']}"');
      print('Screen Time: ${scenario['screenTimeHours']} hours\n');
      
      try {
        final result = await _aiAgentService.generateAIPersonalizedHabitSuggestion(
          moodText: scenario['moodText'] as String,
          preferences: scenario['preferences'] as List<HabitCategory>,
          screenTimeHours: scenario['screenTimeHours'] as double,
          currentStreak: 3,
        );
        
        if (result['success'] == true) {
          final suggestion = result['suggestion'] as Map<String, dynamic>;
          final screenAnalysis = result['screenTimeAnalysis'] as Map<String, dynamic>?;
          
          print('🎯 Suggested Habit: ${suggestion['title']}');
          print('📝 Description: ${suggestion['description']}');
          print('⏱️ Duration: ${suggestion['duration']} minutes');
          print('🎨 Category: ${suggestion['category']}');
          print('💡 AI Reasoning: ${suggestion['reasoning']}');
          
          if (screenAnalysis != null) {
            print('📊 Screen Time Analysis:');
            print('   Category: ${screenAnalysis['category']}');
            print('   Recommendation: ${screenAnalysis['recommendation']}');
          }
        }
      } catch (e) {
        print('❌ Error: $e');
      }
      
      print('\n' + '-' * 50 + '\n');
    }
  }
  
  /// Example 4: Behavioral learning demonstration
  Future<void> demonstrateBehavioralLearning() async {
    print('=== Behavioral Learning & Personalization Demo ===\n');
    
    // Simulate user with different experience levels
    final userProfiles = [
      {
        'name': 'New User (Learning Phase)',
        'currentStreak': 1,
        'recentCompletions': {'mindfulness': 1, 'physical': 0},
        'description': 'Just started their habit journey',
      },
      {
        'name': 'Intermediate User',
        'currentStreak': 15,
        'recentCompletions': {'mindfulness': 8, 'physical': 5, 'productivity': 2},
        'description': 'Building consistent habits',
      },
      {
        'name': 'Advanced User',
        'currentStreak': 45,
        'recentCompletions': {'mindfulness': 20, 'physical': 15, 'productivity': 10},
        'description': 'Habit master seeking new challenges',
      },
    ];
    
    final moodText = 'Feeling motivated and ready for a challenge';
    final preferences = [HabitCategory.physical, HabitCategory.productivity];
    
    for (final profile in userProfiles) {
      print('👤 USER PROFILE: ${profile['name']}');
      print('Description: ${profile['description']}');
      print('Current Streak: ${profile['currentStreak']} days');
      print('Recent Completions: ${profile['recentCompletions']}\n');
      
      try {
        final result = await _aiAgentService.generateAIPersonalizedHabitSuggestion(
          moodText: moodText,
          preferences: preferences,
          screenTimeHours: 3.0,
          currentStreak: profile['currentStreak'] as int,
          recentCompletions: Map<String, int>.from(profile['recentCompletions'] as Map),
        );
        
        if (result['success'] == true) {
          final suggestion = result['suggestion'] as Map<String, dynamic>;
          final personalizationFactors = result['personalizationFactors'] as Map<String, dynamic>;
          
          print('🎯 Personalized Suggestion:');
          print('Title: ${suggestion['title']}');
          print('Duration: ${suggestion['duration']} minutes');
          print('Difficulty: ${suggestion['difficulty']}');
          print('Reasoning: ${suggestion['reasoning']}');
          
          print('\n🧠 Personalization Factors:');
          print('Learning Phase: ${personalizationFactors['learningPhase']}');
          print('Streak Level: ${personalizationFactors['streak']} days');
          
          if (suggestion.containsKey('completionPrediction')) {
            print('Completion Prediction: ${suggestion['completionPrediction']}');
          }
        }
      } catch (e) {
        print('❌ Error: $e');
      }
      
      print('\n' + '-' * 50 + '\n');
    }
  }
  
  /// Run all demonstrations
  Future<void> runAllDemos() async {
    print('🚀 Starting AI Habit Suggestion System Demonstration\n');
    print('This demo showcases how Novita AI integrates with mood analysis,');
    print('screen time data, and user preferences to generate personalized');
    print('habit suggestions that adapt to user behavior over time.\n');
    print('=' * 70 + '\n');
    
    await demonstrateAIMoodBasedSuggestion();
    await compareAIvsStandardSuggestions();
    await demonstrateScreenTimeIntegration();
    await demonstrateBehavioralLearning();
    
    print('✅ All demonstrations completed!');
    print('\nThe AI system successfully demonstrates:');
    print('• Natural language mood analysis using Novita AI');
    print('• Screen time integration for digital wellness');
    print('• User preference consideration and filtering');
    print('• Behavioral pattern learning and adaptation');
    print('• Personalized difficulty and progression');
    print('• Contextual reasoning and motivation');
  }
}

/// Example usage in a Flutter app
class AIHabitSuggestionWidget extends StatefulWidget {
  @override
  _AIHabitSuggestionWidgetState createState() => _AIHabitSuggestionWidgetState();
}

class _AIHabitSuggestionWidgetState extends State<AIHabitSuggestionWidget> {
  final AIHabitSuggestionDemo _demo = AIHabitSuggestionDemo();
  bool _isLoading = false;
  Map<String, dynamic>? _lastSuggestion;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Habit Suggestions'),
        backgroundColor: Colors.blue[600],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI-Powered Habit Suggestions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Get personalized habit suggestions based on your mood, screen time, and preferences using advanced AI.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _runDemo,
              child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Generate AI Suggestion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            
            SizedBox(height: 24),
            
            if (_lastSuggestion != null) ..._buildSuggestionDisplay(),
          ],
        ),
      ),
    );
  }
  
  Future<void> _runDemo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Run the demo in console
      await _demo.runAllDemos();
      
      // Show a sample suggestion in the UI
      setState(() {
        _lastSuggestion = {
          'title': 'Digital Detox Walk',
          'description': 'Take a 10-minute walk without your phone to reduce stress and screen fatigue',
          'duration': '10',
          'category': 'physical',
          'reasoning': 'High screen time and stress detected - offline movement will help reset both',
          'motivation': 'Fresh air and movement are exactly what you need right now!',
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<Widget> _buildSuggestionDisplay() {
    final suggestion = _lastSuggestion!;
    
    return [
      Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'AI Suggestion',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              Text(
                suggestion['title'],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              
              Text(
                suggestion['description'],
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              
              Row(
                children: [
                  Chip(
                    label: Text('${suggestion['duration']} min'),
                    backgroundColor: Colors.blue[100],
                  ),
                  SizedBox(width: 8),
                  Chip(
                    label: Text(suggestion['category']),
                    backgroundColor: Colors.green[100],
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              Text(
                '💡 ${suggestion['reasoning']}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 8),
              
              Text(
                '🎉 ${suggestion['motivation']}',
                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Main function to run the demo
void main() async {
  // Run console demo
  final demo = AIHabitSuggestionDemo();
  await demo.runAllDemos();
  
  // Or run Flutter app
  // runApp(MaterialApp(
  //   home: AIHabitSuggestionWidget(),
  //   title: 'AI Habit Suggestions Demo',
  // ));
}