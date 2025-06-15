import 'package:flutter/material.dart';
import 'package:micro_habit_tracker/models/habit.dart';
import '../services/ai_agent_service.dart';
import '../models/user_profile.dart';

/// Example demonstrating how to use the screen time functionality
class ScreenTimeUsageExample {
  static final AIAgentService _aiAgent = AIAgentService();

  /// Example 1: Check screen time support and permissions
  static Future<void> checkScreenTimeSupport() async {
    print('=== Screen Time Support Check ===');
    
    // Check if screen time tracking is supported
    final isSupported = _aiAgent.isScreenTimeSupported();
    print('Screen time supported: $isSupported');
    
    if (isSupported) {
      // Check current permissions
      final hasPermissions = await _aiAgent.hasScreenTimePermissions();
      print('Has permissions: $hasPermissions');
      
      if (!hasPermissions) {
        print('Support message: ${_aiAgent.getScreenTimeSupportMessage()}');
        
        // Request permissions (this will open system settings)
        print('Requesting permissions...');
        final granted = await _aiAgent.requestScreenTimePermissions();
        print('Permissions granted: $granted');
      }
    }
  }

  /// Example 2: Get basic screen time analysis
  static Future<void> getBasicScreenTimeAnalysis() async {
    print('\n=== Basic Screen Time Analysis ===');
    
    try {
      final analysis = await _aiAgent.analyzeScreenTimeAndUsage();
      
      print('Screen time hours: ${analysis['screenTimeHours']}');
      print('Screen time level: ${analysis['screenTimeLevel']}');
      print('Recommendation: ${analysis['recommendation']}');
      print('Balance needed: ${analysis['balanceNeeded']}');
      print('Suggested break duration: ${analysis['suggestedBreakDuration']} minutes');
      print('Data source: ${analysis['dataSource']}');
      
      if (analysis['permissionRequired'] == true) {
        print('⚠️ Permission required: ${analysis['supportMessage']}');
      }
      
      // App usage analysis (if available)
      final appUsage = analysis['appUsageAnalysis'];
      if (appUsage != null) {
        print('\nApp Usage Analysis:');
        print('Total apps used: ${appUsage['totalApps']}');
        print('Most used app: ${appUsage['mostUsedApp']}');
        print('Average session: ${appUsage['averageSessionDuration']} minutes');
      }
    } catch (e) {
      print('Error getting screen time analysis: $e');
    }
  }

  /// Example 3: Get comprehensive screen time insights
  static Future<void> getScreenTimeInsights() async {
    print('\n=== Screen Time Insights ===');
    
    try {
      final insights = await _aiAgent.getScreenTimeInsights();
      
      final analysis = insights['analysis'];
      final recommendations = insights['recommendations'] as List;
      final habitSuggestions = insights['habitSuggestions'] as List;
      
      print('Total screen time: ${analysis['totalHours']} hours');
      print('Category: ${analysis['category']}');
      
      print('\nRecommendations:');
      for (final rec in recommendations) {
        print('  • $rec');
      }
      
      print('\nHabit suggestions:');
      for (final habit in habitSuggestions) {
        print('  • $habit');
      }
      
      // Top apps
      final topApps = analysis['topApps'] as List;
      if (topApps.isNotEmpty) {
        print('\nTop apps:');
        for (final app in topApps) {
          print('  • ${app['name']}: ${app['hours'].toStringAsFixed(1)}h');
        }
      }
    } catch (e) {
      print('Error getting screen time insights: $e');
    }
  }

  /// Example 4: Generate smart habit suggestions with screen time integration
  static Future<void> generateSmartHabitSuggestions() async {
    print('\n=== Smart Habit Suggestions ===');
    
    try {
      final suggestion = await _aiAgent.generateSmartHabitSuggestion(
        mood: UserMood.stressed,
        preferences: [HabitCategory.mindfulness, HabitCategory.physical],
        currentStreak: 3,
      );
      
      print('Suggested habit: ${suggestion['suggestion']}');
      print('Reasoning: ${suggestion['reasoning']}');
      print('Difficulty: ${suggestion['difficulty']}');
      print('Estimated duration: ${suggestion['estimatedDuration']} minutes');
      
      // Screen time influence
      final screenTimeAnalysis = suggestion['screenTimeAnalysis'];
      if (screenTimeAnalysis != null) {
        print('\nScreen time influence:');
        print('  Current usage: ${screenTimeAnalysis['screenTimeHours']}h');
        print('  Level: ${screenTimeAnalysis['screenTimeLevel']}');
        print('  Balance needed: ${screenTimeAnalysis['balanceNeeded']}');
      }
    } catch (e) {
      print('Error generating smart habit suggestions: $e');
    }
  }

  /// Example 5: Manual screen time data input (for testing or unsupported platforms)
  static Future<void> manualScreenTimeInput() async {
    print('\n=== Manual Screen Time Input ===');
    
    // Simulate manual input of screen time data
    final manualScreenTime = 5.5; // 5.5 hours
    final manualAppUsage = {
      'com.instagram.android': 2.0,
      'com.twitter.android': 1.5,
      'com.google.android.youtube': 1.0,
      'com.whatsapp': 0.8,
      'com.spotify.music': 0.2,
    };
    
    try {
      final analysis = await _aiAgent.analyzeScreenTimeAndUsage(
        manualScreenTime,
        manualAppUsage,
      );
      
      print('Manual analysis results:');
      print('Screen time: ${analysis['screenTimeHours']}h');
      print('Level: ${analysis['screenTimeLevel']}');
      print('Recommendation: ${analysis['recommendation']}');
      print('Data source: ${analysis['dataSource']}');
      
      final appAnalysis = analysis['appUsageAnalysis'];
      if (appAnalysis != null) {
        print('\nApp analysis:');
        print('Most used: ${appAnalysis['mostUsedApp']}');
        print('Social media time: ${appAnalysis['socialMediaTime']}h');
      }
    } catch (e) {
      print('Error with manual screen time input: $e');
    }
  }

  /// Example 6: Complete workflow demonstration
  static Future<void> completeWorkflowDemo() async {
    print('\n=== Complete Workflow Demo ===');
    
    // Step 1: Check support and permissions
    await checkScreenTimeSupport();
    
    // Step 2: Get current screen time data
    await getBasicScreenTimeAnalysis();
    
    // Step 3: Get insights and recommendations
    await getScreenTimeInsights();
    
    // Step 4: Generate smart habit suggestions
    await generateSmartHabitSuggestions();
    
    // Step 5: Demonstrate manual input (fallback)
    await manualScreenTimeInput();
    
    print('\n=== Demo Complete ===');
  }
}

/// Widget example showing how to integrate screen time in UI
class ScreenTimeExampleWidget extends StatefulWidget {
  const ScreenTimeExampleWidget({super.key});

  @override
  State<ScreenTimeExampleWidget> createState() => _ScreenTimeExampleWidgetState();
}

class _ScreenTimeExampleWidgetState extends State<ScreenTimeExampleWidget> {
  final AIAgentService _aiAgent = AIAgentService();
  Map<String, dynamic>? _screenTimeData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadScreenTimeData();
  }

  Future<void> _loadScreenTimeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _aiAgent.analyzeScreenTimeAndUsage();
      setState(() {
        _screenTimeData = data;
      });
    } catch (e) {
      print('Error loading screen time data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Screen Time Integration Example',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_screenTimeData != null)
              _buildScreenTimeDisplay()
            else
              const Text('No screen time data available'),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _loadScreenTimeData,
              child: const Text('Refresh Screen Time Data'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () async {
                await ScreenTimeUsageExample.completeWorkflowDemo();
              },
              child: const Text('Run Complete Demo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeDisplay() {
    final data = _screenTimeData!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screen Time: ${data['screenTimeHours']}h',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Level: ${data['screenTimeLevel']}'),
            Text('Balance needed: ${data['balanceNeeded']}'),
            Text('Data source: ${data['dataSource']}'),
            const SizedBox(height: 8),
            Text(
              'Recommendation: ${data['recommendation']}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}