# 👨‍👩‍👧‍👦 FocusFlow Parent-Child Control System

## 🎯 Core Concept

**Remote Parental Control** - Parents can control their children's devices from their own phone, anywhere in the world.

### ⚡ Key Features
- **Instant Remote Lock**: Parent taps "Lock Now" → Child's device locks immediately
- **Scheduled Rules**: Automatic blocking during school, bedtime, meal times
- **Real-time Control**: Works from anywhere with internet connection
- **System-level Enforcement**: Cannot be bypassed by closing app or restarting device

---

## 👥 Account System Design

### 🔑 Account Types

#### **1️⃣ Parent Account**
```
Role: PARENT
Permissions:
  ✅ Create child profiles
  ✅ Set rules and schedules
  ✅ Remote lock/unlock
  ✅ View usage analytics
  ✅ Manage multiple children
```

#### **2️⃣ Child Account**
```
Role: CHILD
Permissions:
  ❌ Cannot change settings
  ❌ Cannot disable app
  ❌ Cannot unlink from parent
  ✅ Request unlock (parent approves)
  ✅ View their own schedule
```

---

## 🔗 Device Linking Flow

### **Option A: Parent-Initiated Setup** (Recommended)

1. **Parent Phone Setup**
   ```
   Parent → Install FocusFlow → Create Parent Account
   Parent → Add Child → "Setup Child Device"
   Parent → Gets linking code/QR: "ABC123"
   ```

2. **Child Device Setup**
   ```
   Child Device → Install FocusFlow → "I'm a Child"
   Enter linking code: "ABC123"
   Parent approves connection
   Device becomes managed child device
   ```

### **Option B: Direct Login Setup**

1. **Parent on Child's Device**
   ```
   Parent → Use child's device
   Parent → Login with their account
   Parent → "Set up this device for [Child Name]"
   Device auto-becomes child device
   ```

---

## 🏗️ Technical Architecture

### **Real-time Communication Stack**
```
Parent Phone ←→ Supabase Realtime ←→ Child Device

Components:
- Supabase Realtime subscriptions
- Push notifications (backup)
- WebSocket connections
- Command queue system
```

### **Database Schema**
```sql
-- Family management
families (
  id UUID PRIMARY KEY,
  parent_user_id UUID REFERENCES auth.users,
  family_name TEXT,
  created_at TIMESTAMP
);

-- Child profiles
children (
  id UUID PRIMARY KEY,
  family_id UUID REFERENCES families,
  name TEXT,
  age INTEGER,
  avatar_url TEXT,
  created_at TIMESTAMP
);

-- Device registration
child_devices (
  id UUID PRIMARY KEY,
  child_id UUID REFERENCES children,
  device_id TEXT UNIQUE,
  device_name TEXT,
  platform TEXT, -- 'android', 'ios'
  last_online TIMESTAMP,
  is_locked BOOLEAN DEFAULT FALSE
);

-- Screen time rules
screen_time_rules (
  id UUID PRIMARY KEY,
  child_id UUID REFERENCES children,
  rule_type TEXT, -- 'schedule', 'daily_limit', 'bedtime'
  start_time TIME,
  end_time TIME,
  days_of_week INTEGER[], -- [1,2,3,4,5] = weekdays
  is_active BOOLEAN DEFAULT TRUE
);

-- Control commands
control_commands (
  id UUID PRIMARY KEY,
  parent_id UUID REFERENCES auth.users,
  child_device_id UUID REFERENCES child_devices,
  command_type TEXT, -- 'lock', 'unlock', 'set_rule'
  command_data JSONB,
  status TEXT, -- 'pending', 'executed', 'failed'
  created_at TIMESTAMP
);

-- Usage tracking
device_usage_logs (
  id UUID PRIMARY KEY,
  child_device_id UUID REFERENCES child_devices,
  date DATE,
  total_screen_time INTEGER, -- minutes
  app_usage JSONB,
  locks_triggered INTEGER,
  created_at TIMESTAMP
);
```

---

## 📱 User Experience Flows

### **Parent Dashboard**
```
📊 Family Overview
├── Child 1 (Emma's Tablet)
│   ├── Status: 🔓 Unlocked
│   ├── Today: 2h 15m / 3h limit
│   └── [🔒 Lock Now] [⚙️ Settings]
│
├── Child 2 (Jake's Phone)
│   ├── Status: 🔒 Locked (Bedtime)
│   ├── Today: 4h 30m / 4h limit
│   └── [🔓 Unlock] [⚙️ Settings]
```

### **Child Experience**
```
Normal Usage:
┌─────────────────────┐
│  🎮 FocusFlow       │
│                     │
│  📊 Today: 1h 30m   │
│  ⏰ Until 8:00 PM   │
│                     │
│  [Continue Using]   │
└─────────────────────┘

Locked State:
┌─────────────────────┐
│  🔒 Device Locked   │
│                     │
│  Your parent has    │
│  locked this device │
│                     │
│  ⏰ Bedtime: 8 PM   │
│                     │
│  [Ask Parent] [📱]  │
└─────────────────────┘
```

---

## 🛡️ System-Level Enforcement

### **Android Implementation**
```kotlin
// Foreground Service + Device Admin
class ParentalControlService : Service() {
    
    fun lockDevice() {
        // Method 1: Overlay that blocks all input
        showSystemOverlay()
        
        // Method 2: Disable home button (requires device admin)
        disableSystemButtons()
        
        // Method 3: App pinning (requires user setup)
        startLockTask()
    }
    
    fun monitorAppUsage() {
        // Continuously check current app
        // Force return to lock screen if needed
    }
}
```

### **Lock Bypass Prevention**
```kotlin
// Prevent common bypass methods
class AntiBypassManager {
    
    // Restart service if killed
    fun ensureServiceRunning()
    
    // Re-lock if device rebooted
    fun handleDeviceReboot()
    
    // Block uninstall attempts
    fun protectFromUninstall()
    
    // Monitor for developer options
    fun detectDebugMode()
}
```

---

## ⚡ Real-time Control Implementation

### **Parent Side: Send Command**
```dart
class ParentControlProvider extends ChangeNotifier {
  
  Future<void> lockChildDevice(String childDeviceId) async {
    // 1. Store command in database
    await supabase.from('control_commands').insert({
      'parent_id': currentUser.id,
      'child_device_id': childDeviceId,
      'command_type': 'lock',
      'status': 'pending',
    });
    
    // 2. Send real-time notification
    await supabase.realtime.channel('child_$childDeviceId').send({
      'type': 'broadcast',
      'event': 'parent_command',
      'payload': {'command': 'lock'}
    });
    
    // 3. Update UI immediately
    notifyListeners();
  }
}
```

### **Child Side: Receive Command**
```dart
class ChildControlProvider extends ChangeNotifier {
  
  void initializeRealtime() {
    supabase.realtime
      .channel('child_${deviceId}')
      .on('broadcast', {'event': 'parent_command'}, (payload) {
        handleParentCommand(payload['command']);
      })
      .subscribe();
  }
  
  void handleParentCommand(String command) {
    switch (command) {
      case 'lock':
        _lockDevice();
        break;
      case 'unlock':
        _unlockDevice();
        break;
    }
  }
}
```

---

## 📅 Scheduled Rules System

### **Rule Types**
```dart
enum ScheduleType {
  bedtime,      // 8 PM - 7 AM
  schoolTime,   // 8 AM - 3 PM (weekdays)
  mealTime,     // 12 PM - 1 PM
  homeworkTime, // 4 PM - 6 PM
  custom        // Parent-defined
}

class ScreenTimeRule {
  String childId;
  ScheduleType type;
  TimeOfDay startTime;
  TimeOfDay endTime;
  List<int> daysOfWeek; // 1-7
  bool isActive;
  
  bool isCurrentlyBlocked() {
    // Check if current time falls within rule
  }
}
```

### **Automatic Enforcement**
```dart
class ScheduleManager {
  Timer? _scheduleTimer;
  
  void startScheduleMonitoring() {
    _scheduleTimer = Timer.periodic(Duration(minutes: 1), (_) {
      for (var rule in activeRules) {
        if (rule.isCurrentlyBlocked()) {
          _lockDevice(reason: rule.type.toString());
        }
      }
    });
  }
}
```

---

## 🚀 Implementation Phases

### **Phase 1: Foundation** (Week 1-2)
- [ ] Database schema setup
- [ ] Account type system (parent/child)
- [ ] Basic linking flow
- [ ] Simple lock/unlock commands

### **Phase 2: Real-time Control** (Week 3-4)  
- [ ] Supabase Realtime integration
- [ ] Parent dashboard UI
- [ ] Child lock screen UI
- [ ] Command queue system

### **Phase 3: Scheduling** (Week 5-6)
- [ ] Rule creation UI
- [ ] Automatic schedule enforcement  
- [ ] Usage analytics
- [ ] Multiple child support

### **Phase 4: Advanced Features** (Week 7-8)
- [ ] Anti-bypass mechanisms
- [ ] Push notification backup
- [ ] Usage reports and insights
- [ ] Emergency unlock requests

---

## 🔐 Security Considerations

### **Authentication**
- Parent must verify identity for sensitive actions
- Child cannot change parent password/email
- Session management with automatic logout

### **Privacy**
- Minimal data collection from child device
- Transparent about what parent can see
- No secret monitoring or spying

### **Safety**
- Emergency unlock codes
- Gradual enforcement (warnings before locks)
- Age-appropriate messaging

---

## 💡 Business Model Integration

### **Subscription Tiers**
```
🆓 Free Plan:
- 1 child
- Basic scheduling
- Manual lock/unlock

💎 Family Plan ($4.99/month):
- Unlimited children
- Advanced rules
- Usage analytics
- Priority support

🏢 School Edition ($19.99/month):
- Classroom management
- Teacher dashboard
- Bulk device setup
```

---

This system would make FocusFlow a **market leader** in family screen time management! 🚀

**Next Steps:**
1. Should we start with the database schema?
2. Or begin with the parent-child linking flow?
3. Which part would you like to tackle first?