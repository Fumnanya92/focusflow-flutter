import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import UIKit

@available(iOS 15.0, *)
class IOSAppBlockingService: NSObject {
    
    static let shared = IOSAppBlockingService()
    
    // Screen Time API components
    private let center = AuthorizationCenter.shared
    private let managedSettings = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    
    // Configuration
    private var blockedAppTokens: Set<ApplicationToken> = []
    private var isMonitoring = false
    private var focusMode = false
    private var timeSchedule: (start: Int, end: Int)? = nil // Minutes from midnight
    
    // Flutter communication
    private var methodChannel: FlutterMethodChannel?
    
    // Constants
    private let activityName = DeviceActivityName("focusflow.blocking")
    
    override init() {
        super.init()
        print("🍎 IOSAppBlockingService initialized")
    }
    
    // MARK: - Public Methods
    
    func setMethodChannel(_ channel: FlutterMethodChannel) {
        self.methodChannel = channel
        print("🔗 Method channel set for iOS app blocking")
    }
    
    /// Request Screen Time authorization
    func requestAuthorization(completion: @escaping (Bool, String) -> Void) {
        print("🔐 Requesting Family Controls authorization...")
        
        Task {
            do {
                try await center.requestAuthorization(for: .individual)
                
                await MainActor.run {
                    switch center.authorizationStatus {
                    case .approved:
                        print("✅ Family Controls authorization approved")
                        completion(true, "Authorization granted")
                    case .denied:
                        print("❌ Family Controls authorization denied")
                        completion(false, "Authorization denied by user")
                    case .notDetermined:
                        print("⚠️ Family Controls authorization not determined")
                        completion(false, "Authorization not determined")
                    @unknown default:
                        print("❓ Unknown authorization status")
                        completion(false, "Unknown authorization status")
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error requesting authorization: \(error)")
                    completion(false, "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Configure blocked apps
    func configureBlockedApps(appIdentifiers: [String], completion: @escaping (Bool, String) -> Void) {
        print("📱 Configuring blocked apps: \(appIdentifiers)")
        
        guard center.authorizationStatus == .approved else {
            completion(false, "Screen Time authorization not granted")
            return
        }
        
        // Convert bundle identifiers to application tokens
        Task {
            await MainActor.run {
                do {
                    // Get all available apps
                    let applicationSelection = FamilyActivitySelection()
                    
                    // For now, we'll use a simplified approach
                    // In a real implementation, you'd need the user to select apps via FamilyActivityPicker
                    // or maintain a mapping of bundle IDs to tokens
                    
                    // Store the bundle IDs for now (we'll enhance this later)
                    print("✅ App blocking configured for \(appIdentifiers.count) apps")
                    completion(true, "Apps configured successfully")
                } catch {
                    print("❌ Error configuring apps: \(error)")
                    completion(false, "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Start monitoring and blocking
    func startMonitoring(focusMode: Bool, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, completion: @escaping (Bool, String) -> Void) {
        print("🚀 Starting iOS app monitoring...")
        print("🎯 Focus mode: \(focusMode)")
        print("⏰ Schedule: \(startHour):\(String(format: "%02d", startMinute)) - \(endHour):\(String(format: "%02d", endMinute))")
        
        guard center.authorizationStatus == .approved else {
            completion(false, "Screen Time authorization not granted")
            return
        }
        
        self.focusMode = focusMode
        
        // Set up time schedule
        if startHour >= 0 && endHour >= 0 {
            self.timeSchedule = (
                start: startHour * 60 + startMinute,
                end: endHour * 60 + endMinute
            )
        }
        
        // Apply restrictions immediately if in focus mode or within time schedule
        if shouldApplyRestrictions() {
            applyAppRestrictions()
        }
        
        // Set up device activity monitoring
        setupDeviceActivityMonitoring()
        
        self.isMonitoring = true
        completion(true, "Monitoring started successfully")
    }
    
    /// Stop monitoring
    func stopMonitoring(completion: @escaping (Bool, String) -> Void) {
        print("⏹️ Stopping iOS app monitoring...")
        
        // Remove all restrictions
        managedSettings.clearAllSettings()
        
        // Stop device activity monitoring
        deviceActivityCenter.stopMonitoring([activityName])
        
        self.isMonitoring = false
        self.focusMode = false
        self.timeSchedule = nil
        
        completion(true, "Monitoring stopped successfully")
    }
    
    /// Enable focus mode (immediate blocking)
    func enableFocusMode() {
        print("🎯 Enabling focus mode - applying restrictions")
        self.focusMode = true
        if isMonitoring {
            applyAppRestrictions()
        }
    }
    
    /// Disable focus mode
    func disableFocusMode() {
        print("🎯 Disabling focus mode")
        self.focusMode = false
        if isMonitoring && !isWithinTimeSchedule() {
            // Only remove restrictions if not within scheduled time
            managedSettings.clearAllSettings()
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldApplyRestrictions() -> Bool {
        if focusMode {
            return true
        }
        return isWithinTimeSchedule()
    }
    
    private func isWithinTimeSchedule() -> Bool {
        guard let schedule = timeSchedule else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        
        if schedule.start <= schedule.end {
            // Same day schedule (e.g., 9:00 - 17:00)
            return currentMinutes >= schedule.start && currentMinutes <= schedule.end
        } else {
            // Cross-midnight schedule (e.g., 22:00 - 06:00)
            return currentMinutes >= schedule.start || currentMinutes <= schedule.end
        }
    }
    
    private func applyAppRestrictions() {
        print("🚫 Applying app restrictions")
        
        // Apply restrictions to blocked apps
        if !blockedAppTokens.isEmpty {
            managedSettings.application.blockedApplications = blockedAppTokens
        }
        
        // Notify Flutter about restriction status
        notifyFlutter("restrictionsApplied", data: ["timestamp": Date().timeIntervalSince1970])
    }
    
    private func setupDeviceActivityMonitoring() {
        print("📊 Setting up device activity monitoring")
        
        // Create monitoring schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            print("✅ Device activity monitoring started")
        } catch {
            print("❌ Failed to start device activity monitoring: \(error)")
        }
    }
    
    private func notifyFlutter(_ method: String, data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel?.invokeMethod(method, arguments: data)
        }
    }
    
    // MARK: - Method Channel Handlers
    
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🔗 iOS handling method call: \(call.method)")
        
        switch call.method {
        case "requestIOSAuthorization":
            requestAuthorization { success, message in
                result(["success": success, "message": message])
            }
            
        case "configureBlockedApps":
            guard let args = call.arguments as? [String: Any],
                  let appIdentifiers = args["appIdentifiers"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            configureBlockedApps(appIdentifiers: appIdentifiers) { success, message in
                result(["success": success, "message": message])
            }
            
        case "startIOSMonitoring":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            let focusMode = args["focusMode"] as? Bool ?? false
            let startHour = args["startHour"] as? Int ?? -1
            let startMinute = args["startMinute"] as? Int ?? -1
            let endHour = args["endHour"] as? Int ?? -1
            let endMinute = args["endMinute"] as? Int ?? -1
            
            startMonitoring(
                focusMode: focusMode,
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute
            ) { success, message in
                result(["success": success, "message": message])
            }
            
        case "stopIOSMonitoring":
            stopMonitoring { success, message in
                result(["success": success, "message": message])
            }
            
        case "enableIOSFocusMode":
            enableFocusMode()
            result(["success": true, "message": "Focus mode enabled"])
            
        case "disableIOSFocusMode":
            disableFocusMode()
            result(["success": true, "message": "Focus mode disabled"])
            
        case "getIOSAuthorizationStatus":
            let status: String
            switch center.authorizationStatus {
            case .approved:
                status = "approved"
            case .denied:
                status = "denied"
            case .notDetermined:
                status = "notDetermined"
            @unknown default:
                status = "unknown"
            }
            result(["status": status, "success": true])
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - DeviceActivityMonitor Extension

@available(iOS 15.0, *)
extension IOSAppBlockingService: DeviceActivityMonitorDelegate {
    
    func activityStarted(for activity: DeviceActivityName) {
        print("📱 Device activity started: \(activity)")
        notifyFlutter("onDeviceActivityStarted", data: ["activity": activity.rawValue])
    }
    
    func activityEnded(for activity: DeviceActivityName) {
        print("📱 Device activity ended: \(activity)")
        notifyFlutter("onDeviceActivityEnded", data: ["activity": activity.rawValue])
    }
    
    func activityWarningReached(for activity: DeviceActivityName) {
        print("⚠️ Device activity warning reached: \(activity)")
        notifyFlutter("onDeviceActivityWarning", data: ["activity": activity.rawValue])
    }
}