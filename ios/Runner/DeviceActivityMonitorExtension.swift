import Foundation
import DeviceActivity
import ManagedSettings
import UIKit

@available(iOS 15.0, *)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let managedSettings = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("🍎 Device activity interval started: \(activity)")
        
        // Apply restrictions when interval starts
        applyRestrictions()
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("🍎 Device activity interval ended: \(activity)")
        
        // Remove restrictions when interval ends
        removeRestrictions()
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        print("🍎 Device activity warning: \(activity)")
        
        // Show warning before restrictions apply
        sendWarningNotification()
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        print("🍎 Device activity ending warning: \(activity)")
        
        // Notify that restrictions will end soon
        sendEndingNotification()
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("🍎 Device activity event threshold reached: \(event) for \(activity)")
        
        // Handle specific app usage thresholds
        handleEventThreshold(event, activity: activity)
    }
    
    // MARK: - Helper Methods
    
    private func applyRestrictions() {
        print("🚫 Applying Screen Time restrictions")
        
        // Load blocked apps from UserDefaults (shared with main app)
        let userDefaults = UserDefaults(suiteName: "group.com.focusflow.productivity")
        if let blockedAppsData = userDefaults?.data(forKey: "blockedApps"),
           let blockedApps = try? JSONDecoder().decode([String].self, from: blockedAppsData) {
            
            // For now, we'll use application category restrictions
            // In a full implementation, you'd need to map bundle IDs to ApplicationTokens
            // This requires the user to select apps through FamilyActivityPicker
            
            print("📱 Applying restrictions to \(blockedApps.count) apps")
            
            // Apply shield restrictions (this is a simplified example)
            // You would need to implement proper token-based blocking here
            
        }
    }
    
    private func removeRestrictions() {
        print("✅ Removing Screen Time restrictions")
        managedSettings.clearAllSettings()
    }
    
    private func sendWarningNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎯 Focus Time Starting"
        content.body = "App restrictions will begin shortly. Finish what you're doing!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "focusflow.warning",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendEndingNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Focus Session Complete"
        content.body = "Great job! You've completed your focus session."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "focusflow.complete",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func handleEventThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        // Handle specific app usage events
        print("⚠️ App usage threshold reached for event: \(event)")
        
        // Send notification about blocked app attempt
        let content = UNMutableNotificationContent()
        content.title = "🚫 App Blocked"
        content.body = "You tried to access a blocked app during focus time."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "focusflow.blocked.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        
        // Notify main app about the blocking event
        notifyMainAppOfBlockingEvent(event: event)
    }
    
    private func notifyMainAppOfBlockingEvent(event: DeviceActivityEvent.Name) {
        // Store blocking event for main app to read
        let userDefaults = UserDefaults(suiteName: "group.com.focusflow.productivity")
        let blockingEvent = [
            "event": event.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "type": "app_blocked"
        ] as [String: Any]
        
        if let data = try? JSONSerialization.data(withJSONObject: blockingEvent) {
            userDefaults?.set(data, forKey: "lastBlockingEvent")
        }
        
        // Send local notification to wake up main app if needed
        let content = UNMutableNotificationContent()
        content.title = "FocusFlow"
        content.body = "App blocking event recorded"
        content.categoryIdentifier = "HIDDEN"
        content.sound = nil
        
        let request = UNNotificationRequest(
            identifier: "focusflow.internal.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}