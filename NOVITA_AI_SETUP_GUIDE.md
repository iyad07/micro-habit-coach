# Novita AI Integration Setup Guide

This guide provides step-by-step instructions for integrating Novita AI's LLM API with the mood analysis feature in the Micro Habit Tracker application.

## Overview

The mood analysis feature now uses Novita AI's OpenAI-compatible LLM API to perform sentiment analysis through intelligent prompting. This provides more accurate and contextual mood detection compared to traditional rule-based approaches.

## Prerequisites

- Flutter development environment
- Novita AI account
- Internet connection for API calls
- Valid API key from Novita AI

## Step 1: Create Novita AI Account

1. **Sign Up**
   - Visit [Novita AI](https://novita.ai)
   - Click "Sign Up" or "Get Started"
   - Complete the registration process
   - Verify your email address

2. **Account Setup**
   - Log into your Novita AI dashboard
   - Complete any required profile information
   - Review pricing and usage limits

## Step 2: Generate API Key

1. **Access Key Management**
   - Navigate to [Key Management](https://novita.ai/settings/key-management)
   - Or go to Settings → API Keys from the dashboard

2. **Create New API Key**
   - Click "Create New Key" or "Generate API Key"
   - Provide a descriptive name (e.g., "Micro Habit Tracker - Mood Analysis")
   - Set appropriate permissions (ensure chat/completion access)
   - Copy the generated API key immediately
   - **Important**: Store the key securely - it won't be shown again

3. **Key Format**
   - Novita AI keys typically start with `sk_`
   - Example format: `sk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 3: Configure the Application

### Method 1: Direct Configuration (Development)

1. **Update API Key**
   ```dart
   // In lib/services/ai_agent_service.dart
   static const String _novitaApiKey = 'sk_your_actual_api_key_here';
   ```

2. **Verify Configuration**
   ```dart
   // Current configuration in ai_agent_service.dart
   static const String _novitaApiUrl = 'https://api.novita.ai/v3/openai/chat/completions';
   static const String _novitaApiKey = 'YOUR_NOVITA_API_KEY'; // Replace this
   static const String _novitaModel = 'meta-llama/llama-3.1-8b-instruct';
   ```

### Method 2: Environment Variables (Production)

1. **Create Environment File**
   ```bash
   # Create .env file in project root
   NOVITA_API_KEY=sk_your_actual_api_key_here
   ```

2. **Add to .gitignore**
   ```gitignore
   # Add to .gitignore
   .env
   *.env
   ```

3. **Load Environment Variables**
   ```dart
   // Add flutter_dotenv dependency to pubspec.yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   
   // Load in main.dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   Future<void> main() async {
     await dotenv.load(fileName: ".env");
     runApp(MyApp());
   }
   
   // Use in ai_agent_service.dart
   static String get _novitaApiKey => dotenv.env['NOVITA_API_KEY'] ?? 'YOUR_NOVITA_API_KEY';
   ```

## Step 4: Test the Integration

### Basic Test

1. **Run the Example**
   ```dart
   // Use the provided example file
   dart run lib/examples/mood_analysis_example.dart
   ```

2. **Manual Test**
   ```dart
   final aiAgent = AIAgentService();
   
   // Test mood analysis
   final result = await aiAgent.analyzeMoodFromText(
     "I'm feeling really excited about my new project! 🎉"
   );
   
   print('Detected Mood: ${result['detectedMood']}');
   print('Confidence: ${result['confidence']}');
   print('Source: ${result['sentimentAnalysis']['source']}');
   ```

### Expected Output

```
Detected Mood: happy
Confidence: 0.85
Source: novita_ai
```

## Step 5: Verify API Connectivity

### Test API Connection

```dart
Future<void> testNovitaConnection() async {
  try {
    final result = await aiAgent.analyzeMoodFromText("Test message");
    
    if (result['sentimentAnalysis']['source'] == 'novita_ai') {
      print('✅ Novita AI connection successful');
    } else {
      print('⚠️ Using fallback analysis - check API key');
    }
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}
```

### Common Connection Issues

1. **Invalid API Key**
   - Error: `401 Unauthorized`
   - Solution: Verify API key is correct and active

2. **Quota Exceeded**
   - Error: `429 Too Many Requests`
   - Solution: Check usage limits in Novita AI dashboard

3. **Network Issues**
   - Error: `SocketException` or timeout
   - Solution: Check internet connection and firewall settings

## Step 6: Model Configuration

### Available Models

Novita AI supports various models for sentiment analysis:

```dart
// Recommended models (update _novitaModel in ai_agent_service.dart)
static const String _novitaModel = 'meta-llama/llama-3.1-8b-instruct'; // Default
// Alternative options:
// 'meta-llama/llama-3.1-70b-instruct' // More powerful but slower
// 'mistralai/mixtral-8x7b-instruct-v0.1' // Alternative model
```

### Model Selection Criteria

- **Speed**: `llama-3.1-8b-instruct` (fastest)
- **Accuracy**: `llama-3.1-70b-instruct` (most accurate)
- **Balance**: `llama-3.1-8b-instruct` (recommended)

## Step 7: Production Deployment

### Security Best Practices

1. **Never Commit API Keys**
   ```gitignore
   # Ensure these are in .gitignore
   .env
   *.env
   lib/config/api_keys.dart
   ```

2. **Use Environment Variables**
   ```dart
   // Production configuration
   static String get _novitaApiKey {
     return Platform.environment['NOVITA_API_KEY'] ?? 
            dotenv.env['NOVITA_API_KEY'] ?? 
            'fallback_key';
   }
   ```

3. **Implement Rate Limiting**
   ```dart
   // Add rate limiting to prevent quota exhaustion
   class RateLimiter {
     static DateTime? _lastCall;
     static const Duration _minInterval = Duration(milliseconds: 100);
     
     static Future<void> waitIfNeeded() async {
       if (_lastCall != null) {
         final elapsed = DateTime.now().difference(_lastCall!);
         if (elapsed < _minInterval) {
           await Future.delayed(_minInterval - elapsed);
         }
       }
       _lastCall = DateTime.now();
     }
   }
   ```

### Error Handling

```dart
// Enhanced error handling for production
Future<Map<String, dynamic>> _callNovitaAIWithRetry(String text, {int maxRetries = 3}) async {
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await _callNovitaSentimentAnalysis(text);
    } catch (e) {
      if (attempt == maxRetries - 1) {
        // Final attempt failed, use fallback
        return _performRuleBasedSentimentAnalysis(text, _extractEmotionKeywords(text));
      }
      
      // Wait before retry
      await Future.delayed(Duration(seconds: math.pow(2, attempt).toInt()));
    }
  }
  
  // This should never be reached, but just in case
  return _performRuleBasedSentimentAnalysis(text, _extractEmotionKeywords(text));
}
```

## Step 8: Monitoring and Analytics

### Usage Tracking

```dart
// Track API usage
class APIUsageTracker {
  static int _apiCalls = 0;
  static int _fallbackCalls = 0;
  
  static void recordAPICall() => _apiCalls++;
  static void recordFallback() => _fallbackCalls++;
  
  static Map<String, int> getStats() => {
    'api_calls': _apiCalls,
    'fallback_calls': _fallbackCalls,
    'success_rate': _apiCalls / (_apiCalls + _fallbackCalls) * 100,
  };
}
```

### Performance Monitoring

```dart
// Monitor response times
class PerformanceMonitor {
  static final List<Duration> _responseTimes = [];
  
  static void recordResponseTime(Duration duration) {
    _responseTimes.add(duration);
    if (_responseTimes.length > 100) {
      _responseTimes.removeAt(0); // Keep only last 100
    }
  }
  
  static Duration get averageResponseTime {
    if (_responseTimes.isEmpty) return Duration.zero;
    final total = _responseTimes.reduce((a, b) => a + b);
    return Duration(microseconds: total.inMicroseconds ~/ _responseTimes.length);
  }
}
```

## Troubleshooting

### Common Issues and Solutions

1. **"API key not found" Error**
   ```
   Solution: Ensure API key is properly set in ai_agent_service.dart
   Check: static const String _novitaApiKey = 'sk_your_key_here';
   ```

2. **"Model not found" Error**
   ```
   Solution: Verify model name is correct
   Check: static const String _novitaModel = 'meta-llama/llama-3.1-8b-instruct';
   ```

3. **"Quota exceeded" Error**
   ```
   Solution: Check usage limits in Novita AI dashboard
   Consider: Implementing request caching or rate limiting
   ```

4. **"Connection timeout" Error**
   ```
   Solution: Check internet connection
   Consider: Increasing timeout duration or implementing retry logic
   ```

5. **"Invalid JSON response" Error**
   ```
   Solution: The fallback emotion extraction will handle this
   Check: Logs for the actual response content
   ```

### Debug Mode

```dart
// Enable debug logging
static const bool _debugMode = true; // Set to false in production

if (_debugMode) {
  print('Novita AI Request: $body');
  print('Novita AI Response: ${response.body}');
}
```

### Testing Checklist

- [ ] API key is valid and active
- [ ] Model name is correct
- [ ] Internet connection is stable
- [ ] Quota limits are not exceeded
- [ ] Response parsing works correctly
- [ ] Fallback mechanism activates when needed
- [ ] Error handling covers all scenarios

## Cost Optimization

### Reduce API Costs

1. **Implement Caching**
   ```dart
   // Cache recent analyses
   static final Map<String, Map<String, dynamic>> _cache = {};
   static const Duration _cacheExpiry = Duration(hours: 1);
   ```

2. **Batch Processing**
   ```dart
   // Process multiple texts in one request when possible
   Future<List<Map<String, dynamic>>> analyzeMultipleTexts(List<String> texts) async {
     // Implementation for batch processing
   }
   ```

3. **Smart Fallback**
   ```dart
   // Use rule-based analysis for simple cases
   if (_isSimpleCase(text)) {
     return _performRuleBasedSentimentAnalysis(text, keywordAnalysis);
   }
   ```

## Support and Resources

### Documentation Links

- [Novita AI Documentation](https://novita.ai/docs)
- [Novita AI LLM API Guide](https://novita.ai/docs/guides/llm-api)
- [OpenAI API Compatibility](https://novita.ai/docs/guides/llm-api#openai-compatibility)

### Community Support

- [Novita AI Discord](https://discord.gg/novita-ai)
- [GitHub Issues](https://github.com/novitalabs)
- [Support Email](mailto:support@novita.ai)

### Getting Help

If you encounter issues:

1. Check this troubleshooting guide
2. Review the debug logs
3. Test with the provided examples
4. Contact Novita AI support with specific error messages
5. Consider using the fallback rule-based analysis temporarily

## Conclusion

With Novita AI integration, your mood analysis feature now has:

- ✅ Advanced AI-powered sentiment analysis
- ✅ High accuracy emotion detection
- ✅ Robust fallback mechanisms
- ✅ Production-ready error handling
- ✅ Cost-effective implementation

The system will automatically fall back to rule-based analysis if the API is unavailable, ensuring your app remains functional at all times.