# 🍎 FocusFlow iOS Implementation Guide

## Overview

FocusFlow now supports iOS using Apple's Screen Time APIs, providing native app blocking capabilities similar to the Android implementation. This document outlines the iOS-specific implementation using:

- **FamilyControls**: For requesting Screen Time authorization
- **ManagedSettings**: For applying app restrictions and blocks
- **DeviceActivity**: For monitoring app usage and triggering events

## Architecture

### Native iOS Components

1. **IOSAppBlockingService.swift**
   - Main Swift service handling Screen Time API interactions
   - Manages app blocking configuration and monitoring
   - Communicates with Flutter via method channels

2. **DeviceActivityMonitorExtension.swift**
   - Handles Screen Time monitoring events
   - Applies/removes restrictions based on schedule
   - Sends notifications about blocking events

3. **AppDelegate.swift** (Updated)
   - Sets up method channels for iOS communication
   - Handles platform-specific method calls
   - Bridges iOS native functionality with Flutter

### Flutter Integration

4. **app_blocking_provider.dart** (Updated)
   - Platform-aware implementation (iOS/Android)
   - iOS-specific permission handling
   - Screen Time API method calls

5. **permissions_screen.dart** (Updated)
   - iOS-specific permission requests
   - Family Controls authorization UI
   - Platform-appropriate permission descriptions

## Key Features

### ✅ Implemented

- **Screen Time Authorization**: Request and check Family Controls permissions
- **App Blocking Configuration**: Configure which apps to block
- **Focus Mode**: Immediate blocking activation
- **Scheduled Blocking**: Time-based restrictions
- **Platform Detection**: Automatic iOS/Android behavior
- **Method Channel Communication**: Seamless Flutter-iOS integration
- **Notification Support**: Block alerts and focus reminders
- **App Group Sharing**: Data sharing between main app and extensions

### 🔄 iOS Limitations & Differences

1. **App Enumeration**: iOS doesn't allow enumerating all installed apps due to privacy. We provide a curated list of common social media apps.

2. **App Selection**: Full implementation would require users to select apps through `FamilyActivityPicker` provided by Apple.

3. **Restriction Method**: iOS uses token-based app blocking rather than overlay interruptions.

4. **Background Monitoring**: Handled by iOS system via DeviceActivity framework.

5. **Permission Model**: Uses Family Controls authorization instead of usage stats.

## Setup Requirements

### 1. Xcode Configuration

```xml
<!-- Info.plist -->
<key>NSFamilyControlsUsageDescription</key>
<string>FocusFlow needs access to Screen Time controls to help you block distracting apps during focus sessions.</string>

<key>com.apple.developer.family-controls</key>
<true/>

<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.focusflow.productivity</string>
</array>
```

### 2. iOS Version Requirements

- **Minimum iOS Version**: 15.0 (Screen Time APIs introduced)
- **Recommended**: iOS 16.0+ for enhanced functionality

### 3. App Store Requirements

- Family Controls capability must be enabled in Xcode
- App Store Connect configuration for Screen Time entitlement
- Privacy policy must mention Screen Time usage

## Usage Flow

### 1. Permission Request
```swift
// User taps "Enable Screen Time" in permissions screen
let success = await blockingProvider.requestIOSAuthorization()
```

### 2. App Configuration
```swift
// Configure which apps to block
await iosBlockingService.configureBlockedApps(appIdentifiers: ["com.instagram.phoenix", "com.tiktok.app"])
```

### 3. Start Monitoring
```swift
// Start monitoring with optional schedule
await iosBlockingService.startMonitoring(
    focusMode: false,
    startHour: 9,
    startMinute: 0,
    endHour: 17,
    endMinute: 0
)
```

### 4. Focus Mode
```swift
// Enable immediate blocking
await iosBlockingService.enableFocusMode()
```

## Method Channel API

### iOS-Specific Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `requestIOSAuthorization` | Request Family Controls auth | None |
| `getIOSAuthorizationStatus` | Check current auth status | None |
| `configureBlockedApps` | Set which apps to block | `appIdentifiers: [String]` |
| `startIOSMonitoring` | Begin Screen Time monitoring | `focusMode, startHour, startMinute, endHour, endMinute` |
| `stopIOSMonitoring` | Stop monitoring | None |
| `enableIOSFocusMode` | Activate immediate blocking | None |
| `disableIOSFocusMode` | Deactivate immediate blocking | None |

### Cross-Platform Methods

| Method | iOS Behavior | Android Behavior |
|--------|-------------|------------------|
| `getInstalledApps` | Returns curated app list | Enumerates all apps |
| `hasUsageStatsPermission` | Checks Family Controls auth | Checks usage stats permission |
| `startBlockingService` | Calls `startIOSMonitoring` | Starts foreground service |
| `stopBlockingService` | Calls `stopIOSMonitoring` | Stops foreground service |

## Development Notes

### Testing on iOS

1. **Simulator Limitations**: Screen Time APIs don't work in simulator. Test on physical device.

2. **Debug Mode**: Family Controls may behave differently in debug vs release builds.

3. **Entitlements**: Ensure proper entitlements are configured in Xcode.

### Common Issues

1. **Authorization Denied**: User must grant Family Controls permission in iOS Settings.

2. **App Selection**: Consider implementing FamilyActivityPicker for full app selection.

3. **Background Execution**: DeviceActivity monitoring happens in system extension.

### Future Enhancements

1. **FamilyActivityPicker Integration**: Allow users to select any installed app
2. **Category Blocking**: Block entire app categories (Social, Games, etc.)
3. **Time Limits**: Implement usage time limits per app
4. **Parental Controls**: Multi-user family management
5. **Widget Support**: Screen Time widgets for quick access

## File Structure

```
ios/
├── Runner/
│   ├── IOSAppBlockingService.swift           # Main iOS blocking service
│   ├── DeviceActivityMonitorExtension.swift  # Screen Time event handling
│   ├── AppDelegate.swift                     # Updated with method channels
│   └── Info.plist                           # Updated with permissions
└── Runner.xcodeproj/                         # Xcode project config
```

## Platform Comparison

| Feature | Android Implementation | iOS Implementation |
|---------|----------------------|-------------------|
| **App Detection** | Usage Stats API | DeviceActivity API |
| **Blocking Method** | Overlay interruption | ManagedSettings restriction |
| **Permission Model** | Usage Stats + Overlay | Family Controls authorization |
| **Background Service** | Foreground service | System DeviceActivity monitoring |
| **App Enumeration** | Full system access | Privacy-limited + curated list |
| **Customization** | High (overlays, intents) | Limited (system restrictions) |

## Conclusion

The iOS implementation provides equivalent functionality to Android while respecting iOS privacy and security models. The Screen Time API integration ensures system-level blocking that cannot be bypassed, making it highly effective for digital wellness use cases.

For production deployment, additional testing and potentially App Store review is recommended due to the sensitive nature of Screen Time permissions.