import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/habit.dart';
import '../providers/app_provider.dart';
import '../widgets/mood_selector.dart';
import '../widgets/preference_selector.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  
  int _currentPage = 0;
  UserMood? _selectedMood;
  List<HabitCategory> _selectedPreferences = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_nameController.text.trim().isEmpty || _selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all steps'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.completeOnboarding(
        _nameController.text.trim(),
        _selectedMood!,
        _selectedPreferences,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage 
                            ? const Color(0xFF6C63FF) 
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ).animate().fadeIn(duration: 600.ms),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildNamePage(),
                  _buildMoodPage(),
                  _buildPreferencePage(),
                ],
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Text(
                        'Back',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : (
                      _currentPage == 3 ? _completeOnboarding : _nextPage
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _currentPage == 3 ? 'Get Started' : 'Next',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    final aiAgent = Provider.of<AppProvider>(context, listen: false).aiAgent;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.psychology,
            size: 100,
            color: Color(0xFF6C63FF),
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 40),
          
          Text(
            'Welcome to\nMicro-Habit Tracker!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
          
          const SizedBox(height: 20),
          
          Text(
            aiAgent.welcomeMessages.first,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '✨ Build better habits, one micro-step at a time\n🎯 Personalized suggestions based on your mood\n📈 Track your progress and celebrate streaks',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person,
            size: 80,
            color: Color(0xFF6C63FF),
          ).animate().scale(duration: 600.ms),
          
          const SizedBox(height: 40),
          
          Text(
            'What should I call you?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 20),
          
          Text(
            'I\'d love to personalize your experience!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 40),
          
          TextField(
            controller: _nameController,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white54,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildMoodPage() {
    final aiAgent = Provider.of<AppProvider>(context, listen: false).aiAgent;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.mood,
            size: 80,
            color: Color(0xFF6C63FF),
          ).animate().scale(duration: 600.ms),
          
          const SizedBox(height: 40),
          
          Text(
            'How are you feeling today?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 20),
          
          Text(
            aiAgent.moodPrompt,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 40),
          
          MoodSelector(
            selectedMood: _selectedMood,
            onMoodSelected: (mood) {
              setState(() {
                _selectedMood = mood;
              });
            },
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildPreferencePage() {
    final aiAgent = Provider.of<AppProvider>(context, listen: false).aiAgent;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite,
            size: 80,
            color: Color(0xFF6C63FF),
          ).animate().scale(duration: 600.ms),
          
          const SizedBox(height: 40),
          
          Text(
            'What interests you most?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 20),
          
          Text(
            aiAgent.preferencePrompt,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 40),
          
          PreferenceSelector(
            selectedPreferences: _selectedPreferences,
            onPreferencesChanged: (preferences) {
              setState(() {
                _selectedPreferences = preferences;
              });
            },
          ).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 20),
          
          Text(
            'You can select multiple options or skip this step',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white54,
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }
}