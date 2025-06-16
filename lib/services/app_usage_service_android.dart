// This file contains Android-specific implementations
// It should only be imported on Android platform

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_apps/device_apps.dart';
import 'app_usage_service.dart';

/// Android implementation using native packages
class AppUsageServiceAndroidImpl implements AppUsageService {
  static const Duration _defaultQueryPeriod = Duration(days: 1);
  
  @override
  Future<bool> hasPermissions() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        return await UsageStats.checkUsagePermission() ?? false;
      } catch (e) {
        print('Error checking permissions: $e');
        return false;
      }
    }
    return false;
  }
  
  @override
  Future<bool> requestPermissions() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await UsageStats.grantUsagePermission();
        return await hasPermissions();
      } catch (e) {
        print('Error requesting usage permission: $e');
        return false;
      }
    }
    return false;
  }
  
  @override
  Future<double> getTodayScreenTime() async {
    try {
      if (!await hasPermissions()) {
        throw Exception('Screen time permissions not granted');
      }
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      return await _getAndroidScreenTime(startOfDay, now);
    } catch (e) {
      print('Error getting screen time: $e');
      return 0.0;
    }
  }
  
  @override
  Future<Map<String, double>> getTodayAppUsage() async {
    try {
      if (!await hasPermissions()) {
        throw Exception('Screen time permissions not granted');
      }
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      return await _getAndroidAppUsage(startOfDay, now);
    } catch (e) {
      print('Error getting app usage: $e');
      return {};
    }
  }
  
  @override
  Future<double> getScreenTimeForPeriod(DateTime start, DateTime end) async {
    try {
      if (!await hasPermissions()) {
        throw Exception('Screen time permissions not granted');
      }
      
      return await _getAndroidScreenTime(start, end);
    } catch (e) {
      print('Error getting screen time for period: $e');
      return 0.0;
    }
  }
  
  @override
  Future<Map<String, dynamic>> getScreenTimeAnalysis() async {
    try {
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
      
      // Find top apps and resolve their information
      final sortedApps = appUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topApps = <Map<String, dynamic>>[];
      
      for (final entry in sortedApps.take(5)) {
        final appInfo = await _getAppInfo(entry.key);
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
      };
    } catch (e) {
      print('Error in screen time analysis: $e');
      return {
        'totalHours': 0.0,
        'category': 'low',
        'topApps': [],
        'appCount': 0,
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
  
  @override
  bool isSupported() {
    return !kIsWeb && Platform.isAndroid;
  }
  
  @override
  String getSupportMessage() {
    return 'Screen time tracking is available on Android. Please grant usage access permission.';
  }
  
  /// Android-specific screen time calculation using usage_stats
  Future<double> _getAndroidScreenTime(DateTime start, DateTime end) async {
    try {
      final usageStats = await UsageStats.queryUsageStats(start, end);
      
      if (usageStats == null || usageStats.isEmpty) {
        return 0.0;
      }
      
      // Calculate total foreground time across all apps
      int totalTimeInForeground = 0;
      
      for (final usage in usageStats) {
        final timeInForeground = usage.totalTimeInForeground;
        if (timeInForeground != null) {
          // Handle both int and String types
          if (timeInForeground is int) {
            totalTimeInForeground += timeInForeground as int;
          } else if (timeInForeground is String) {
            totalTimeInForeground += int.tryParse(timeInForeground) ?? 0;
          }
        }
      }
      
      // Convert milliseconds to hours
      return totalTimeInForeground / (1000 * 60 * 60);
    } catch (e) {
      print('Error in Android screen time calculation: $e');
      return 0.0;
    }
  }
  
  /// Android-specific app usage data using usage_stats
  Future<Map<String, double>> _getAndroidAppUsage(DateTime start, DateTime end) async {
    try {
      final usageStats = await UsageStats.queryUsageStats(start, end);
      
      if (usageStats == null || usageStats.isEmpty) {
        return {};
      }
      
      final Map<String, double> appUsage = {};
      
      for (final usage in usageStats) {
        final packageName = usage.packageName ?? 'Unknown';
        final timeInForeground = usage.totalTimeInForeground;
        
        if (timeInForeground != null) {
          int timeInMs = 0;
          
          // Handle both int and String types
          if (timeInForeground is int) {
            timeInMs = timeInForeground as int;
          } else if (timeInForeground is String) {
            timeInMs = int.tryParse(timeInForeground) ?? 0;
          }
          
          // Convert milliseconds to hours and filter out very short usage
          final hours = timeInMs / (1000 * 60 * 60);
          if (hours > 0.01) { // Only include apps used for more than 36 seconds
            appUsage[packageName] = hours;
          }
        }
      }
      
      return appUsage;
    } catch (e) {
      print('Error in Android app usage calculation: $e');
      return {};
    }
  }
  
  /// Resolve package name to app information
  Future<Map<String, dynamic>> _getAppInfo(String packageName) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final app = await DeviceApps.getApp(packageName, true);
        if (app != null) {
          return {
            'name': app.appName,
            'packageName': packageName,
            'icon': app is ApplicationWithIcon ? app.icon : null,
          };
        }
      }
      
      // Fallback to package name if app info not found
      return {
        'name': _formatPackageName(packageName),
        'packageName': packageName,
        'icon': null,
      };
    } catch (e) {
      print('Error getting app info for $packageName: $e');
      return {
        'name': _formatPackageName(packageName),
        'packageName': packageName,
        'icon': null,
      };
    }
  }
  
  /// Format package name to a more readable format
  String _formatPackageName(String packageName) {
    // Extract the last part of the package name and capitalize it
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      final appName = parts.last;
      return appName.substring(0, 1).toUpperCase() + appName.substring(1);
    }
    return packageName;
  }
}