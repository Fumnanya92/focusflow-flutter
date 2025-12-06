# FocusFlow - Mobile App for Digital Wellbeing

A Flutter mobile application designed to help users reduce social media addiction, stay present, regain focus, and build healthier digital habits through gamification, app blocking, and productivity tools.

## Features

### Core Features
- **App Blocking System**: Block distracting apps with customizable rules and overlay interruptions
- **Focus Timer**: Pomodoro-style timer with strict app blocking during sessions
- **Task Management**: To-do list with rewards and daily focus planning
- **Streak System**: Build habits with daily streaks and streak protection
- **Phone-Down Challenge**: Group social challenges to stay off your phone
- **Gamification**: XP points, badges, levels, and monthly leaderboards
- **Analytics**: Track screen time, blocked apps, and productivity metrics

### Technical Features
- Background service monitoring
- Overlay permission handling
- Usage stats tracking
- Sensor integration for challenge detection
- Local data persistence with Hive
- Provider state management
- Material Design 3 with custom theme

## Project Structure

```
focusflow_flutter/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme.dart          # App theme with colors matching Stitch UI
│   │   ├── router.dart         # GoRouter navigation configuration
│   │   ├── constants.dart      # App-wide constants
│   │   └── utils/              # Utility functions
│   │
│   ├── features/
│   │   ├── onboarding/         # Welcome & permissions flow
│   │   ├── auth/               # Login & signup
│   │   ├── dashboard/          # Main dashboard with streaks & stats
│   │   ├── focus/              # Focus timer functionality
│   │   ├── tasks/              # Task management
│   │   ├── challenges/         # Phone-down challenge
│   │   ├── blocking/           # App blocking & overlay system
│   │   ├── analytics/          # Usage analytics & charts
│   │   ├── rewards/            # XP, badges, levels
│   │   └── settings/           # App settings
│   │
│   └── shared/
│       └── widgets/            # Reusable UI components
│
├── assets/
│   ├── fonts/                  # Plus Jakarta Sans fonts
│   ├── images/
│   ├── icons/
│   ├── animations/
│   └── sounds/
│
└── android/                    # Android-specific configuration
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code with Flutter extensions
- Android SDK
- Git

### Installation Steps

1. **Clone or create the project**
```bash
cd C:\Users\DELL.COM\Desktop\Darey\focusflow_flutter
```

2. **Create directory structure**

On Windows, run:
```bash
setup.bat
```

On Mac/Linux, run:
```bash
chmod +x setup.sh
./setup.sh
```

3. **Install dependencies**
```bash
flutter pub get
```

4. **Download and add fonts**
- Visit https://fonts.google.com/specimen/Plus+Jakarta+Sans
- Download the font family
- Extract and copy these files to `assets/fonts/`:
  - PlusJakartaSans-Regular.ttf
  - PlusJakartaSans-Medium.ttf
  - PlusJakartaSans-Bold.ttf
  - PlusJakartaSans-ExtraBold.ttf

5. **Configure Android Permissions**

Edit `android/app/src/main/AndroidManifest.xml` and add:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
        tools:ignore="ProtectedPermissions"/>
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    
    <application
        android:label="FocusFlow"
        android:icon="@mipmap/ic_launcher">
        <!-- Your app content -->
    </application>
</manifest>
```

6. **Run the app**
```bash
flutter run
```

## Design System

### Colors
- **Primary**: `#19E66B` - Bright green for CTAs and highlights
- **Primary Teal**: `#2D7A79` - Teal variant for accents
- **Accent**: `#F59E0B` - Amber for streaks and rewards
- **Background Light**: `#F6F8F7`
- **Background Dark**: `#112117`
- **Surface Dark**: `#1A3224`

### Typography
- **Font Family**: Plus Jakarta Sans
- **Weights**: Regular (400), Medium (500), Bold (700), ExtraBold (800)

### Border Radius
- Small: 8px
- Medium: 16px (default)
- Large: 24px
- XLarge: 32px
- Full: 9999px (pills)

## Key Packages

- **State Management**: `provider`
- **Navigation**: `go_router`
- **Local Storage**: `hive`, `shared_preferences`
- **Permissions**: `permission_handler`
- **App Usage**: `usage_stats`, `device_apps`
- **Overlay**: `flutter_overlay_window`, `system_alert_window`
- **Background**: `workmanager`, `flutter_foreground_task`
- **Notifications**: `flutter_local_notifications`
- **Sensors**: `sensors_plus`
- **UI**: `google_fonts`, `fl_chart`, `lottie`

## Development Roadmap

### Phase 1 - MVP (Current)
- [x] Project structure setup
- [x] Theme and design system
- [x] Main dashboard UI
- [x] Overlay screen UI
- [ ] Complete all placeholder screens
- [ ] Implement app blocking service
- [ ] Add local data persistence
- [ ] Permission handling flow

### Phase 2 - Core Features
- [ ] Focus timer functionality
- [ ] Task management system
- [ ] Streak tracking
- [ ] Background service for app monitoring
- [ ] Overlay trigger system

### Phase 3 - Social Features
- [ ] Phone-down challenge (multiplayer)
- [ ] QR code sharing
- [ ] Friend connections
- [ ] Leaderboards

### Phase 4 - Gamification
- [ ] XP and leveling system
- [ ] Badge achievements
- [ ] Reward animations
- [ ] Progress tracking

### Phase 5 - Analytics & Cloud
- [ ] Advanced analytics
- [ ] Cloud sync
- [ ] AI-driven insights
- [ ] Predictive blocking

## Android-Specific Notes

### Battery Optimization
The app requires battery optimization exemption to run the background monitoring service reliably. This is requested during the permissions flow.

### Overlay Permission
The overlay permission is critical for showing interruption screens when users try to open blocked apps.

### Usage Stats Permission
This special permission requires users to manually enable it in Settings. The app guides users through this process.

## Testing

Run tests with:
```bash
flutter test
```

Build APK:
```bash
flutter build apk --release
```

## Contributing

This is a personal project. For questions or suggestions, please reach out to the development team.

## License

Proprietary - All rights reserved

## Support

For issues or questions:
- Create an issue in the project repository
- Contact the development team

---

**Built with Flutter 💙 | Designed with Stitch**
