# Screen Time Implementation Guide

## Overview

This document describes the implementation of screen time data collection and analysis functionality in the Micro Habit Tracker app. The system automatically collects device screen time data and uses it to generate personalized habit suggestions.

## Features Implemented

### 1. Screen Time Data Collection
- **Automatic Collection**: Collects screen time data directly from the device
- **Cross-Platform Support**: Uses platform-specific APIs for optimal performance
- **Permission Management**: Handles permission requests and user consent
- **Fallback Support**: Works with manual data input when automatic collection isn't available

### 2. Data Analysis
- **Screen Time Categorization**: Classifies usage as low, moderate, or high
- **App Usage Analysis**: Identifies top apps and usage patterns
- **Break Duration Calculation**: Suggests optimal break times based on usage
- **Trend Analysis**: Tracks patterns over time

### 3. AI Integration
- **Smart Habit Suggestions**: Uses screen time data to suggest relevant habits
- **Personalized Recommendations**: Adapts suggestions based on usage patterns
- **Balance Optimization**: Promotes healthy digital consumption habits

## Implementation Details

### Dependencies Added

```yaml
# Screen time and app usage tracking
usage_stats: ^1.3.0
app_usage: ^3.0.0
permission_handler: ^11.1.0
```

### Key Components

#### 1. ScreenTimeService (`lib/services/screen_time_service.dart`)
- Core service for screen time data collection
- Handles platform-specific implementations
- Manages permissions and error handling

#### 2. Enhanced AIAgentService
- Integrated screen time analysis with existing AI logic
- Automatic data collection in habit suggestion generation
- Smart recommendations based on screen time patterns

#### 3. ScreenTimeWidget (`lib/widgets/screen_time_widget.dart`)
- UI component for displaying screen time information
- Permission request handling
- Real-time data updates

#### 4. Home Screen Integration
- Added screen time widget to main interface
- Seamless integration with existing UI

### Android Permissions

Added to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Screen time and app usage permissions -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

## Usage Examples

### Basic Screen Time Analysis

```dart
final aiAgent = AIAgentService();

// Automatic data collection and analysis
final analysis = await aiAgent.analyzeScreenTimeAndUsage();
print('Screen time: ${analysis['screenTimeHours']}h');
print('Level: ${analysis['screenTimeLevel']}');
print('Recommendation: ${analysis['recommendation']}');
```

### Smart Habit Suggestions

```dart
// Generate habit suggestions with automatic screen time integration
final suggestion = await aiAgent.generateSmartHabitSuggestion(
  mood: UserMood.stressed,
  preferences: [HabitCategory.mindfulness],
);
```

### Permission Management

```dart
// Check support and permissions
if (aiAgent.isScreenTimeSupported()) {
  if (!await aiAgent.hasScreenTimePermissions()) {
    await aiAgent.requestScreenTimePermissions();
  }
}
```

### Manual Data Input (Fallback)

```dart
// For testing or unsupported platforms
final analysis = await aiAgent.analyzeScreenTimeAndUsage(
  5.5, // hours
  {'com.instagram.android': 2.0}, // app usage
);
```

## Platform Support

### Android
- ✅ **Fully Supported**: Uses `usage_stats` package for native Android APIs
- ✅ **Permission Handling**: Automatic permission requests
- ✅ **App Usage Details**: Detailed per-app usage statistics

### iOS
- ⚠️ **Limited Support**: Requires special Apple approval for Screen Time API
- ✅ **Fallback Available**: Manual input and cross-platform package support
- ℹ️ **Future Enhancement**: Can be implemented with proper Apple developer approval

### Other Platforms
- ✅ **Fallback Support**: Manual data input
- ✅ **Cross-Platform Package**: Basic usage statistics where available

## Screen Time Categories

| Category | Hours | Description | Recommendations |
|----------|-------|-------------|----------------|
| **Low** | < 3h | Excellent balance | Continue balanced approach |
| **Moderate** | 3-6h | Good balance | Add offline activities |
| **High** | > 6h | Consider breaks | Regular breaks, physical activities |

## Habit Suggestions Based on Screen Time

### High Screen Time (>6h)
- Take a 10-minute walk without your phone
- Practice 5 minutes of deep breathing
- Do stretching exercises
- 20-20-20 rule: Look at something 20 feet away for 20 seconds every 20 minutes

### Moderate Screen Time (3-6h)
- Read a few pages of a book
- Practice mindful breathing for 3 minutes
- Do a quick tidy-up of your space
- Try a creative hobby

### Low Screen Time (<3h)
- Continue your balanced approach
- Explore new creative activities
- Maintain current healthy habits

## Error Handling

The implementation includes comprehensive error handling:

1. **Permission Denied**: Graceful fallback to manual input
2. **Platform Not Supported**: Clear messaging and alternative options
3. **Data Collection Errors**: Fallback to previous data or defaults
4. **Network Issues**: Local data processing and caching

## Privacy and Security

- **Local Processing**: All screen time data is processed locally on the device
- **No External Transmission**: Data is not sent to external servers
- **User Consent**: Clear permission requests and explanations
- **Data Minimization**: Only collects necessary usage statistics

## Testing

Use the provided example file (`lib/examples/screen_time_usage_example.dart`) to test the implementation:

```dart
// Run complete workflow demo
await ScreenTimeUsageExample.completeWorkflowDemo();
```

## Future Enhancements

1. **iOS Screen Time API**: Implement with proper Apple approval
2. **Historical Analysis**: Track screen time trends over weeks/months
3. **App Category Analysis**: Categorize apps (social, productivity, entertainment)
4. **Smart Notifications**: Proactive break reminders based on usage
5. **Integration with Health Apps**: Connect with Apple Health/Google Fit
6. **Machine Learning**: Predictive habit suggestions based on usage patterns

## Troubleshooting

### Common Issues

1. **Permission Not Granted**
   - Solution: Guide user to Settings > Apps > Special Access > Usage Access
   - Fallback: Use manual input mode

2. **No Data Available**
   - Check if device supports usage stats
   - Verify app has been used for at least a few hours
   - Try manual refresh

3. **Platform Not Supported**
   - Use manual input functionality
   - Consider cross-platform alternatives

### Debug Commands

```dart
// Check support status
print('Supported: ${aiAgent.isScreenTimeSupported()}');
print('Permissions: ${await aiAgent.hasScreenTimePermissions()}');
print('Message: ${aiAgent.getScreenTimeSupportMessage()}');
```

## Conclusion

The screen time implementation provides a comprehensive solution for collecting and analyzing device usage data to enhance habit suggestions. The system is designed to be robust, privacy-focused, and user-friendly, with appropriate fallbacks for different platforms and scenarios.

The integration with the existing AI agent service ensures that screen time data seamlessly enhances the personalization of habit recommendations, helping users maintain a healthy balance between digital consumption and offline activities.