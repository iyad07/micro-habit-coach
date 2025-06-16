import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:micro_habit_tracker/models/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/habit.dart';
import '../providers/app_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/progress_widget.dart';
import '../widgets/mood_selector.dart';
import '../widgets/screen_time_widget.dart';

import '../services/ai_agent_service.dart';
import 'settings_screen.dart';
import '../utils/font_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  bool _showMoodSelector = false;
  bool _isCompletingHabit = false;
  bool _isGeneratingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _completeHabit(String habitId) async {
    setState(() {
      _isCompletingHabit = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.completeHabit(habitId);
      
      // Show success animation
      _fabController.forward().then((_) {
        _fabController.reverse();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Habit completed! 🎉',
                  style: FontHelper.poppins(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing habit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingHabit = false;
        });
      }
    }
  }

  Future<void> _generateNewSuggestion() async {
    setState(() {
      _isGeneratingSuggestion = true;
    });
    
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.generateHabitSuggestion();
    } finally {
      setState(() {
        _isGeneratingSuggestion = false;
      });
    }
  }

  Future<void> _acceptSuggestion() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.acceptHabitSuggestion();
  }

  void _toggleMoodSelector() {
    setState(() {
      _showMoodSelector = !_showMoodSelector;
    });
  }

  Future<void> _updateMood(UserMood mood) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.updateMood(mood);
    setState(() {
      _showMoodSelector = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      final userProfile = appProvider.userProfile;
      final todaysHabit = appProvider.todaysHabit;
      final currentSuggestion = appProvider.currentSuggestion;

      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            userProfile != null ? 'Hello, ${userProfile.name}!' : 'Micro-Habit Tracker',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => kIsWeb
                        ? Scaffold(
                            backgroundColor: const Color(0xFF0F0F23),
                            body: Center(
                              child: Container(
                                width: 400,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const SettingsScreen(),
                              ),
                            ),
                          )
                        : const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings, color: Colors.white),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await appProvider.initialize();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced greeting section with quick actions
                _buildEnhancedGreetingSection(userProfile),
                const SizedBox(height: 16),
                
                // Today's focus section (most important)
                if (todaysHabit != null) ...[
                  _buildTodaysFocusSection(todaysHabit),
                  const SizedBox(height: 24),
                ] else if (currentSuggestion != null) ...[
                  _buildAISuggestionFocusSection(currentSuggestion),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildGetStartedSection(),
                  const SizedBox(height: 24),
                ],

                // Quick Stats Dashboard
                _buildQuickStatsSection(),
                const SizedBox(height: 24),

                // Digital Wellness Insights
          _buildDigitalWellnessSection(),
          const SizedBox(height: 24),

          // AI Insights
          _buildAIInsightsSection(),
          const SizedBox(height: 24),

          // Habit Journey
          _buildHabitJourneySection(),
                
                // Bottom spacing for FAB
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      );
    });
  }

  Widget _buildEnhancedGreetingSection(UserProfile? userProfile) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    String motivationalMessage;
    
    if (hour < 12) {
      greeting = 'Good morning';
      motivationalMessage = 'Start your day with intention! 🌅';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      motivationalMessage = 'Keep the momentum going! ⚡';
    } else {
      greeting = 'Good evening';
      motivationalMessage = 'Reflect and recharge! 🌙';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    if (userProfile != null)
                      Text(
                        userProfile.name,
                        style: FontHelper.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      motivationalMessage,
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: _toggleMoodSelector,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userProfile?.currentMood?.emoji ?? '😊',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userProfile?.currentMood?.displayName ?? 'Set Mood',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_showMoodSelector) ...[
            const SizedBox(height: 20),
            MoodSelector(
              selectedMood: userProfile?.currentMood,
              onMoodSelected: _updateMood,
              compact: true,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600)).slideY(begin: -0.2, end: 0);
  }

  Widget _buildTodaysFocusSection(Habit habit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            habit.isCompletedToday 
                ? const Color(0xFF4CAF50).withOpacity(0.2)
                : const Color(0xFFFF6B35).withOpacity(0.2),
            habit.isCompletedToday 
                ? const Color(0xFF4CAF50).withOpacity(0.05)
                : const Color(0xFFFF6B35).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: habit.isCompletedToday 
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFFFF6B35).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: habit.isCompletedToday 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  habit.isCompletedToday ? Icons.check_circle : Icons.today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.isCompletedToday ? 'Completed Today! 🎉' : 'Today\'s Focus',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      habit.isCompletedToday 
                          ? 'Great job! Keep the momentum going.'
                          : 'Your micro-habit for today',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HabitCard(
            habit: habit,
            isCompleted: habit.isCompletedToday,
            onComplete: () => _completeHabit(habit.id),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideX(begin: -0.1, end: 0);
  }

  Widget _buildAISuggestionFocusSection(Map<String, String> suggestion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.2),
            const Color(0xFF6C63FF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Suggestion Ready! ✨',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Personalized just for you',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HabitSuggestionCard(
            title: suggestion['title'] ?? 'New Habit Suggestion',
            description: suggestion['description'] ?? 'A personalized habit suggestion for you.',
            category: HabitCategory.values.firstWhere(
              (cat) => cat.displayName == suggestion['category'],
              orElse: () => HabitCategory.mindfulness,
            ),
            durationMinutes: int.tryParse(suggestion['duration'] ?? '5') ?? 5,
            reasoning: suggestion['reasoning'],
            onAccept: _acceptSuggestion,
            onReject: _generateNewSuggestion,
            isGenerating: _isGeneratingSuggestion,
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 300)).slideX(begin: 0.1, end: 0);
  }

  Widget _buildGetStartedSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.psychology,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ready to start your journey?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI will analyze your mood and preferences to suggest the perfect micro-habit for you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGeneratingSuggestion ? null : _generateNewSuggestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isGeneratingSuggestion
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analyzing your preferences...',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Get My AI Suggestion',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 400)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
   }

  Widget _buildQuickStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Stats',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<AppProvider>(
             builder: (context, appProvider, child) {
               final stats = {
                 'currentStreak': appProvider.habits.where((h) => h.isCompletedToday).length,
                 'weeklyCompletion': appProvider.habits.isNotEmpty ? 
                   (appProvider.habits.where((h) => h.isCompletedToday).length / appProvider.habits.length * 100).round() : 0,
                 'totalHabits': appProvider.habits.length,
               };
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Current Streak',
                      '${stats['currentStreak']}',
                      'days',
                      Icons.local_fire_department,
                      const Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'This Week',
                      '${stats['weeklyCompletion']}',
                      '%',
                      Icons.calendar_today,
                      const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Habits',
                      '${stats['totalHabits']}',
                      'habits',
                      Icons.check_circle,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 500)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalWellnessSection() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return FutureBuilder<double>(
      future: appProvider.appUsageService.getTodayScreenTime(),
          builder: (context, snapshot) {
             final totalHours = snapshot.data ?? 0.0;
            //final totalHours = screenTimeData['totalHours'] as double;
            final isHealthy = totalHours < 6.0; // Healthy threshold
            
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isHealthy 
                        ? const Color(0xFF4CAF50).withOpacity(0.15)
                        : const Color(0xFFFF9800).withOpacity(0.15),
                    isHealthy 
                        ? const Color(0xFF4CAF50).withOpacity(0.05)
                        : const Color(0xFFFF9800).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHealthy 
                      ? const Color(0xFF4CAF50).withOpacity(0.3)
                      : const Color(0xFFFF9800).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isHealthy ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isHealthy ? Icons.phone_android : Icons.warning,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digital Wellness',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isHealthy ? 'Great balance today!' : 'Consider taking a break',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Screen Time Today',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalHours.toStringAsFixed(1)}h',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: (totalHours / 12).clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isHealthy ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isHealthy 
                                  ? 'Healthy usage 👍'
                                  : 'Consider a digital detox 📱',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isHealthy) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF6C63FF),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Try a 5-minute mindfulness break!',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ).animate().fadeIn(delay: const Duration(milliseconds: 600)).slideX(begin: 0.1, end: 0);
      }
  

  Widget _buildAIInsightsSection() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withOpacity(0.15),
                const Color(0xFF6C63FF).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Insights',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                   final insights = _generateInsights(appProvider);
                  return Column(
                    children: insights.map((insight) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              insight['icon'] as IconData,
                              color: insight['color'] as Color,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    insight['title'] as String,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    insight['description'] as String,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: const Duration(milliseconds: 700)).slideY(begin: 0.1, end: 0);
      },
    );
  }

  List<Map<String, dynamic>> _generateInsights(AppProvider appProvider) {
    final currentStreak = appProvider.habits.where((h) => h.isCompletedToday).length;
    final weeklyCompletion = appProvider.habits.isNotEmpty
        ? (appProvider.habits.where((h) => h.isCompletedToday).length / appProvider.habits.length * 100).round() : 0;
    final insights = <Map<String, dynamic>>[];
    
    // Streak insight
    if (currentStreak >= 7) {
      insights.add({
        'icon': Icons.local_fire_department,
        'color': const Color(0xFFFF6B35),
        'title': 'Amazing Streak! 🔥',
        'description': 'You\'ve maintained a $currentStreak-day streak. You\'re building incredible momentum!',
      });
    } else if (currentStreak >= 3) {
      insights.add({
        'icon': Icons.trending_up,
        'color': const Color(0xFF4CAF50),
        'title': 'Building Momentum',
        'description': 'Great progress with your $currentStreak-day streak. Keep it up!',
      });
    } else {
      insights.add({
        'icon': Icons.rocket_launch,
        'color': const Color(0xFF6C63FF),
        'title': 'Fresh Start',
        'description': 'Every expert was once a beginner. Your journey starts now!',
      });
    }
    
    // Weekly completion insight
    if (weeklyCompletion >= 80) {
      insights.add({
        'icon': Icons.star,
        'color': const Color(0xFFFFD700),
        'title': 'Weekly Champion',
        'description': '$weeklyCompletion% completion this week. You\'re absolutely crushing it!',
      });
    } else if (weeklyCompletion >= 50) {
      insights.add({
        'icon': Icons.thumb_up,
        'color': const Color(0xFF4CAF50),
        'title': 'Solid Progress',
        'description': '$weeklyCompletion% completion this week. You\'re on the right track!',
      });
    }
    
    // Motivational insight
    insights.add({
      'icon': Icons.lightbulb,
      'color': const Color(0xFF00BCD4),
      'title': 'Pro Tip',
      'description': 'Consistency beats perfection. Small daily actions create lasting change.',
    });
    
    return insights;
  }

  Widget _buildHabitJourneySection() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
         final recentHabits = appProvider.habits
            .where((habit) => habit.completedDates.isNotEmpty)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        if (recentHabits.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.map,
                    size: 48,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Journey Awaits',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your first habit to start building your personal journey map.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 800));
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.timeline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Habit Journey',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentHabits.take(5).length,
                  itemBuilder: (context, index) {
                    final habit = recentHabits[index];
                    final completionRate = habit.completedDates.length / 
                        DateTime.now().difference(habit.createdAt).inDays.clamp(1, double.infinity);
                    
                    return Container(
                      width: 140,
                      height: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: habit.category.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: habit.category.color.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                habit.category.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: habit.category.color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${habit.completedDates.length}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              habit.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: completionRate.clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              habit.category.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(completionRate * 100).toInt()}% completion',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: const Duration(milliseconds: 800)).slideX(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildTodaysHabitSection(Habit habit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Habit',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        HabitCard(
          habit: habit,
          isCompleted: habit.isCompletedToday,
          onComplete: () => _completeHabit(habit.id),
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 600));
  }

  Widget _buildNoHabitSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.psychology,
            size: 48,
            color: Color(0xFF6C63FF),
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to start your journey?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI will analyze your mood and preferences to suggest the perfect micro-habit for you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isGeneratingSuggestion ? null : _generateNewSuggestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isGeneratingSuggestion
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analyzing...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Get AI Suggestion',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 400));
  }

  Widget _buildRecentHabitsSection(List<Habit> habits) {
    if (habits.isEmpty) return const SizedBox.shrink();

    // Sort habits by createdAt in descending order (latest first)
    final sortedHabits = List<Habit>.from(habits)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Habits',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedHabits.take(3).map((habit) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HabitCard(
            habit: habit,
            isCompleted: habit.isCompletedToday,
            onComplete: () => _completeHabit(habit.id),

            compact: true,
          ),
        )),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 800));
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
      ),
      child: FloatingActionButton(
        onPressed: _generateNewSuggestion,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }}