# AI-Powered Habit Suggestion System

## Overview

The AI-Powered Habit Suggestion System integrates **Novita AI** with comprehensive user analysis to generate personalized micro-habit recommendations. This system analyzes user mood through natural language processing, considers screen time patterns for digital wellness, and adapts suggestions based on user preferences and behavioral patterns.

## Key Features

### 🧠 AI-Powered Mood Analysis
- **Natural Language Processing**: Uses Novita AI to analyze mood from user text input
- **Emotion Detection**: Identifies happy, stressed, tired, or energized states
- **Confidence Scoring**: Provides confidence levels for mood classifications
- **Fallback System**: Rule-based analysis when AI is unavailable

### 📱 Screen Time Integration
- **Automatic Detection**: Retrieves screen time data from device usage stats
- **Digital Wellness**: Suggests offline activities for high screen time
- **Balance Recommendations**: Promotes healthy screen time habits
- **App Usage Analysis**: Identifies social media heavy usage patterns

### 🎯 Personalized Recommendations
- **User Preferences**: Filters suggestions by preferred habit categories
- **Behavioral Learning**: Adapts based on completion history and patterns
- **Difficulty Adaptation**: Adjusts challenge level based on user streak
- **Time Context**: Considers time of day and day of week

### 📊 Comprehensive Analytics
- **Behavior Pattern Tracking**: Stores and analyzes user interactions
- **Success Rate Monitoring**: Tracks completion rates and preferences
- **Learning Phase Detection**: Identifies new vs experienced users
- **Preference Evolution**: Adapts to changing user interests

## System Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Input    │───▶│   Novita AI      │───▶│   AI Analysis   │
│ (Mood Text)     │    │ Sentiment API    │    │   Results       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
┌─────────────────┐    ┌──────────────────┐             ▼
│ Screen Time     │───▶│  Context Builder │    ┌─────────────────┐
│   Service       │    │                  │───▶│ Comprehensive   │
└─────────────────┘    └──────────────────┘    │   Context       │
                                ▲               └─────────────────┘
┌─────────────────┐             │                        │
│ User Behavior   │─────────────┘                        ▼
│   Patterns      │                               ┌─────────────────┐
└─────────────────┘                               │ AI Suggestion   │
                                                  │   Generator     │
┌─────────────────┐                               └─────────────────┘
│ User            │                                        │
│ Preferences     │                                        ▼
└─────────────────┘                               ┌─────────────────┐
                                                  │ Enhanced        │
                                                  │ Suggestion      │
                                                  └─────────────────┘
```

## API Integration

### Novita AI Configuration

```dart
// API Configuration
static const String _novitaApiUrl = 'https://api.novita.ai/v3/openai/chat/completions';
static const String _novitaApiKey = 'your-api-key-here';
static const String _novitaModel = 'meta-llama/llama-3.1-8b-instruct';
```

### Usage Example

```dart
// Generate AI-powered habit suggestion
final result = await aiAgentService.generateAIPersonalizedHabitSuggestion(
  moodText: "I'm feeling stressed and overwhelmed with work",
  preferences: [HabitCategory.mindfulness, HabitCategory.relaxation],
  screenTimeHours: 6.5,
  currentStreak: 3,
  recentCompletions: {'mindfulness': 2, 'physical': 1},
);

if (result['success'] == true) {
  final suggestion = result['suggestion'];
  print('Suggested Habit: ${suggestion['title']}');
  print('Description: ${suggestion['description']}');
  print('AI Reasoning: ${suggestion['reasoning']}');
}
```

## Input Processing

### 1. Mood Analysis

**Input**: Natural language text describing user's current emotional state

**Processing**:
- Novita AI analyzes sentiment and emotion
- Keyword extraction for emotion detection
- Confidence scoring and validation
- Fallback to rule-based analysis if needed

**Output**: Structured mood data with confidence scores

```json
{
  "mood": "stressed",
  "confidence": 0.85,
  "sentiment": "negative",
  "reasoning": "Keywords indicate work pressure and anxiety"
}
```

### 2. Screen Time Analysis

**Input**: Screen time hours (automatic or manual)

**Processing**:
- Categorizes as low/moderate/high
- Analyzes app usage patterns
- Generates digital wellness recommendations
- Calculates suggested break duration

**Output**: Screen time insights and recommendations

```json
{
  "hours": 6.5,
  "category": "high",
  "recommendation": "Consider offline activities to reduce digital fatigue",
  "suggestedBreakDuration": 15
}
```

### 3. Behavioral Pattern Learning

**Input**: User interaction history and completion data

**Processing**:
- Tracks completion success rates
- Identifies preferred categories and times
- Determines learning phase status
- Calculates difficulty preferences

**Output**: Personalization insights

```json
{
  "learningPhase": false,
  "successRate": 0.78,
  "preferredCategories": ["mindfulness", "physical"],
  "preferredTimes": [9, 14, 20],
  "difficultyPreference": "moderate"
}
```

## AI Suggestion Generation

### Novita AI Prompt Engineering

The system uses carefully crafted prompts to ensure consistent, high-quality suggestions:

```
System Prompt:
"You are an expert AI habit coach specializing in personalized wellness recommendations.
Analyze the provided context and suggest ONE specific, actionable micro-habit that:
1. Matches the user's current mood and emotional state
2. Considers their screen time patterns and digital wellness
3. Aligns with their stated preferences
4. Is appropriate for their current streak and motivation level
5. Takes into account their behavioral patterns and success history"

User Context:
- Mood: stressed (confidence: 85%)
- Screen Time: 6.5 hours (high)
- Preferences: mindfulness, relaxation
- Current Streak: 3 days
- Success Rate: 78%
```

### Suggestion Enhancement

After AI generation, suggestions are enhanced with:

- **Personalized Titles**: Adapted to user's streak and mood
- **Dynamic Descriptions**: Include contextual information
- **Completion Prediction**: Likelihood of successful completion
- **Streak Encouragement**: Motivational messages based on progress
- **Next-Level Suggestions**: Progressive difficulty recommendations

## Example Scenarios

### Scenario 1: High Screen Time + Stress

**Input**:
```
Mood: "I've been staring at my computer all day and feeling overwhelmed"
Screen Time: 8.0 hours
Preferences: [mindfulness, relaxation]
Streak: 5 days
```

**AI Output**:
```json
{
  "title": "Digital Detox Walk",
  "description": "Take a 10-minute walk without your phone to reduce stress and screen fatigue",
  "duration": "10",
  "category": "physical",
  "difficulty": "easy",
  "reasoning": "High screen time and stress detected - offline movement will help reset both",
  "motivation": "Fresh air and movement are exactly what you need right now!",
  "tips": ["Leave your phone behind", "Focus on your surroundings", "Take deep breaths"]
}
```

### Scenario 2: High Energy + Low Screen Time

**Input**:
```
Mood: "I'm feeling energized and motivated to get things done!"
Screen Time: 2.0 hours
Preferences: [physical, productivity]
Streak: 12 days
```

**AI Output**:
```json
{
  "title": "Power Productivity Sprint",
  "description": "Channel your energy into a focused 15-minute task or goal",
  "duration": "15",
  "category": "productivity",
  "difficulty": "moderate",
  "reasoning": "Your high energy and balanced screen time are perfect for productive activities",
  "motivation": "Your energy is contagious! Let's make something happen!",
  "tips": ["Pick one specific task", "Set a timer", "Celebrate completion"]
}
```

### Scenario 3: Tired + Moderate Screen Time

**Input**:
```
Mood: "Feeling tired and drained after a long day"
Screen Time: 4.0 hours
Preferences: [relaxation, mindfulness]
Streak: 1 day
```

**AI Output**:
```json
{
  "title": "Gentle Evening Reset",
  "description": "5 minutes of calming breathwork to restore your energy",
  "duration": "5",
  "category": "mindfulness",
  "difficulty": "easy",
  "reasoning": "Your fatigue calls for gentle restoration without overwhelming activities",
  "motivation": "Small moments of calm create big changes in how you feel",
  "tips": ["Find a comfortable position", "Breathe slowly and deeply", "Be patient with yourself"]
}
```

## Implementation Guide

### 1. Setup Novita AI

1. Sign up at [Novita AI](https://novita.ai/)
2. Get your API key from [Key Management](https://novita.ai/settings/key-management)
3. Update the API key in `ai_agent_service.dart`

### 2. Initialize Services

```dart
final storageService = StorageService();
final screenTimeService = ScreenTimeService();
final aiAgentService = AIAgentService(storageService, screenTimeService);
```

### 3. Generate Suggestions

```dart
// Method 1: AI-Powered (Recommended)
final aiResult = await aiAgentService.generateAIPersonalizedHabitSuggestion(
  moodText: userMoodInput,
  preferences: userPreferences,
  screenTimeHours: screenTime,
  currentStreak: streak,
);

// Method 2: Smart Suggestion (Automatic screen time)
final smartResult = await aiAgentService.generateSmartHabitSuggestion(
  mood: detectedMood,
  preferences: userPreferences,
  currentStreak: streak,
);

// Method 3: Standard Suggestion (Fallback)
final standardResult = await aiAgentService.generatePersonalizedHabitSuggestion(
  mood: mood,
  preferences: preferences,
  screenTimeHours: screenTime,
  currentStreak: streak,
);
```

### 4. Handle Results

```dart
if (result['success'] == true) {
  final suggestion = result['suggestion'] as Map<String, dynamic>;
  final moodAnalysis = result['moodAnalysis'] as Map<String, dynamic>;
  final screenAnalysis = result['screenTimeAnalysis'] as Map<String, dynamic>?;
  
  // Display suggestion to user
  showHabitSuggestion(
    title: suggestion['title'],
    description: suggestion['description'],
    duration: suggestion['duration'],
    reasoning: suggestion['reasoning'],
    motivation: suggestion['motivation'],
  );
  
  // Track analytics
  trackSuggestionGenerated(
    mood: moodAnalysis['mood'],
    screenTime: screenAnalysis?['hours'],
    source: suggestion['source'],
  );
} else {
  // Handle error or fallback
  showErrorMessage('Unable to generate suggestion');
}
```

## Performance Considerations

### API Rate Limiting
- Implement request throttling for Novita AI calls
- Cache recent mood analyses to avoid redundant API calls
- Use fallback suggestions when API limits are reached

### Local Caching
- Store behavior patterns locally for offline functionality
- Cache successful suggestions for pattern learning
- Implement intelligent prefetching for common scenarios

### Error Handling
- Graceful degradation to rule-based suggestions
- Retry logic for temporary API failures
- User-friendly error messages

## Analytics and Learning

### Tracked Metrics
- Suggestion generation success rate
- User completion rates by suggestion type
- Mood detection accuracy
- Screen time correlation with habit success
- Preference evolution over time

### Learning Improvements
- Continuous refinement of AI prompts
- Behavioral pattern recognition
- Personalization algorithm optimization
- User feedback integration

## Security and Privacy

### Data Protection
- Mood text is processed securely through Novita AI
- Local storage encryption for sensitive data
- No permanent storage of personal mood descriptions
- Anonymized analytics data only

### API Security
- Secure API key management
- Request authentication and validation
- Rate limiting and abuse prevention
- Error logging without sensitive data

## Future Enhancements

### Planned Features
- **Multi-language Support**: Mood analysis in multiple languages
- **Voice Input**: Speech-to-text mood analysis
- **Contextual Learning**: Environmental factor integration
- **Social Features**: Community-driven habit suggestions
- **Advanced Analytics**: Predictive habit success modeling

### Integration Opportunities
- **Wearable Devices**: Heart rate and activity data
- **Calendar Integration**: Schedule-aware suggestions
- **Weather API**: Weather-influenced habit recommendations
- **Health Apps**: Comprehensive wellness tracking

## Troubleshooting

### Common Issues

1. **API Key Invalid**
   - Verify API key in Novita AI dashboard
   - Check key permissions and quotas
   - Ensure proper key format

2. **Mood Analysis Fails**
   - Check internet connectivity
   - Verify API endpoint accessibility
   - Review input text format

3. **Screen Time Not Available**
   - Check device permissions
   - Verify platform support
   - Use manual input fallback

4. **Suggestions Not Personalized**
   - Ensure sufficient user data
   - Check behavior pattern storage
   - Verify preference settings

### Debug Mode

Enable debug logging to troubleshoot issues:

```dart
// Enable debug mode
aiAgentService.setDebugMode(true);

// Check logs for detailed information
print('Mood Analysis: ${result['moodAnalysis']}');
print('AI Reasoning: ${result['aiReasoning']}');
print('Personalization Factors: ${result['personalizationFactors']}');
```

## Conclusion

The AI-Powered Habit Suggestion System represents a significant advancement in personalized wellness technology. By combining Novita AI's natural language processing capabilities with comprehensive user analysis, the system delivers highly relevant, contextual habit recommendations that adapt to user behavior and promote long-term success.

The system's multi-layered approach ensures reliability through fallback mechanisms while continuously learning and improving from user interactions. This creates a personalized experience that evolves with the user's journey toward better habits and overall wellness.