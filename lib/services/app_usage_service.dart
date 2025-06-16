import 'package:flutter/foundation.dart';
import 'dart:io';
import '../providers/demo_mode_provider.dart';

// Conditional imports for platform-specific implementations
import 'app_usage_service_android.dart' if (dart.library.html) 'app_usage_service_web_stub.dart';

/// Abstract interface for app usage tracking across platforms
abstract class AppUsageService {
  /// Check if the service has necessary permissions
  Future<bool> hasPermissions();
  
  /// Request permissions for app usage data access
  Future<bool> requestPermissions();
  
  /// Get total screen time for today in hours
  Future<double> getTodayScreenTime();
  
  /// Get app usage data for today
  Future<Map<String, double>> getTodayAppUsage();
  
  /// Get screen time for a specific date range
  Future<double> getScreenTimeForPeriod(DateTime start, DateTime end);
  
  /// Get screen time analysis with categorization
  Future<Map<String, dynamic>> getScreenTimeAnalysis();
  
  /// Check if screen time data collection is supported on this platform
  bool isSupported();
  
  /// Get a user-friendly message about screen time support
  String getSupportMessage();
  
  /// Factory method to create the appropriate service based on platform
  static AppUsageService create({DemoModeProvider? demoModeProvider}) {
    // If demo mode is enabled or we're on web, use mock implementation
    if (kIsWeb || (demoModeProvider?.isDemoMode ?? false)) {
      return AppUsageServiceWeb();
    } else if (!kIsWeb && Platform.isAndroid) {
      return AppUsageServiceAndroidImpl();
    } else {
      // Fallback to web/mock implementation for unsupported platforms
      return AppUsageServiceWeb();
    }
  }
}

/// Mock implementation for web and unsupported platforms
class AppUsageServiceWeb implements AppUsageService {
  static const bool _isDemoMode = true;
  
  // Mock data for demonstration
  static const Map<String, double> _mockAppUsage = {
    'com.instagram.android': 2.5,
    'com.whatsapp': 1.8,
    'com.spotify.music': 1.2,
    'com.twitter.android': 0.9,
    'com.google.android.youtube': 3.1,
    'com.facebook.katana': 1.4,
    'com.snapchat.android': 0.7,
    'com.tiktok': 2.2,
    'com.netflix.mediaclient': 1.6,
    'com.google.android.apps.messaging': 0.5,
  };
  
  static const double _mockTotalScreenTime = 8.2;
  
  @override
  Future<bool> hasPermissions() async {
    // Always return true for web/demo mode
    return true;
  }
  
  @override
  Future<bool> requestPermissions() async {
    // Always return true for web/demo mode
    return true;
  }
  
  @override
  Future<double> getTodayScreenTime() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTotalScreenTime;
  }
  
  @override
  Future<Map<String, double>> getTodayAppUsage() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return Map.from(_mockAppUsage);
  }
  
  @override
  Future<double> getScreenTimeForPeriod(DateTime start, DateTime end) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Calculate mock data based on period length
    final days = end.difference(start).inDays;
    return _mockTotalScreenTime * (days > 0 ? days : 1);
  }
  
  @override
  Future<Map<String, dynamic>> getScreenTimeAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final screenTime = await getTodayScreenTime();
    final appUsage = await getTodayAppUsage();
    
    // Categorize screen time
    String category;
    if (screenTime >= 8) {
      category = 'high';
    } else if (screenTime >= 4) {
      category = 'moderate';
    } else {
      category = 'low';
    }
    
    // Get top apps with mock app names
    final sortedApps = appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topApps = <Map<String, dynamic>>[];
    
    for (final entry in sortedApps.take(5)) {
      final appInfo = _getMockAppInfo(entry.key);
      topApps.add({
        'name': appInfo['name'],
        'packageName': appInfo['packageName'],
        'hours': entry.value,
        'icon': appInfo['icon'],
      });
    }
    
    return {
      'totalHours': screenTime,
      'category': category,
      'topApps': topApps,
      'appCount': appUsage.length,
      'timestamp': DateTime.now().toIso8601String(),
      'isDemoMode': _isDemoMode,
    };
  }
  
  @override
  bool isSupported() {
    return true; // Always supported in demo mode
  }
  
  @override
  String getSupportMessage() {
    if (kIsWeb) {
      return 'Running in web demo mode with simulated screen time data.';
    } else {
      return 'Running in demo mode with simulated screen time data.';
    }
  }
  
  /// Get mock app information for display
  Map<String, dynamic> _getMockAppInfo(String packageName) {
    const appNames = {
      'com.instagram.android': 'Instagram',
      'com.whatsapp': 'WhatsApp',
      'com.spotify.music': 'Spotify',
      'com.twitter.android': 'Twitter',
      'com.google.android.youtube': 'YouTube',
      'com.facebook.katana': 'Facebook',
      'com.snapchat.android': 'Snapchat',
      'com.tiktok': 'TikTok',
      'com.netflix.mediaclient': 'Netflix',
      'com.google.android.apps.messaging': 'Messages',
    };
    
    return {
      'name': appNames[packageName] ?? _formatPackageName(packageName),
      'packageName': packageName,
      'icon': null, // No icons in web mode
    };
  }
  
  /// Format package name to a more readable format
  String _formatPackageName(String packageName) {
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      final appName = parts.last;
      return appName.substring(0, 1).toUpperCase() + appName.substring(1);
    }
    return packageName;
  }
}

// The Android implementation is now in a separate file to avoid web compilation issues