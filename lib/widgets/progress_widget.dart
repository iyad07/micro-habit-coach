import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';

class ProgressWidget extends StatelessWidget {
  final UserProfile userProfile;
  final bool compact;

  const ProgressWidget({
    super.key,
    required this.userProfile,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.trending_up,
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
                      'Your Progress',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Keep up the great work!',
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
          SizedBox(height: compact ? 16 : 20),
          if (compact)
            _buildCompactStats()
          else
            _buildFullStats(),
        ],
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildFullStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                title: 'Current Streak',
                value: '${userProfile.currentStreak}',
                subtitle: 'days',
                color: const Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.emoji_events,
                title: 'Longest Streak',
                value: '${userProfile.longestStreak}',
                subtitle: 'days',
                color: const Color(0xFFFFD700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                title: 'Total Completed',
                value: '${userProfile.totalHabitsCompleted}',
                subtitle: 'habits',
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                title: 'Days Active',
                value: '${_calculateDaysActive()}',
                subtitle: 'days',
                color: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildProgressBar(),
      ],
    );
  }

  Widget _buildCompactStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCompactStat(
          icon: Icons.local_fire_department,
          value: '${userProfile.currentStreak}',
          label: 'Streak',
          color: const Color(0xFFFF6B35),
        ),
        _buildCompactStat(
          icon: Icons.check_circle,
          value: '${userProfile.totalHabitsCompleted}',
          label: 'Completed',
          color: const Color(0xFF4CAF50),
        ),
        _buildCompactStat(
          icon: Icons.emoji_events,
          value: '${userProfile.longestStreak}',
          label: 'Best',
          color: const Color(0xFFFFD700),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().scale(
      delay: const Duration(milliseconds: 100),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildProgressBar() {
    final weeklyGoal = 7; // 7 days a week
    final currentStreak = userProfile.currentStreak ?? 0;
    final currentWeekProgress = currentStreak % 7;
    final progress = currentWeekProgress / weeklyGoal;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$currentWeekProgress/$weeklyGoal days',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getProgressMessage(progress),
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 0.2,
      end: 0,
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 400),
    );
  }

  int _calculateDaysActive() {
    final now = DateTime.now();
    final createdAt = userProfile.createdAt;
    return now.difference(createdAt).inDays + 1;
  }

  String _getProgressMessage(double progress) {
    if (progress >= 1.0) {
      return 'Amazing! You\'ve completed your weekly goal! 🎉';
    } else if (progress >= 0.7) {
      return 'You\'re almost there! Keep going! 💪';
    } else if (progress >= 0.4) {
      return 'Great progress! You\'re on track! 🚀';
    } else {
      return 'Let\'s build that habit streak! 🌟';
    }
  }
}

class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final bool compact;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.3),
            const Color(0xFFFF6B35).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 8 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: compact ? 20 : 24,
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak Day Streak!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!compact)
                  Text(
                    'Best: $longestStreak days',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (currentStreak > 0)
            Text(
              '🔥',
              style: TextStyle(fontSize: compact ? 20 : 24),
            ),
        ],
      ),
    ).animate().scale(
      duration: const Duration(milliseconds: 400),
    );
  }
}