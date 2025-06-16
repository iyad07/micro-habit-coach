import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing application configuration from environment variables
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // Novita AI Configuration
  String? get novitaAIApiKey => dotenv.env['NOVITA_AI_API_KEY'];
  String get novitaAIBaseUrl => dotenv.env['NOVITA_AI_BASE_URL'] ?? 'https://api.novita.ai/v3/async/txt2img';

  // App Configuration
  String get appEnvironment => dotenv.env['APP_ENV'] ?? 'development';
  bool get isDebugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  bool get isProduction => appEnvironment.toLowerCase() == 'production';
  bool get isDevelopment => appEnvironment.toLowerCase() == 'development';

  // Analytics Configuration
  bool get isAnalyticsEnabled => dotenv.env['ANALYTICS_ENABLED']?.toLowerCase() == 'true';
  String? get analyticsApiKey => dotenv.env['ANALYTICS_API_KEY'];

  // Notification Configuration
  bool get isNotificationEnabled => dotenv.env['NOTIFICATION_ENABLED']?.toLowerCase() != 'false';

  // Database Configuration
  String? get databaseUrl => dotenv.env['DATABASE_URL'];
  String get databaseName => dotenv.env['DATABASE_NAME'] ?? 'micro_habit_tracker';

  // Feature Flags
  bool get isSentimentAnalysisEnabled => dotenv.env['ENABLE_SENTIMENT_ANALYSIS']?.toLowerCase() != 'false';
  bool get isScreenTimeTrackingEnabled => dotenv.env['ENABLE_SCREEN_TIME_TRACKING']?.toLowerCase() != 'false';
  bool get isAISuggestionsEnabled => dotenv.env['ENABLE_AI_SUGGESTIONS']?.toLowerCase() != 'false';

  // Validation methods
  bool get hasNovitaAIKey => novitaAIApiKey != null && novitaAIApiKey!.isNotEmpty;
  bool get hasAnalyticsKey => analyticsApiKey != null && analyticsApiKey!.isNotEmpty;
  bool get hasDatabaseUrl => databaseUrl != null && databaseUrl!.isNotEmpty;

  // Configuration status for debugging
  Map<String, dynamic> get configStatus => {
    'app_environment': appEnvironment,
    'debug_mode': isDebugMode,
    'has_novita_ai_key': hasNovitaAIKey,
    'sentiment_analysis_enabled': isSentimentAnalysisEnabled,
    'screen_time_tracking_enabled': isScreenTimeTrackingEnabled,
    'ai_suggestions_enabled': isAISuggestionsEnabled,
    'analytics_enabled': isAnalyticsEnabled,
    'has_analytics_key': hasAnalyticsKey,
    'notifications_enabled': isNotificationEnabled,
    'has_database_url': hasDatabaseUrl,
  };

  // Print configuration status (for debugging)
  void printConfigStatus() {
    if (isDebugMode) {
      print('=== Configuration Status ===');
      configStatus.forEach((key, value) {
        print('$key: $value');
      });
      print('===========================');
    }
  }

  // Validate required configuration
  List<String> validateConfiguration() {
    List<String> errors = [];

    if (isSentimentAnalysisEnabled && !hasNovitaAIKey) {
      errors.add('Sentiment analysis is enabled but NOVITA_AI_API_KEY is not set');
    }

    if (isAnalyticsEnabled && !hasAnalyticsKey) {
      errors.add('Analytics is enabled but ANALYTICS_API_KEY is not set');
    }

    return errors;
  }

  // Get environment variable with fallback
  String getEnvVar(String key, {String? fallback}) {
    return dotenv.env[key] ?? fallback ?? '';
  }

  // Get boolean environment variable with fallback
  bool getBoolEnvVar(String key, {bool fallback = false}) {
    final value = dotenv.env[key]?.toLowerCase();
    if (value == null) return fallback;
    return value == 'true' || value == '1' || value == 'yes';
  }

  // Get integer environment variable with fallback
  int getIntEnvVar(String key, {int fallback = 0}) {
    final value = dotenv.env[key];
    if (value == null) return fallback;
    return int.tryParse(value) ?? fallback;
  }

  // Get double environment variable with fallback
  double getDoubleEnvVar(String key, {double fallback = 0.0}) {
    final value = dotenv.env[key];
    if (value == null) return fallback;
    return double.tryParse(value) ?? fallback;
  }
}