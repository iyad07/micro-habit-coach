# Mood Analysis Implementation Guide

This document provides a comprehensive guide for the mood analysis feature using sentiment analysis in the Micro Habit Tracker application.

## Overview

The mood analysis feature processes user text input to determine their emotional state and categorizes it into one of four mood categories: **Happy**, **Stressed**, **Tired**, or **Energized**. Based on the detected mood, the system generates personalized habit suggestions.

## Architecture

### Core Components

1. **Mood Analysis Engine** (`AIAgentService.analyzeMoodFromText`)
   - Processes user text input
   - Extracts emotion keywords and emojis
   - Uses Novita AI sentiment analysis (with rule-based fallback)
   - Classifies mood into target categories
   - Generates confidence scores

2. **Habit Generation** (`AIAgentService.generateHabitFromMoodText`)
   - Analyzes mood from text
   - Converts mood to appropriate enum
   - Generates personalized habit suggestions
   - Provides contextual processing messages

3. **Keyword Detection System**
   - Comprehensive emotion keyword database
   - Emoji recognition
   - Multi-language support ready

## Implementation Details

### Mood Classification Process

```
User Input → Keyword Extraction → Sentiment Analysis → Mood Classification → Habit Generation
```

#### Step 1: Keyword Extraction
- Scans text for emotion-related keywords and emojis
- Categories: happy, stressed, tired, energized
- Supports both text and emoji indicators

#### Step 2: Sentiment Analysis
- **Primary**: Novita AI API integration
- **Fallback**: Rule-based sentiment analysis
- Provides sentiment scores and confidence levels

#### Step 3: Mood Classification
- Combines keyword analysis with sentiment results
- Prioritizes keyword-based detection over sentiment-based
- Maps results to target mood categories

#### Step 4: Habit Generation
- Uses detected mood to generate appropriate habits
- Considers user preferences and historical data
- Provides contextual messaging

### Emotion Keywords Database

```dart
static const Map<String, List<String>> _emotionKeywords = {
  'happy': ['happy', 'joy', 'excited', 'cheerful', 'delighted', 'pleased', 
           'content', 'glad', 'elated', 'euphoric', '😊', '😄', '😃', '🙂', 
           '😁', '🥳', '🎉'],
  'stressed': ['stressed', 'anxious', 'worried', 'overwhelmed', 'pressure', 
              'tense', 'nervous', 'frantic', 'panic', 'burden', '😰', '😟', 
              '😧', '😨', '😱', '💔', '😵'],
  'tired': ['tired', 'exhausted', 'fatigue', 'sleepy', 'drained', 'weary', 
           'worn out', 'lethargic', 'sluggish', 'depleted', '😴', '😪', 
           '🥱', '😑', '😶', '💤'],
  'energized': ['energized', 'motivated', 'pumped', 'active', 'vibrant', 
               'dynamic', 'enthusiastic', 'invigorated', 'refreshed', 
               'charged', '⚡', '🔥', '💪', '🚀', '✨', '🌟']
};
```

## Novita AI Integration

### API Configuration

```dart
static const String _novitaApiUrl = 'https://api.novita.ai/v3/async/txt2img';
static const String _novitaApiKey = 'YOUR_NOVITA_API_KEY';
```

### Setup Instructions

1. **Get Novita AI API Key**
   - Sign up at [Novita AI](https://novita.ai)
   - Navigate to API section
   - Generate a new API key
   - Copy the key for configuration

2. **Configure API Key**
   ```dart
   // Replace in ai_agent_service.dart
   static const String _novitaApiKey = 'your_actual_api_key_here';
   ```

3. **Update API Endpoint**
   - Verify the correct Novita AI sentiment analysis endpoint
   - Update `_novitaApiUrl` if needed
   - Adjust request payload format according to Novita AI documentation

### API Request Format

```dart
final body = json.encode({
  'text': text,
  'model': 'sentiment-analysis-v1', // Replace with actual Novita AI model
});

final headers = {
  'Authorization': 'Bearer $_novitaApiKey',
  'Content-Type': 'application/json',
};
```

### Error Handling

- **API Failures**: Automatic fallback to rule-based analysis
- **Network Issues**: Graceful degradation with local processing
- **Invalid Responses**: Default mood classification with low confidence

## Usage Examples

### Basic Mood Analysis

```dart
final aiAgent = AIAgentService();

// Analyze mood from text
final result = await aiAgent.analyzeMoodFromText(
  "I'm feeling really stressed about my presentation tomorrow 😰"
);

print('Detected Mood: ${result['detectedMood']}'); // "stressed"
print('Confidence: ${result['confidence']}'); // 0.85
```

### Generate Habit from Mood

```dart
// Generate habit suggestion based on mood text
final habitResult = await aiAgent.generateHabitFromMoodText(
  "I'm so energized and ready to be productive! ⚡"
);

final habit = habitResult['habitSuggestion'];
print('Suggestion: ${habit['suggestion']}'); // "Take a 10-minute energizing walk"
print('Category: ${habit['category']}'); // "physical"
```

## Response Format

### Mood Analysis Response

```dart
{
  'originalText': 'User input text',
  'detectedMood': 'happy|stressed|tired|energized',
  'confidence': 0.0-1.0,
  'keywordAnalysis': {
    'foundKeywords': {'emotion': ['keyword1', 'keyword2']},
    'totalMatches': 3,
    'dominantEmotion': 'happy'
  },
  'sentimentAnalysis': {
    'sentiment': 'positive|negative|neutral',
    'confidence': 0.0-1.0,
    'emotions': {},
    'source': 'novita_ai|rule_based'
  },
  'reasoning': 'Classification explanation',
  'timestamp': 'ISO8601 timestamp'
}
```

### Habit Generation Response

```dart
{
  'moodAnalysis': { /* mood analysis result */ },
  'habitSuggestion': {
    'suggestion': 'Habit description',
    'category': 'mindfulness|physical|productivity',
    'estimatedDuration': 'Duration string',
    'difficulty': 'easy|moderate|challenging'
  },
  'processingMessage': 'Contextual message for user',
  'timestamp': 'ISO8601 timestamp'
}
```

## Confidence Scoring

The confidence score is calculated using a weighted average:
- **60%** keyword-based confidence
- **40%** sentiment analysis confidence

```dart
double confidence = (keywordConfidence * 0.6 + sentimentConfidence * 0.4);
```

### Confidence Levels
- **0.8-1.0**: High confidence (strong keyword matches + positive sentiment)
- **0.6-0.8**: Medium confidence (some keywords or clear sentiment)
- **0.3-0.6**: Low confidence (weak indicators)
- **0.0-0.3**: Very low confidence (fallback classification)

## Customization Options

### Adding New Keywords

```dart
// Extend emotion keywords
'happy': [...existingKeywords, 'blissful', 'ecstatic', '🌈'],
```

### Custom Mood Categories

1. Update `UserMood` enum in models
2. Add keyword mappings
3. Update classification logic
4. Extend habit suggestion mappings

### Language Support

```dart
// Add language-specific keywords
'happy': {
  'en': ['happy', 'joyful'],
  'es': ['feliz', 'alegre'],
  'fr': ['heureux', 'joyeux']
}
```

## Performance Considerations

### Optimization Strategies

1. **Caching**: Store recent mood analyses
2. **Batch Processing**: Group multiple requests
3. **Local Fallback**: Always available rule-based analysis
4. **Async Processing**: Non-blocking mood detection

### Memory Management

- Keyword database is static (loaded once)
- Analysis results are stored temporarily
- Automatic cleanup of old analysis data

## Testing

### Unit Tests

```dart
// Test mood detection accuracy
void testMoodDetection() {
  final testCases = {
    'I am very happy today! 😊': 'happy',
    'Feeling stressed and overwhelmed': 'stressed',
    'So tired and exhausted 😴': 'tired',
    'Energized and ready to go! ⚡': 'energized',
  };
  
  // Run tests...
}
```

### Integration Tests

- API connectivity tests
- Fallback mechanism validation
- End-to-end mood-to-habit flow

## Security Considerations

### API Key Management

- Store API keys securely (environment variables)
- Never commit keys to version control
- Use different keys for development/production

### Data Privacy

- User text is processed temporarily
- No permanent storage of sensitive content
- Anonymized analytics only

### Error Handling

- Graceful degradation on API failures
- No exposure of internal errors to users
- Comprehensive logging for debugging

## Troubleshooting

### Common Issues

1. **API Key Invalid**
   - Verify key is correct
   - Check API quota/limits
   - Ensure proper authorization header

2. **Low Confidence Scores**
   - Add more specific keywords
   - Improve text preprocessing
   - Adjust confidence calculation weights

3. **Incorrect Mood Detection**
   - Review keyword mappings
   - Check sentiment analysis accuracy
   - Validate classification logic

### Debug Mode

```dart
// Enable detailed logging
final analysis = await aiAgent.analyzeMoodFromText(text);
print('Debug Info: ${analysis['keywordAnalysis']}');
print('Sentiment: ${analysis['sentimentAnalysis']}');
```

## Future Enhancements

### Planned Features

1. **Machine Learning Integration**
   - User-specific mood patterns
   - Adaptive keyword weighting
   - Personalized confidence thresholds

2. **Multi-language Support**
   - Localized keyword databases
   - Language-specific sentiment models
   - Cultural context awareness

3. **Advanced Analytics**
   - Mood trend analysis
   - Habit effectiveness correlation
   - Predictive mood modeling

4. **Real-time Processing**
   - Streaming mood analysis
   - Live habit suggestions
   - Instant feedback loops

## Contributing

When contributing to the mood analysis feature:

1. Follow existing code patterns
2. Add comprehensive tests
3. Update documentation
4. Consider performance impact
5. Maintain backward compatibility

## Support

For issues or questions:
- Check existing documentation
- Review example implementations
- Test with provided examples
- Submit detailed bug reports