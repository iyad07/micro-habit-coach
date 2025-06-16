import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// Provider for managing demo mode state
class DemoModeProvider extends ChangeNotifier {
  bool _isDemoMode = false;
  final StorageService _storageService = StorageService();

  bool get isDemoMode => _isDemoMode;

  DemoModeProvider() {
    _loadDemoMode();
  }

  // Load demo mode state from storage
  Future<void> _loadDemoMode() async {
    try {
      _isDemoMode = await _storageService.getDemoMode();
      notifyListeners();
    } catch (e) {
      print('Error loading demo mode: $e');
    }
  }

  // Toggle demo mode
  Future<void> toggleDemoMode() async {
    try {
      _isDemoMode = !_isDemoMode;
      await _storageService.setDemoMode(_isDemoMode);
      notifyListeners();
    } catch (e) {
      print('Error toggling demo mode: $e');
      // Revert on error
      _isDemoMode = !_isDemoMode;
      notifyListeners();
    }
  }

  // Set demo mode explicitly
  Future<void> setDemoMode(bool enabled) async {
    if (_isDemoMode == enabled) return;
    
    try {
      _isDemoMode = enabled;
      await _storageService.setDemoMode(_isDemoMode);
      notifyListeners();
    } catch (e) {
      print('Error setting demo mode: $e');
      // Revert on error
      _isDemoMode = !enabled;
      notifyListeners();
    }
  }
  
  /// Enable demo mode
  Future<void> enableDemoMode() => setDemoMode(true);
  
  /// Disable demo mode
  Future<void> disableDemoMode() => setDemoMode(false);
  
  /// Get demo mode description
  String get demoModeDescription {
    if (_isDemoMode) {
      return 'Demo mode is enabled. The app will use simulated data for screen time and app usage.';
    } else {
      return 'Demo mode is disabled. The app will use real device data when available.';
    }
  }
  
  /// Get demo mode status for display
  String get statusText => _isDemoMode ? 'Enabled' : 'Disabled';
}