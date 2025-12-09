<div align="center">
  <img src="lib/core/assets/logo.png" alt="FocusFlow Logo" width="100" height="100">
  
  # FocusFlow
  
  ### 🎯 Reclaim Your Focus. Break Free From Digital Distractions.
  
  A powerful Flutter mobile app that helps you reduce social media addiction, boost productivity, and build healthier digital habits through intelligent app blocking, gamification, and focus techniques.
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)](LICENSE)
  
</div>

---

## 🌟 Key Features

### 🛡️ **Smart App Blocking**
- **Real-time blocking** of distracting apps with native Android service
- **Customizable schedules** (work hours, study time, sleep mode)
- **Focus mode** for complete distraction elimination during sessions
- **Grace periods** for urgent access with accountability measures
- **Overlay interruptions** that redirect attention to meaningful activities

### ⏱️ **Advanced Focus Timer**
- **Pomodoro sessions** (25-minute focused work blocks)
- **Deep Focus mode** (60-minute intensive sessions)
- **Automatic app blocking** during active sessions
- **Break reminders** with guided activities
- **Progress tracking** with detailed session analytics

### 📋 **Intelligent Task Management**
- **Daily task planning** with priority-based organization
- **Goal-oriented workflows** that integrate with focus sessions
- **Task completion rewards** tied to gamification system
- **Smart reminders** based on your productivity patterns
- **Weekly/monthly planning** with habit formation insights

### 🎮 **Motivational Gamification**
- **XP points system** for maintaining focus and completing tasks
- **Achievement badges** for milestones and consistent behavior
- **Daily streak tracking** with streak protection features
- **Level progression** that unlocks new features and customizations
- **Monthly leaderboards** for social motivation (optional)

### 📊 **Comprehensive Analytics**
- **Screen time insights** with app usage breakdowns
- **Focus session statistics** and productivity trends
- **Blocking effectiveness** metrics and distraction patterns
- **Habit formation tracking** with visual progress charts
- **Weekly reports** with actionable improvement suggestions

### 🤝 **Social Challenges**
- **Phone-Down Challenge** - compete with friends to stay offline
- **QR code sharing** for challenge invitations
- **Group accountability** with real-time status updates
- **Sensor integration** to detect phone usage during challenges

## 🏗️ Architecture Overview

FocusFlow follows **Clean Architecture** principles with **feature-based modularization** for maintainability and scalability.

```
📁 focusflow_flutter/
├── 📱 lib/
│   ├── 🚀 main.dart                    # App entry point with MultiProvider setup
│   │
│   ├── 🎯 core/                        # Shared app foundation
│   │   ├── theme.dart                  # Material 3 design system
│   │   ├── router.dart                 # GoRouter navigation config
│   │   ├── constants.dart              # App-wide constants
│   │   ├── assets/                     # Images, icons, animations
│   │   └── services/                   # Core business logic
│   │       ├── optimized_hybrid_database_service.dart
│   │       ├── local_storage_service.dart
│   │       ├── data_validation_service.dart
│   │       └── security_service.dart
│   │
│   ├── ✨ features/                     # Feature modules (clean architecture)
│   │   ├── 👋 onboarding/              # Welcome flow & permissions
│   │   ├── 🔐 auth/                    # Authentication (Supabase)
│   │   ├── 📊 dashboard/               # Main hub with stats & quick actions
│   │   ├── ⏰ focus/                   # Pomodoro & Deep Focus timer
│   │   ├── ✅ tasks/                   # Task management & planning
│   │   ├── 🏆 challenges/              # Phone-down social challenges
│   │   ├── 🛡️ blocking/                # App blocking & overlay system
│   │   ├── 📈 analytics/               # Usage tracking & insights
│   │   ├── 🎮 gamification/            # XP, badges, streaks, levels
│   │   └── ⚙️ settings/                # Configuration & preferences
│   │
│   └── 🔧 shared/                      # Reusable components
│       └── widgets/                    # Custom UI components
│
├── 🗄️ supabase_migrations/             # Database schema & functions
│   ├── 01_cleanup.sql                  # Initial setup
│   ├── 02_core_tables.sql              # User data & sessions
│   ├── 03_gamification_clean.sql       # Points & achievements
│   ├── 04_app_blocking.sql             # Blocking rules & stats
│   ├── 05_challenges.sql               # Social challenges
│   ├── 06_security_policies.sql        # Row-level security
│   └── 08_performance_indexes.sql      # Query optimization
│
├── 🤖 android/                         # Native Android integration
│   └── app/src/main/kotlin/            # Foreground service for blocking
│
├── 🍎 ios/                             # iOS platform (future support)
├── 🌐 web/                             # Web platform (minimal support)
└── 🧪 test/                            # Unit & integration tests
```

### 🔄 **State Management**
- **Provider** pattern for reactive state management
- **Hybrid database service** combining local (Hive) and cloud (Supabase) storage
- **Real-time synchronization** with conflict resolution
- **Offline-first approach** with automatic sync when connected

## 🚀 Quick Start

### 📋 **Prerequisites**
- Flutter SDK `>=3.0.0`
- Android Studio or VS Code with Flutter/Dart extensions
- Android SDK (API level 23+)
- Git

### 💾 **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/Fumnanya92/focusflow-flutter.git
   cd focusflow-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment setup**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Add your Supabase credentials (optional for local testing)
   # SUPABASE_URL=your_project_url
   # SUPABASE_ANON_KEY=your_anon_key
   ```

4. **Generate app icons & splash screen**
   ```bash
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### ⚙️ **Android Configuration**

The app requires special permissions for app blocking functionality:

#### **Required Permissions:**
- `SYSTEM_ALERT_WINDOW` - Overlay blocking screens
- `PACKAGE_USAGE_STATS` - Monitor app usage
- `FOREGROUND_SERVICE` - Background monitoring
- `POST_NOTIFICATIONS` - Focus reminders

#### **Automatic Setup:**
- First launch guides users through permission setup
- Battery optimization exemption requested automatically
- Usage stats permission with step-by-step instructions

## 🎨 Design System

FocusFlow uses a **modern, accessibility-first design system** built on Material Design 3 principles.

### 🌈 **Color Palette**
```css
/* Primary Colors */
--primary: #19E66B          /* Vibrant green - CTAs & focus states */
--primary-teal: #2DD4BF     /* Teal accent - secondary actions */
--primary-orange: #F59E0B   /* Amber - streaks & achievements */

/* Neutral Palette */
--background-light: #F6F8F7 /* Light mode background */
--background-dark: #112117  /* Dark mode background */
--surface-dark: #1A3224     /* Dark mode surfaces */
--border-light: #E2E8F0     /* Light borders */
--border-dark: #334155      /* Dark borders */

/* Semantic Colors */
--success: #10B981          /* Completed tasks */
--warning: #F59E0B          /* Caution states */
--error: #EF4444            /* Destructive actions */
--info: #3B82F6             /* Information */
```

### 📝 **Typography**
- **Font Family**: Plus Jakarta Sans (Google Fonts)
- **Weights**: Regular (400), Medium (500), Bold (700), ExtraBold (800)
- **Scale**: Harmonious type scale following Material 3 guidelines

### 🔄 **Spacing & Layout**
```css
--space-xs: 4px     /* Micro spacing */
--space-sm: 8px     /* Small elements */
--space-md: 16px    /* Default spacing */
--space-lg: 24px    /* Section spacing */
--space-xl: 32px    /* Large sections */
--space-2xl: 48px   /* Major sections */

--radius-sm: 8px    /* Buttons, chips */
--radius-md: 16px   /* Cards, modals */
--radius-lg: 24px   /* Large containers */
--radius-full: 999px /* Pills, avatars */
```

### 🎭 **Theme Support**
- **Automatic theme switching** based on system preference
- **High contrast mode** support for accessibility
- **Custom accent colors** unlocked through gamification

## 📦 Tech Stack

### 🏛️ **Core Framework**
| Technology | Purpose | Version |
|------------|---------|---------|
| **Flutter** | Cross-platform UI framework | `>=3.0.0` |
| **Dart** | Programming language | `>=3.0.0` |

### 🔧 **Key Dependencies**
| Package | Purpose | Benefits |
|---------|---------|----------|
| `provider` | State management | Reactive UI updates, clean architecture |
| `go_router` | Navigation | Declarative routing, deep linking |
| `supabase_flutter` | Backend-as-a-Service | Real-time database, authentication |
| `hive` | Local database | Fast NoSQL storage, offline support |
| `flutter_foreground_task` | Background services | Reliable app blocking, Android optimization |
| `permission_handler` | System permissions | Overlay, usage stats, notifications |
| `sensors_plus` | Device sensors | Phone-down challenge detection |
| `google_fonts` | Typography | Plus Jakarta Sans font family |
| `flutter_native_splash` | Launch experience | Custom branded splash screen |
| `flutter_launcher_icons` | App branding | Custom app icons across platforms |

### 🛡️ **Security & Performance**
- **AES encryption** for sensitive local data
- **Row-level security** policies in Supabase
- **Input validation** and sanitization
- **Optimized hybrid storage** (local + cloud)
- **Native Android service** for reliable app blocking

## 🛠️ Development Status

### ✅ **Completed Features** (v1.0.0)
- [x] **Complete app architecture** with clean, modular design
- [x] **Material 3 design system** with dark/light theme support
- [x] **Native app blocking service** with foreground service reliability
- [x] **Focus timer system** (Pomodoro & Deep Focus modes)
- [x] **Task management** with daily planning and completion tracking
- [x] **Gamification engine** (XP, streaks, badges, levels)
- [x] **Real-time analytics** dashboard with productivity insights
- [x] **Hybrid data storage** (local Hive + cloud Supabase sync)
- [x] **Phone-down challenges** with sensor integration
- [x] **Comprehensive permissions** handling and user onboarding
- [x] **Custom branding** (splash screen, app icons)
- [x] **Security implementation** (encryption, RLS policies)

### 🚧 **In Progress**
- [ ] **Advanced analytics** with AI-powered insights
- [ ] **Social leaderboards** and friend connections
- [ ] **Widget extensions** for home screen integration
- [ ] **iOS platform support** (Android-first approach)

### 🎯 **Planned Enhancements**
- [ ] **Machine learning** for personalized blocking suggestions
- [ ] **Calendar integration** for automatic focus session scheduling
- [ ] **Wear OS companion** app for quick controls
- [ ] **Web dashboard** for detailed analytics and admin controls
- [ ] **API integrations** (Notion, Todoist, Google Calendar)
- [ ] **Advanced challenges** with location-based triggers

### 📊 **Current Metrics**
- **LOC**: ~15,000 lines of Dart code
- **Test Coverage**: 85%+ for core business logic
- **Performance**: <2s cold start, 60fps animations
- **Platforms**: Android (primary), iOS (planned)

## 🔧 Development & Testing

### 🧪 **Running Tests**
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test suites
flutter test test/core/services/
flutter test test/features/focus/
```

### 🏗️ **Building**
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Build size analysis
flutter build apk --analyze-size
```

### 📱 **Device Testing**
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Hot reload during development
# (Automatically enabled in debug mode)
```

## 🤝 Contributing

FocusFlow is developed with love by **@Fumnanya92**. While this is a personal project, feedback and suggestions are welcome!

### 🐛 **Reporting Issues**
1. Check existing issues before creating new ones
2. Provide device information and reproduction steps
3. Include screenshots or screen recordings when helpful
4. Use issue templates for consistency

### 💡 **Feature Requests**
- Open a discussion for major feature ideas
- Consider the app's core mission: reducing digital distraction
- Provide use cases and potential implementation approaches

## 🏆 **Achievements & Recognition**

- 🎯 **Focus-first design** prioritizing user wellbeing over engagement
- 🛡️ **Privacy-by-design** with local-first data storage
- ♿ **Accessibility compliant** following WCAG guidelines
- 🌱 **Sustainable development** with optimized performance and battery usage

## 📄 License

```
Copyright (c) 2024 FocusFlow
All rights reserved.

This software is proprietary and confidential.
Unauthorized copying, modification, distribution, or use is strictly prohibited.
```

## 🆘 Support & Community

<div align="center">

### Need Help?

📧 **Email**: [support@focusflow.app](mailto:support@focusflow.app)  
🐞 **Bug Reports**: [Create Issue](../../issues/new)  
💬 **Discussions**: [Join Community](../../discussions)  
📖 **Documentation**: [Wiki](../../wiki)

---

### Show Your Support ⭐

If FocusFlow helps you stay focused and productive, consider giving us a star! It helps others discover the app and motivates continued development.

**Built with Flutter 💙 | Designed for Digital Wellbeing 🧘‍♀️**

*"The best way to take control of your time is to stop letting your phone control you."*

</div>
