import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/demo_mode_provider.dart';

class DemoModeToggle extends StatelessWidget {
  const DemoModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DemoModeProvider>(
      builder: (context, demoModeProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      demoModeProvider.isDemoMode 
                          ? Icons.science 
                          : Icons.smartphone,
                      color: demoModeProvider.isDemoMode 
                          ? Colors.orange 
                          : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo Mode',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            demoModeProvider.isDemoMode
                                ? 'Using simulated data for testing and web compatibility'
                                : 'Using real device data and screen time tracking',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: demoModeProvider.isDemoMode,
                      onChanged: (value) {
                        demoModeProvider.toggleDemoMode();
                        
                        // Show feedback to user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value 
                                  ? 'Demo mode enabled - Using mock data for web compatibility'
                                  : 'Demo mode disabled - Using real device data',
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: value ? Colors.orange : Colors.blue,
                          ),
                        );
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
                if (demoModeProvider.isDemoMode) ...
                  [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo mode provides simulated screen time and app usage data for testing and web compatibility.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}