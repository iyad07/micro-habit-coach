// Web stub file - this file is used when compiling for web
// It provides a stub implementation that delegates to the web service

import 'app_usage_service.dart';

/// Stub implementation that delegates to AppUsageServiceWeb
class AppUsageServiceAndroidImpl implements AppUsageService {
  final AppUsageService _webService = AppUsageServiceWeb();
  
  @override
  Future<bool> hasPermissions() => _webService.hasPermissions();
  
  @override
  Future<bool> requestPermissions() => _webService.requestPermissions();
  
  @override
  Future<double> getTodayScreenTime() => _webService.getTodayScreenTime();
  
  @override
  Future<Map<String, double>> getTodayAppUsage() => _webService.getTodayAppUsage();
  
  @override
  Future<double> getScreenTimeForPeriod(DateTime start, DateTime end) => 
      _webService.getScreenTimeForPeriod(start, end);
  
  @override
  Future<Map<String, dynamic>> getScreenTimeAnalysis() => 
      _webService.getScreenTimeAnalysis();
  
  @override
  bool isSupported() => _webService.isSupported();
  
  @override
  String getSupportMessage() => _webService.getSupportMessage();
}