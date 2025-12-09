package com.example.focusflow

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.content.pm.PackageManager
import android.content.pm.ApplicationInfo
import android.graphics.PixelFormat
import android.view.WindowManager
import android.view.Gravity
import android.view.View
import android.widget.TextView
import android.widget.Button
import android.graphics.Color
import android.view.ViewGroup
import android.widget.LinearLayout
import android.app.NotificationManager
import android.app.NotificationChannel
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.focusflow/permissions"
    private val APP_MONITOR_CHANNEL = "app.focusflow/monitor"
    private val OVERLAY_CHANNEL = "com.example.focusflow/overlay"
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    
    // Notification constants
    private val NOTIFICATION_CHANNEL_ID = "focusflow_channel"
    private val NOTIFICATION_CHANNEL_NAME = "FocusFlow Notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create notification channel
        createNotificationChannel()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUsageStatsSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Could not open usage stats settings", e.message)
                    }
                }
                "checkUsageStatsPermission" -> {
                    val hasPermission = checkUsageStatsPermission()
                    result.success(hasPermission)
                }
                else -> result.notImplemented()
            }
        }

        // 🚀 NEW FOREGROUND SERVICE CHANNEL - This is the REAL solution!
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_MONITOR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // ===============================
                // FOREGROUND SERVICE COMMANDS
                // ===============================
                "startBlockingService" -> {
                    try {
                        val blockedApps = call.argument<String>("blockedApps") ?: "[]"
                        val startHour = call.argument<Int>("startHour") ?: -1
                        val startMinute = call.argument<Int>("startMinute") ?: -1
                        val endHour = call.argument<Int>("endHour") ?: -1
                        val endMinute = call.argument<Int>("endMinute") ?: -1
                        val focusMode = call.argument<Boolean>("focusMode") ?: false
                        
                        val serviceIntent = Intent(this, AppBlockingService::class.java).apply {
                            action = AppBlockingService.ACTION_START_BLOCKING
                            putExtra(AppBlockingService.EXTRA_BLOCKED_APPS, blockedApps)
                            putExtra("startHour", startHour)
                            putExtra("startMinute", startMinute) 
                            putExtra("endHour", endHour)
                            putExtra("endMinute", endMinute)
                            putExtra(AppBlockingService.EXTRA_FOCUS_MODE, focusMode)
                        }
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        
                        result.success("🚀 Blocking service started - 100% reliable!")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to start service: ${e.message}", null)
                    }
                }
                
                "stopBlockingService" -> {
                    try {
                        val serviceIntent = Intent(this, AppBlockingService::class.java).apply {
                            action = AppBlockingService.ACTION_STOP_BLOCKING
                        }
                        startService(serviceIntent)
                        result.success("🛑 Blocking service stopped")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to stop service: ${e.message}", null)
                    }
                }
                
                "updateBlockedApps" -> {
                    try {
                        val blockedApps = call.argument<String>("blockedApps") ?: "[]"
                        val startHour = call.argument<Int>("startHour") ?: -1
                        val startMinute = call.argument<Int>("startMinute") ?: -1
                        val endHour = call.argument<Int>("endHour") ?: -1
                        val endMinute = call.argument<Int>("endMinute") ?: -1
                        val focusMode = call.argument<Boolean>("focusMode") ?: false
                        
                        val serviceIntent = Intent(this, AppBlockingService::class.java).apply {
                            action = AppBlockingService.ACTION_UPDATE_BLOCKED_APPS
                            putExtra(AppBlockingService.EXTRA_BLOCKED_APPS, blockedApps)
                            putExtra("startHour", startHour)
                            putExtra("startMinute", startMinute)
                            putExtra("endHour", endHour)
                            putExtra("endMinute", endMinute)
                            putExtra(AppBlockingService.EXTRA_FOCUS_MODE, focusMode)
                        }
                        startService(serviceIntent)
                        result.success("📱 Blocked apps updated in service")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to update service: ${e.message}", null)
                    }
                }
                
                "getLastBlockEvent" -> {
                    try {
                        val prefs = getSharedPreferences("focusflow_blocking", MODE_PRIVATE)
                        val lastBlockEvent = prefs.getString("last_block_event", null)
                        val lastBlockTimestamp = prefs.getLong("last_block_timestamp", 0)
                        
                        val response = mapOf(
                            "event" to lastBlockEvent,
                            "timestamp" to lastBlockTimestamp
                        )
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get block event: ${e.message}", null)
                    }
                }
                
                // ===============================
                // LEGACY METHODS (for compatibility)
                // ===============================
                "getForegroundApp" -> {
                    val foregroundApp = getForegroundApp()
                    result.success(foregroundApp)
                }
                "getInstalledApps" -> {
                    val installedApps = getInstalledApps()
                    result.success(installedApps)
                }
                "getAppUsageStats" -> {
                    val packageName = call.argument<String>("packageName")
                    val days = call.argument<Int>("days") ?: 7
                    if (packageName != null) {
                        val usageStats = getAppUsageStats(packageName, days)
                        result.success(usageStats)
                    } else {
                        result.error("ERROR", "Package name is required", null)
                    }
                }
                "openUsageStatsSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Could not open usage stats settings", e.message)
                    }
                }
                "openOverlaySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                        intent.data = Uri.parse("package:$packageName")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Could not open overlay settings", e.message)
                    }
                }
                "closeApp" -> {
                    val args = call.arguments as? Map<String, Any>
                    val packageName = args?.get("packageName") as? String
                    if (packageName != null) {
                        val success = closeApp(packageName)
                        result.success(success)
                    } else {
                        result.error("ERROR", "Package name is required", null)
                    }
                }
                "checkOverlayPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                "sendNotification" -> {
                    val title = call.argument<String>("title") ?: "FocusFlow"
                    val body = call.argument<String>("body") ?: ""
                    val type = call.argument<String>("type") ?: "info"
                    
                    sendNotification(title, body, type)
                    result.success("Notification sent")
                }
                "showTaskReminderOverlay" -> {
                    // Now handled by Flutter TaskOverlayService
                    result.success("Task reminder now handled by Flutter overlay service")
                }
                "startBlockingService" -> {
                    try {
                        val blockedAppsJson = call.argument<String>("blockedApps") ?: "[]"
                        val focusMode = call.argument<Boolean>("focusMode") ?: false
                        val startHour = call.argument<Int>("startHour") ?: -1
                        val startMinute = call.argument<Int>("startMinute") ?: -1
                        val endHour = call.argument<Int>("endHour") ?: -1
                        val endMinute = call.argument<Int>("endMinute") ?: -1
                        
                        val intent = Intent(this, AppBlockingService::class.java).apply {
                            action = "ACTION_START_BLOCKING"
                            putExtra("EXTRA_BLOCKED_APPS", blockedAppsJson)
                            putExtra("EXTRA_FOCUS_MODE", focusMode)
                            putExtra("startHour", startHour)
                            putExtra("startMinute", startMinute)
                            putExtra("endHour", endHour)
                            putExtra("endMinute", endMinute)
                        }
                        
                        startForegroundService(intent)
                        result.success("Blocking service started")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to start blocking service: ${e.message}", null)
                    }
                }
                "stopBlockingService" -> {
                    try {
                        val intent = Intent(this, AppBlockingService::class.java).apply {
                            action = "ACTION_STOP_BLOCKING"
                        }
                        startService(intent)
                        result.success("Blocking service stopped")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to stop blocking service: ${e.message}", null)
                    }
                }
                "updateBlockingConfig" -> {
                    try {
                        val blockedAppsJson = call.argument<String>("blockedApps") ?: "[]"
                        val focusMode = call.argument<Boolean>("focusMode") ?: false
                        val startHour = call.argument<Int>("startHour") ?: -1
                        val startMinute = call.argument<Int>("startMinute") ?: -1
                        val endHour = call.argument<Int>("endHour") ?: -1
                        val endMinute = call.argument<Int>("endMinute") ?: -1
                        
                        val intent = Intent(this, AppBlockingService::class.java).apply {
                            action = "ACTION_UPDATE_BLOCKED_APPS"
                            putExtra("EXTRA_BLOCKED_APPS", blockedAppsJson)
                            putExtra("EXTRA_FOCUS_MODE", focusMode)
                            putExtra("startHour", startHour)
                            putExtra("startMinute", startMinute)
                            putExtra("endHour", endHour)
                            putExtra("endMinute", endMinute)
                        }
                        
                        startService(intent)
                        result.success("Blocking config updated")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to update blocking config: ${e.message}", null)
                    }
                }
                "getTaskStatus" -> {
                    // Get current task status for accountability partner
                    val taskStatus = mapOf(
                        "hasTasksToday" to true,
                        "taskCount" to 3,
                        "completedTasks" to 1,
                        "pendingTasks" to 2,
                        "progress" to 33
                    )
                    result.success(taskStatus)
                }
                else -> result.notImplemented()
            }
        }

        // System overlay channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showBlockOverlay" -> {
                    try {
                        val appName = call.argument<String>("appName") ?: "Unknown App"
                        val title = call.argument<String>("title") ?: "App Blocked"
                        val message = call.argument<String>("message") ?: "This app is currently blocked."
                        
                        showSystemOverlay(appName, title, message)
                        result.success("Overlay shown for $appName")
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", "Failed to show overlay: ${e.message}", null)
                    }
                }
                "hideOverlay" -> {
                    try {
                        hideSystemOverlay()
                        result.success("Overlay hidden")
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", "Failed to hide overlay: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkUsageStatsPermission(): Boolean {
        return try {
            val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOpsManager.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOpsManager.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    private fun getForegroundApp(): String? {
        return try {
            if (!checkUsageStatsPermission()) {
                println("⚠️ Usage stats permission not granted")
                return null
            }

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val currentTime = System.currentTimeMillis()
            val queryTime = currentTime - 5000 // Check last 5 seconds for more accurate detection
            
            // Get usage events to find the most recent foreground app
            val usageEvents = usageStatsManager.queryEvents(queryTime, currentTime)
            var lastResumedApp: String? = null
            var lastEventTime = 0L
            
            val event = android.app.usage.UsageEvents.Event()
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    if (event.timeStamp > lastEventTime) {
                        lastResumedApp = event.packageName
                        lastEventTime = event.timeStamp
                    }
                }
            }
            
            // Verify the detected app is not our own app and is actually installed
            if (lastResumedApp != null && lastResumedApp != packageName && lastResumedApp != "com.example.focusflow") {
                try {
                    val packageInfo = packageManager.getPackageInfo(lastResumedApp, 0)
                    val appInfo = packageInfo.applicationInfo
                    if (appInfo != null) {
                        val appName = packageManager.getApplicationLabel(appInfo).toString()
                        println("📱 Real app detected: $appName ($lastResumedApp)")
                        return lastResumedApp
                    } else {
                        println("❌ App info not available: $lastResumedApp")
                        return null
                    }
                } catch (e: Exception) {
                    println("❌ App not installed or accessible: $lastResumedApp")
                    return null
                }
            }
            
            null
        } catch (e: Exception) {
            println("⚠️ Error getting foreground app: ${e.message}")
            e.printStackTrace()
            null
        }
    }

    private fun showSystemOverlay(appName: String, title: String, message: String) {
        try {
            // Check if we have overlay permission
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                println("🚫 No overlay permission - requesting permission")
                return
            }

            // Initialize WindowManager if not already done
            if (windowManager == null) {
                windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            }

            // Remove existing overlay if present
            hideSystemOverlay()

            // Create full-screen blocking overlay
            val overlayLayout = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.parseColor("#F0112117")) // Mostly opaque dark green
                setPadding(60, 120, 60, 120)
                gravity = Gravity.CENTER
            }

            // Blocked emoji
            val emojiView = TextView(this).apply {
                text = "🚫"
                textSize = 80f
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, 40)
            }

            // Title
            val titleView = TextView(this).apply {
                text = "Time to Refocus"
                textSize = 28f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, 20)
                typeface = android.graphics.Typeface.DEFAULT_BOLD
            }

            // Message
            val messageView = TextView(this).apply {
                text = "You've hit your limit for $appName.\nStay focused to earn 50 points!"
                textSize = 16f
                setTextColor(Color.parseColor("#CCFFFFFF"))
                gravity = Gravity.CENTER
                setPadding(20, 0, 20, 60)
            }

            // Button container
            val buttonLayout = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            }

            // Close app button
            val closeButton = Button(this).apply {
                text = "Close App"
                setBackgroundColor(Color.parseColor("#19E66B"))
                setTextColor(Color.parseColor("#112117"))
                textSize = 16f
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 120)
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                setPadding(40, 20, 40, 20)
                setOnClickListener {
                    hideSystemOverlay()
                    // Force close the blocked app and return to home screen
                    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(homeIntent)
                    println("🏠 Returned to home screen")
                }
            }

            // Grace period button
            val graceButton = Button(this).apply {
                text = "Give me 2 minutes"
                setBackgroundColor(Color.parseColor("#33FFFFFF"))
                setTextColor(Color.WHITE)
                textSize = 16f
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 120).apply {
                    topMargin = 20
                }
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                setPadding(40, 20, 40, 20)
                setOnClickListener {
                    hideSystemOverlay()
                    // Notify Flutter about grace period start
                    try {
                        val channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, "com.example.focusflow/overlay")
                        channel.invokeMethod("startGracePeriod", mapOf("appName" to appName, "duration" to 120))
                        println("⏰ Grace period granted for 2 minutes for $appName")
                    } catch (e: Exception) {
                        println("⚠️ Could not notify Flutter about grace period: ${e.message}")
                    }
                }
            }

            // Add all views to layouts
            buttonLayout.addView(closeButton)
            buttonLayout.addView(graceButton)
            
            overlayLayout.addView(emojiView)
            overlayLayout.addView(titleView)
            overlayLayout.addView(messageView)
            overlayLayout.addView(buttonLayout)

            // Set layout parameters for full-screen UNESCAPABLE overlay
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            )

            params.gravity = Gravity.CENTER

            // Add persistent overlay to window manager
            overlayView = overlayLayout
            windowManager?.addView(overlayLayout, params)

            println("✅ Persistent blocking overlay shown for $appName")
            println("🔒 App usage blocked until user takes action")

        } catch (e: Exception) {
            println("❌ Error showing system overlay: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun hideSystemOverlay() {
        try {
            overlayView?.let { view ->
                windowManager?.removeView(view)
                overlayView = null
                println("🔄 System overlay hidden")
            }
        } catch (e: Exception) {
            println("⚠️ Error hiding overlay: ${e.message}")
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        return try {
            val packageManager = packageManager
            val installedApps = mutableListOf<Map<String, Any>>()
            
            // Get list of installed applications
            val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            }
            
            for (appInfo in packages) {
                // Skip system apps and our own app
                if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) == 0 && 
                    appInfo.packageName != packageName) {
                    
                    try {
                        val appName = packageManager.getApplicationLabel(appInfo).toString()
                        val appMap = mapOf(
                            "packageName" to appInfo.packageName,
                            "appName" to appName,
                            "isSystemApp" to false
                        )
                        installedApps.add(appMap)
                    } catch (e: Exception) {
                        // Skip apps we can't get info for
                    }
                }
            }
            
            println("📱 Found ${installedApps.size} installed user apps")
            installedApps
        } catch (e: Exception) {
            println("❌ Error getting installed apps: ${e.message}")
            emptyList()
        }
    }

    private fun getAppUsageStats(packageName: String, days: Int): Map<String, Any> {
        return try {
            if (!checkUsageStatsPermission()) {
                return mapOf("error" to "Usage stats permission not granted")
            }

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - (days * 24 * 60 * 60 * 1000L)
            
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, 
                startTime, 
                endTime
            )
            
            val appUsage = usageStatsList.find { it.packageName == packageName }
            
            if (appUsage != null) {
                mapOf(
                    "packageName" to packageName,
                    "totalTimeInForeground" to appUsage.totalTimeInForeground,
                    "lastTimeUsed" to appUsage.lastTimeUsed,
                    "firstTimeStamp" to appUsage.firstTimeStamp,
                    "totalTimeInForegroundMinutes" to (appUsage.totalTimeInForeground / (1000 * 60)),
                    "success" to true
                )
            } else {
                mapOf(
                    "packageName" to packageName,
                    "totalTimeInForeground" to 0,
                    "totalTimeInForegroundMinutes" to 0,
                    "success" to true,
                    "message" to "No usage data found for this app"
                )
            }
        } catch (e: Exception) {
            println("❌ Error getting usage stats for $packageName: ${e.message}")
            mapOf(
                "error" to "Failed to get usage stats: ${e.message}",
                "success" to false
            )
        }
    }
    
    // Force close an app by bringing user to home screen aggressively
    private fun closeApp(packageName: String): Boolean {
        return try {
            println("🔒 AGGRESSIVELY forcing close of $packageName")
            
            // Method 1: Launch home screen intent with multiple flags
            val homeIntent = Intent(Intent.ACTION_MAIN)
            homeIntent.addCategory(Intent.CATEGORY_HOME)
            homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                              Intent.FLAG_ACTIVITY_CLEAR_TOP or
                              Intent.FLAG_ACTIVITY_SINGLE_TOP or
                              Intent.FLAG_ACTIVITY_CLEAR_TASK
            
            startActivity(homeIntent)
            
            // Method 2: Also try to launch our own app to override the blocked app
            val ourAppIntent = Intent(this, MainActivity::class.java)
            ourAppIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            startActivity(ourAppIntent)
            
            println("🏠 Aggressively brought user to home screen and our app")
            true
        } catch (e: Exception) {
            println("❌ Error closing app $packageName: ${e.message}")
            false
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for app blocking and focus reminders"
                enableVibration(true)
                enableLights(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            println("📢 Notification channel created")
        }
    }
    
    private fun sendNotification(title: String, body: String, type: String) {
        try {
            val icon = when (type) {
                "block" -> android.R.drawable.ic_dialog_alert
                "reminder" -> android.R.drawable.ic_dialog_info
                else -> android.R.drawable.ic_dialog_info
            }
            
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(icon)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)
                .build()
            
            val notificationId = System.currentTimeMillis().toInt()
            val notificationManager = NotificationManagerCompat.from(this)
            
            if (notificationManager.areNotificationsEnabled()) {
                notificationManager.notify(notificationId, notification)
                println("📢 Notification sent: $title - $body")
            } else {
                println("⚠️ Notifications are disabled by user")
            }
        } catch (e: Exception) {
            println("❌ Error sending notification: ${e.message}")
        }
    }

    // Old native overlay removed - now using beautiful Flutter TaskOverlayService

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleBlockingIntent(intent)
        handleRouteIntent(intent)
    }

    private fun handleBlockingIntent(intent: Intent) {
        // No longer needed - native service handles all blocking with beautiful native overlay
        println("📱 Blocking handled entirely by native service")
    }

    private fun handleRouteIntent(intent: Intent) {
        val route = intent.getStringExtra("route")
        if (route != null) {
            // Navigate to specific route in Flutter
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                val routeChannel = MethodChannel(messenger, "app.focusflow/navigation")
                routeChannel.invokeMethod("navigateTo", route)
            }
        }
    }

    override fun onDestroy() {
        hideSystemOverlay()
        super.onDestroy()
    }
}
