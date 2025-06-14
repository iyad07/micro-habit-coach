import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/habit.dart';

class MoodSelector extends StatelessWidget {
  final UserMood? selectedMood;
  final Function(UserMood) onMoodSelected;
  final bool compact;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompactSelector() : _buildFullSelector();
  }

  Widget _buildFullSelector() {
    return Column(
      children: UserMood.values.map((mood) {
        final isSelected = selectedMood == mood;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onMoodSelected(mood),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF6C63FF).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF6C63FF)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        mood.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mood.displayName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getMoodDescription(mood),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF6C63FF),
                      size: 24,
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: UserMood.values.indexOf(mood) * 100),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: UserMood.values.map((mood) {
        final isSelected = selectedMood == mood;
        return GestureDetector(
          onTap: () => onMoodSelected(mood),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF6C63FF)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  mood.displayName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ).animate().scale(
          delay: Duration(milliseconds: UserMood.values.indexOf(mood) * 50),
          duration: const Duration(milliseconds: 300),
        );
      }).toList(),
    );
  }

  String _getMoodDescription(UserMood mood) {
    switch (mood) {
      case UserMood.happy:
        return 'Feeling great and positive';
      case UserMood.stressed:
        return 'Feeling overwhelmed or anxious';
      case UserMood.tired:
        return 'Feeling low energy or exhausted';
      case UserMood.energized:
        return 'Feeling motivated and active';
    }
  }
}