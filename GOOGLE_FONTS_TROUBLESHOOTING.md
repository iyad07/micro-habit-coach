# Google Fonts Troubleshooting Guide

## Issue Description

The app may encounter network connectivity issues when trying to load Google Fonts, resulting in errors like:

```
Exception: Failed to load font with url `https://fonts.gstatic.com/s/a/...`
ClientException with SocketException: Failed host lookup: 'fonts.gstatic.com'
```

## Root Cause

This error occurs when:
1. **Network connectivity issues** - No internet connection or restricted access to fonts.gstatic.com
2. **Firewall restrictions** - Corporate or institutional firewalls blocking Google Fonts
3. **DNS resolution problems** - Unable to resolve fonts.gstatic.com domain
4. **Regional restrictions** - Some regions may have limited access to Google services

## Solution Implemented

### 1. FontHelper Utility Class

We've created a `FontHelper` utility class (`lib/utils/font_helper.dart`) that provides:

- **Automatic fallback** to system fonts when Google Fonts fail to load
- **Error handling** with proper logging
- **Consistent API** that matches GoogleFonts usage

### 2. Usage Examples

#### Before (Problematic):
```dart
style: GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.white,
)
```

#### After (Safe):
```dart
style: FontHelper.poppins(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.white,
)
```

### 3. Text Theme Configuration

In `main.dart`, we use the FontHelper for the app's text theme:

```dart
textTheme: FontHelper.poppinsTextTheme(
  Theme.of(context).textTheme,
).apply(
  bodyColor: Colors.white,
  displayColor: Colors.white,
),
```

## Migration Guide

To update existing code:

1. **Add import**: `import '../utils/font_helper.dart';`
2. **Replace GoogleFonts.poppins()** with **FontHelper.poppins()**
3. **Replace GoogleFonts.poppinsTextTheme()** with **FontHelper.poppinsTextTheme()**

## Benefits

✅ **Graceful degradation** - App continues to work even without internet
✅ **Better user experience** - No crashes due to font loading failures
✅ **Consistent styling** - Maintains visual consistency with fallback fonts
✅ **Error logging** - Helps identify connectivity issues during development

## Testing

To test the fallback behavior:

1. **Disable internet connection**
2. **Run the app**
3. **Verify** that the app loads with system fonts instead of crashing

## Alternative Solutions

### Option 1: Bundle Fonts Locally

1. Download Poppins font files
2. Add to `assets/fonts/` directory
3. Configure in `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
```

### Option 2: Conditional Font Loading

```dart
Future<bool> checkConnectivity() async {
  try {
    final result = await InternetAddress.lookup('fonts.gstatic.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
```

## Best Practices

1. **Always use FontHelper** instead of direct GoogleFonts calls
2. **Test offline scenarios** during development
3. **Monitor font loading errors** in production
4. **Consider bundling critical fonts** for offline-first apps

## Troubleshooting Steps

If you encounter font loading issues:

1. **Check internet connectivity**
2. **Verify DNS resolution**: `nslookup fonts.gstatic.com`
3. **Test with different networks** (mobile data vs WiFi)
4. **Check firewall/proxy settings**
5. **Use FontHelper utility** for automatic fallback

## Related Resources

- [Flutter Networking Documentation](https://docs.flutter.dev/development/data-and-backend/networking)
- [Google Fonts Package Issues](https://github.com/material-foundation/flutter-packages/issues)
- [Flutter Font Configuration](https://docs.flutter.dev/cookbook/design/fonts)