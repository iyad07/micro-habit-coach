import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/habit.dart';
import '../providers/app_provider.dart';
import '../widgets/preference_selector.dart';
import '../widgets/mood_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final userProfile = appProvider.userProfile;
    
    if (userProfile != null) {
      setState(() {
        _notificationsEnabled = userProfile.notificationsEnabled;
        _reminderTime = TimeOfDay(
          hour: userProfile.reminderHour,
          minute: userProfile.reminderMinute,
        );
      });
    }
  }

  Future<void> _updateNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.updateNotificationSettings(
        _notificationsEnabled,
        _reminderTime.hour,
        _reminderTime.minute,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings updated successfully!',
              style: GoogleFonts.poppins(),
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
            content: Text('Error updating settings: $e'),
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

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              surface: Color(0xFF2A2A3E),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      await _updateNotificationSettings();
    }
  }

  Future<void> _updatePreferences(List<HabitCategory> preferences) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.updatePreferences(preferences);
  }

  Future<void> _updateMood(UserMood mood) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.updateMood(mood);
  }

  Future<void> _resetAppData() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text(
          'Reset App Data',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will delete all your habits, progress, and settings. This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.resetAppData();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      final userProfile = appProvider.userProfile;
      
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              _buildProfileSection(userProfile),
              const SizedBox(height: 30),
              
              // Mood section
              _buildMoodSection(userProfile),
              const SizedBox(height: 30),
              
              // Preferences section
              _buildPreferencesSection(userProfile),
              const SizedBox(height: 30),
              
              // Notifications section
              _buildNotificationsSection(),
              const SizedBox(height: 30),
              
              // Statistics section
              _buildStatisticsSection(userProfile),
              const SizedBox(height: 30),
              
              // Danger zone
              _buildDangerZone(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProfileSection(userProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile?.name ?? 'User',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Member since ${userProfile?.createdAt.day}/${userProfile?.createdAt.month}/${userProfile?.createdAt.year}',
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
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildMoodSection(userProfile) {
    return _buildSection(
      title: 'Current Mood',
      icon: Icons.mood,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling today?',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          MoodSelector(
            selectedMood: userProfile?.currentMood,
            onMoodSelected: _updateMood,
            compact: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildPreferencesSection(userProfile) {
    return _buildSection(
      title: 'Habit Preferences',
      icon: Icons.favorite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What types of habits interest you most?',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          PreferenceSelector(
            selectedPreferences: userProfile?.preferredCategories ?? [],
            onPreferencesChanged: _updatePreferences,
            compact: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildNotificationsSection() {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Reminders',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _updateNotificationSettings();
                },
                activeColor: const Color(0xFF6C63FF),
              ),
            ],
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectReminderTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reminder Time',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _reminderTime.format(context),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildStatisticsSection(userProfile) {
    return _buildSection(
      title: 'Statistics',
      icon: Icons.bar_chart,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Completed',
              '${userProfile?.totalHabitsCompleted ?? 0}',
              Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Longest Streak',
              '${userProfile?.longestStreak ?? 0} days',
              Icons.local_fire_department,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6C63FF),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return _buildSection(
      title: 'Danger Zone',
      icon: Icons.warning,
      iconColor: Colors.red,
      child: ElevatedButton(
        onPressed: _resetAppData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Reset All Data',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? const Color(0xFF6C63FF),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}