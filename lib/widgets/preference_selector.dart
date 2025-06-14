import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/habit.dart';

class PreferenceSelector extends StatelessWidget {
  final List<HabitCategory> selectedPreferences;
  final Function(List<HabitCategory>) onPreferencesChanged;
  final bool compact;

  const PreferenceSelector({
    super.key,
    required this.selectedPreferences,
    required this.onPreferencesChanged,
    this.compact = false,
  });

  void _togglePreference(HabitCategory category) {
    final newPreferences = List<HabitCategory>.from(selectedPreferences);
    
    if (newPreferences.contains(category)) {
      newPreferences.remove(category);
    } else {
      newPreferences.add(category);
    }
    
    onPreferencesChanged(newPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompactSelector() : _buildFullSelector();
  }

  Widget _buildFullSelector() {
    return Column(
      children: HabitCategory.values.map((category) {
        final isSelected = selectedPreferences.contains(category);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _togglePreference(category),
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
                        category.emoji,
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
                          category.displayName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getCategoryDescription(category),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF6C63FF)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF6C63FF)
                            : Colors.white54,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: HabitCategory.values.indexOf(category) * 100),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: HabitCategory.values.map((category) {
        final isSelected = selectedPreferences.contains(category);
        return GestureDetector(
          onTap: () => _togglePreference(category),
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
                  category.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  category.displayName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ).animate().scale(
          delay: Duration(milliseconds: HabitCategory.values.indexOf(category) * 50),
          duration: const Duration(milliseconds: 300),
        );
      }).toList(),
    );
  }

  String _getCategoryDescription(HabitCategory category) {
    switch (category) {
      case HabitCategory.physical:
        return 'Exercise, movement, and physical wellness';
      case HabitCategory.mindfulness:
        return 'Meditation, breathing, and mental clarity';
      case HabitCategory.relaxation:
        return 'Rest, recovery, and stress relief';
      case HabitCategory.productivity:
        return 'Learning, organizing, and goal achievement';
    }
  }
}