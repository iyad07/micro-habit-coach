import 'package:flutter/material.dart';
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
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  bool _showMoodSelector = false;
  bool _isCompletingHabit = false;

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
                  style: GoogleFonts.poppins(color: Colors.white),
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
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.generateHabitSuggestion();
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
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                // Greeting and mood section
                _buildGreetingSection(userProfile),
                const SizedBox(height: 20),
                
                // Progress overview
                if (userProfile != null)
                  ProgressWidget(userProfile: userProfile).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),
                
                // Screen time tracking
                const ScreenTimeWidget().animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),
                
                // AI Chat section
                if (currentSuggestion != null) ...[
                  _buildAIChatSection(currentSuggestion),
                  const SizedBox(height: 20),
                ],
                
                // Today's habit section
                if (todaysHabit != null) ...[
                  _buildTodaysHabitSection(todaysHabit),
                  const SizedBox(height: 20),
                ] else if (currentSuggestion == null) ...[
                  _buildNoHabitSection(),
                  const SizedBox(height: 20),
                ],
                
                // Recent habits
                _buildRecentHabitsSection(appProvider.habits),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      );
    });
  }

  Widget _buildGreetingSection(UserProfile? userProfile) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
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
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _toggleMoodSelector,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
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
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildAIChatSection(Map<String, String> suggestion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Suggestion',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        HabitSuggestionCard(
          title: suggestion['title'] ?? 'New Habit Suggestion',
          description: suggestion['description'] ?? 'A personalized habit suggestion for you.',
          category: HabitCategory.values.firstWhere(
            (cat) => cat.displayName == suggestion['category'],
            orElse: () => HabitCategory.mindfulness,
          ),
          durationMinutes: int.tryParse(suggestion['duration'] ?? '5') ?? 5,
          onAccept: _acceptSuggestion,
          onReject: _generateNewSuggestion,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
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
    ).animate().fadeIn(delay: 600.ms);
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
            'Ready for a new habit?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to get a personalized habit suggestion!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
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
    ).animate().fadeIn(delay: 800.ms);
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
  }
}