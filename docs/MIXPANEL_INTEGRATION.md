# Mixpanel Analytics Integration

This document describes how the analytics implementation works in the Miniature Paint Finder app, specifically focused on non-blocking behavior to avoid interfering with critical app functions like authentication.

## Overview

The app uses a simplified analytics implementation that avoids direct dependencies on third-party SDKs like Mixpanel. Instead, we've created a custom implementation that:

1. Initializes in a non-blocking way
2. Won't interfere with critical app flows
3. Allows easy enabling/disabling of tracking
4. Provides a clean API for tracking events

## Components

### MixpanelService

Located in `lib/services/mixpanel_service.dart`, this is the core service that handles event tracking. It's designed to be:

- Non-blocking: Initialization happens in a background task
- Fault-tolerant: Errors are caught and logged without affecting the app
- Easy to disable: Has enable/disable methods to turn tracking on/off

### AnalyticsRouteObserver

Located in `lib/utils/analytics_route_observer.dart`, this component automatically tracks screen views as the user navigates through the app.

### ScreenAnalytics

Located in `lib/screens/screen_analytics.dart`, this provides a mixin and wrapper classes to easily add analytics tracking to screens.

### AuthAnalyticsService

Located in `lib/services/auth_analytics_service.dart`, this is a specialized service for tracking authentication events like login, signup, and logout.

## Usage

### Tracking Screen Views

There are three ways to track screen views:

1. **Automatic via RouteObserver**: Add names to your routes for better tracking
   ```dart
   MaterialApp(
     navigatorObservers: [analyticsRouteObserver],
     routes: {
       '/': (context) => const AuthScreen(),
       '/home': (context) => const HomeScreen(),
     },
   )
   ```

2. **Using the ScreenAnalytics mixin**:
   ```dart
   class MyScreenState extends State<MyScreen> with ScreenAnalytics {
     @override
     String get screenName => 'My Screen Name';
     
     // Rest of your state implementation
   }
   ```

3. **Using the ScreenViewTracker widget**:
   ```dart
   ScreenViewTracker(
     screenName: 'My Screen',
     child: MyWidget(),
   )
   ```

### Tracking Custom Events

```dart
// From any widget with the ScreenAnalytics mixin
trackEvent('Button Clicked', {'button_name': 'Submit'});

// Or directly using the service
MixpanelService().trackEvent('Button Clicked', {'button_name': 'Submit'});
```

### Tracking Auth Events

```dart
final analytics = AuthAnalyticsService();

// After successful login
analytics.trackLogin('email', user.id);

// After successful registration
analytics.trackRegistration('google', user.id);

// When auth fails
analytics.trackAuthFailure('email', 'Wrong password');

// When user logs out
analytics.trackLogout();
```

## Best Practices

1. **Never block the UI thread**: Always use non-blocking calls for analytics operations
2. **Handle errors gracefully**: Catch exceptions in analytics code to prevent app crashes
3. **Respect user privacy**: Only track what's necessary and avoid personally identifiable information
4. **Use descriptive event names**: Make event names clear and consistent
5. **Add meaningful properties**: Include relevant data with events to make analysis easier

## Troubleshooting

If you encounter issues with the analytics implementation:

1. Check the logs for any error messages related to analytics
2. Try disabling analytics temporarily to see if issues persist
3. Ensure all tracking calls are wrapped in try/catch blocks
4. Verify that initialization is truly non-blocking

## Future Improvements

1. Add actual Mixpanel SDK integration behind our abstraction layer
2. Add opt-in/opt-out functionality for users
3. Implement more advanced tracking features like funnels and cohorts
4. Add automatic session tracking 