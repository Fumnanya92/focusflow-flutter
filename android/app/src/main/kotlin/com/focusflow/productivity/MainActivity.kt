package com.focusflow.productivity

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
import android.widget.LinearLayout
import android.os.Handler
import android.os.Looper
import android.widget.ImageView
import android.graphics.Typeface
import android.view.ViewGroup.LayoutParams
import android.widget.RelativeLayout
import android.content.SharedPreferences
import android.content.pm.ResolveInfo
import android.graphics.drawable.Drawable
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.*
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.focusflow.productivity/system"
    private val PERMISSIONS_CHANNEL = "com.focusflow.productivity/permissions"
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    private var blockedAppsPackages = mutableSetOf<String>()
    private var isMonitoring = false
    private var monitoringHandler: Handler? = null
    private var monitoringRunnable: Runnable? = null
    
    // Time-based blocking variables
    private var blockingStartHour = -1
    private var blockingStartMinute = -1
    private var blockingEndHour = -1
    private var blockingEndMinute = -1
    private var timeScheduleEnabled = false
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // System channel for app monitoring and blocking
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                "checkOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "getInstalledApps" -> {
                    try {
                        Log.d("FocusFlow", "📱 Starting to fetch installed apps...")
                        val apps = getInstalledAppsList()
                        Log.d("FocusFlow", "✅ Found ${apps.size} launchable apps")
                        result.success(apps)
                    } catch (e: Exception) {
                        Log.e("FocusFlow", "❌ Error fetching installed apps: ${e.message}", e)
                        result.success(emptyList<Map<String, Any>>())
                    }
                }
                "getCurrentAppPackage" -> {
                    val currentApp = getCurrentRunningApp()
                    result.success(currentApp)
                }
                "showBlockingOverlay" -> {
                    val appName = call.argument<String>("appName") ?: "Unknown App"
                    val blockedPackage = call.argument<String>("blockedPackage") ?: ""
                    showBlockingOverlay(appName, blockedPackage)
                    result.success(null)
                }
                "hideBlockingOverlay" -> {
                    hideBlockingOverlay()
                    result.success(null)
                }
                "getAppUsageStats" -> {
                    val packageName = call.argument<String>("packageName")
                    val timeRange = call.argument<Int>("timeRange") ?: 1
                    if (packageName != null) {
                        val stats = getAppUsageStats(packageName, timeRange)
                        result.success(stats)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "getAllAppsUsage" -> {
                    val timeRange = call.argument<Int>("timeRange") ?: 1
                    val allStats = getAllAppsUsageStats(timeRange)
                    result.success(allStats)
                }
                "startBlockingService" -> {
                    try {
                        // Extract all the arguments Flutter is sending
                        val blockedAppsJson = call.argument<String>("blockedApps")
                        val focusMode = call.argument<Boolean>("focusMode") ?: false
                        val startHour = call.argument<Int>("startHour") ?: -1
                        val startMinute = call.argument<Int>("startMinute") ?: -1
                        val endHour = call.argument<Int>("endHour") ?: -1
                        val endMinute = call.argument<Int>("endMinute") ?: -1
                        
                        Log.d("FocusFlow", "🔍 START_SERVICE: Received JSON: '$blockedAppsJson'")
                        Log.d("FocusFlow", "🔍 START_SERVICE: Focus mode: $focusMode")
                        Log.d("FocusFlow", "🔍 START_SERVICE: Schedule: $startHour:$startMinute - $endHour:$endMinute")
                        
                        startAppBlockingService(blockedAppsJson, focusMode, startHour, startMinute, endHour, endMinute)
                        result.success("Blocking service started successfully")
                    } catch (e: Exception) {
                        Log.e("FocusFlow", "❌ Error in startBlockingService: ${e.message}", e)
                        result.error("SERVICE_ERROR", "Failed to start blocking service: ${e.message}", null)
                    }
                }
                "stopBlockingService" -> {
                    stopAppBlockingService()
                    result.success("Service stopped successfully")
                }
                "getLastBlockEvent" -> {
                    val lastEvent = getLastBlockingEvent()
                    result.success(lastEvent)
                }
                "sendNotification" -> {
                    val title = call.argument<String>("title") ?: "FocusFlow"
                    val message = call.argument<String>("message") ?: ""
                    sendLocalNotification(title, message)
                    result.success(null)
                }
                "updateBlockedApps" -> {
                    try {
                        // Get the JSON string and parse it
                        val blockedAppsJson = call.argument<String>("blockedApps")
                        Log.d("FocusFlow", "Received blocked apps JSON: $blockedAppsJson")
                        
                        val blockedApps = if (blockedAppsJson != null && blockedAppsJson.isNotEmpty()) {
                            parseBlockedAppsJson(blockedAppsJson)
                        } else {
                            emptyList<Map<String, Any>>()
                        }
                        
                        // Get schedule information
                        val focusMode = call.argument<Boolean>("focusMode") ?: false
                        val startHour = call.argument<Int>("startHour") ?: -1
                        val startMinute = call.argument<Int>("startMinute") ?: -1
                        val endHour = call.argument<Int>("endHour") ?: -1
                        val endMinute = call.argument<Int>("endMinute") ?: -1
                        
                        // Update time schedule
                        blockingStartHour = startHour
                        blockingStartMinute = startMinute
                        blockingEndHour = endHour
                        blockingEndMinute = endMinute
                        timeScheduleEnabled = (startHour != -1 && startMinute != -1 && endHour != -1 && endMinute != -1)
                        
                        Log.d("FocusFlow", "Focus mode: $focusMode, Time schedule enabled: $timeScheduleEnabled")
                        if (timeScheduleEnabled) {
                            Log.d("FocusFlow", "Schedule: $startHour:$startMinute - $endHour:$endMinute")
                        } else {
                            Log.d("FocusFlow", "24/7 blocking mode (no time schedule)")
                        }
                        
                        updateBlockedAppsList(blockedApps)
                        
                        // Send configuration to AppBlockingService
                        val serviceIntent = Intent(this, AppBlockingService::class.java).apply {
                            action = AppBlockingService.ACTION_UPDATE_BLOCKED_APPS
                            putExtra(AppBlockingService.EXTRA_BLOCKED_APPS, blockedAppsJson)
                            putExtra("startHour", startHour)
                            putExtra("startMinute", startMinute) 
                            putExtra("endHour", endHour)
                            putExtra("endMinute", endMinute)
                            putExtra(AppBlockingService.EXTRA_FOCUS_MODE, focusMode)
                        }
                        startService(serviceIntent)
                        Log.d("FocusFlow", "📡 Configuration sent to AppBlockingService")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("FocusFlow", "Error processing blocked apps: ${e.message}")
                        result.error("CAST_ERROR", "Failed to process blocked apps data: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Permissions channel for permission management
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageStatsSettings" -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(), 
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        try {
            // Try to open specific app settings first
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e("FocusFlow", "Failed to open specific usage settings, falling back to general: ${e.message}")
            try {
                // Fallback to general usage access settings
                val generalIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                startActivity(generalIntent)
            } catch (e2: Exception) {
                Log.e("FocusFlow", "Failed to open usage access settings: ${e2.message}")
                // Final fallback - open app info settings
                val appSettingsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(appSettingsIntent)
            }
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, 
                               Uri.parse("package:$packageName"))
            startActivity(intent)
        }
    }

    private fun getInstalledAppsList(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        val packageManager = this.packageManager
        
        try {
            Log.d("FocusFlow", "🔍 Starting app detection process...")
            
            // Get all launchable apps (apps with launcher intents) instead of just user-installed apps
            val launcherIntent = Intent(Intent.ACTION_MAIN, null)
            launcherIntent.addCategory(Intent.CATEGORY_LAUNCHER)
            val launchableApps = packageManager.queryIntentActivities(launcherIntent, 0)
            
            Log.d("FocusFlow", "📱 Found ${launchableApps.size} launchable apps")
            
            for (resolveInfo in launchableApps) {
                try {
                    val appInfo = resolveInfo.activityInfo.applicationInfo
                    val packageName = appInfo.packageName
                    
                    // Skip our own app and core Android system components
                    if (packageName != this.packageName &&
                        !packageName.startsWith("com.android.") &&
                        !packageName.startsWith("com.google.android.") &&
                        packageName != "android" &&
                        packageName != "com.android.systemui" &&
                        packageName != "com.android.settings") {
                        
                        val appName = packageManager.getApplicationLabel(appInfo).toString()
                        val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                        
                        val icon = try {
                            packageManager.getApplicationIcon(packageName)
                        } catch (e: Exception) {
                            null
                        }
                        
                        val appMap = mapOf(
                            "name" to appName,
                            "packageName" to packageName,
                            "isSystemApp" to isSystemApp,
                            "hasIcon" to (icon != null)
                        )
                        apps.add(appMap)
                    }
                } catch (e: Exception) {
                    Log.w("FocusFlow", "⚠️ Error processing app: ${e.message}")
                }
            }
            
            Log.d("FocusFlow", "📋 After filtering launchable apps: ${apps.size}")
            
            // Also include any user-installed apps that might not have launcher activities
            val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            val existingPackages = apps.map { it["packageName"] as String }.toSet()
            
            Log.d("FocusFlow", "🔍 Checking ${installedApps.size} total installed apps for missing ones...")
            
            for (appInfo in installedApps) {
                try {
                    val packageName = appInfo.packageName
                    
                    // Include user-installed apps that aren't already in the list
                    if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0 &&
                        packageName != this.packageName &&
                        !existingPackages.contains(packageName)) {
                        
                        val appName = packageManager.getApplicationLabel(appInfo).toString()
                        val icon = try {
                            packageManager.getApplicationIcon(packageName)
                        } catch (e: Exception) {
                            null
                        }
                        
                        val appMap = mapOf(
                            "name" to appName,
                            "packageName" to packageName,
                            "isSystemApp" to false,
                            "hasIcon" to (icon != null)
                        )
                        apps.add(appMap)
                    }
                } catch (e: Exception) {
                    Log.w("FocusFlow", "⚠️ Error processing installed app: ${e.message}")
                }
            }
            
            val finalApps = apps.sortedBy { it["name"] as String }
            Log.d("FocusFlow", "✅ Final app list: ${finalApps.size} apps")
            
            // Log some samples for debugging
            if (finalApps.isNotEmpty()) {
                Log.d("FocusFlow", "📋 Sample apps found:")
                finalApps.take(5).forEach { app ->
                    val isSystem = if (app["isSystemApp"] as Boolean) " (system)" else ""
                    Log.d("FocusFlow", "   - ${app["name"]}${isSystem}")
                }
                if (finalApps.size > 5) {
                    Log.d("FocusFlow", "   ... and ${finalApps.size - 5} more")
                }
            } else {
                Log.w("FocusFlow", "⚠️ WARNING: No apps found! This is unusual.")
            }
            
            return finalApps
            
        } catch (e: Exception) {
            Log.e("FocusFlow", "❌ Critical error in getInstalledAppsList: ${e.message}", e)
            return emptyList()
        }
    }

    private fun getCurrentRunningApp(): String? {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // For Android 5.0+, use Usage Stats
                if (hasUsageStatsPermission()) {
                    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                    val time = System.currentTimeMillis()
                    val usageStats = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_BEST, 
                        time - 1000 * 10, // Last 10 seconds
                        time
                    )
                    
                    if (usageStats.isNotEmpty()) {
                        val recentApp = usageStats.maxByOrNull { it.lastTimeUsed }
                        return recentApp?.packageName
                    }
                }
            } else {
                // For older versions, use getRunningTasks (deprecated but still works)
                @Suppress("DEPRECATION")
                val runningTasks = activityManager.getRunningTasks(1)
                if (runningTasks.isNotEmpty()) {
                    return runningTasks[0].topActivity?.packageName
                }
            }
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error getting current app: ${e.message}")
        }
        return null
    }

    private fun showBlockingOverlay(appName: String, blockedPackage: String) {
        try {
            if (overlayView != null) {
                hideBlockingOverlay()
            }
            
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.CENTER
            
            // Create overlay layout
            val overlayLayout = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.parseColor("#E3F2FD"))
                gravity = Gravity.CENTER
                setPadding(64, 64, 64, 64)
            }
            
            // App blocked title
            val titleText = TextView(this).apply {
                text = "🚫 App Blocked"
                textSize = 28f
                setTextColor(Color.parseColor("#1976D2"))
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }
            
            // Blocked app name
            val appNameText = TextView(this).apply {
                text = "\"$appName\" is blocked during your focus session"
                textSize = 18f
                setTextColor(Color.parseColor("#424242"))
                gravity = Gravity.CENTER
                setPadding(0, 32, 0, 32)
            }
            
            // Motivational message
            val messageText = TextView(this).apply {
                text = "🎯 Stay focused! You've got this!"
                textSize = 16f
                setTextColor(Color.parseColor("#666666"))
                gravity = Gravity.CENTER
                setPadding(0, 16, 0, 32)
            }
            
            // Go back button
            val goBackButton = Button(this).apply {
                text = "Return to Focus"
                textSize = 16f
                setBackgroundColor(Color.parseColor("#1976D2"))
                setTextColor(Color.WHITE)
                setPadding(32, 16, 32, 16)
                setOnClickListener {
                    hideBlockingOverlay()
                    moveTaskToBack(true)
                }
            }
            
            overlayLayout.addView(titleText)
            overlayLayout.addView(appNameText)
            overlayLayout.addView(messageText)
            overlayLayout.addView(goBackButton)
            
            overlayView = overlayLayout
            windowManager?.addView(overlayView, params)
            
            // Auto-hide after 5 seconds
            Handler(Looper.getMainLooper()).postDelayed({
                hideBlockingOverlay()
                moveTaskToBack(true)
            }, 5000)
            
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error showing overlay: ${e.message}")
        }
    }

    private fun hideBlockingOverlay() {
        try {
            overlayView?.let { view ->
                windowManager?.removeView(view)
                overlayView = null
            }
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error hiding overlay: ${e.message}")
        }
    }

    private fun getAppUsageStats(packageName: String, timeRangeHours: Int): Map<String, Any>? {
        if (!hasUsageStatsPermission()) return null
        
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - (timeRangeHours * 60 * 60 * 1000L)
            
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            val targetStats = usageStatsList.find { it.packageName == packageName }
            if (targetStats != null) {
                return mapOf(
                    "packageName" to targetStats.packageName,
                    "totalTimeInForeground" to targetStats.totalTimeInForeground,
                    "firstTimeStamp" to targetStats.firstTimeStamp,
                    "lastTimeStamp" to targetStats.lastTimeStamp,
                    "lastTimeUsed" to targetStats.lastTimeUsed
                )
            }
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error getting usage stats: ${e.message}")
        }
        
        return null
    }

    private fun getAllAppsUsageStats(timeRangeHours: Int): List<Map<String, Any>> {
        if (!hasUsageStatsPermission()) return emptyList()
        
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - (timeRangeHours * 60 * 60 * 1000L)
            
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            val packageManager = this.packageManager
            val result = mutableListOf<Map<String, Any>>()
            
            for (usageStats in usageStatsList) {
                if (usageStats.totalTimeInForeground > 0) {
                    try {
                        val appInfo = packageManager.getApplicationInfo(usageStats.packageName, 0)
                        val appName = packageManager.getApplicationLabel(appInfo).toString()
                        
                        result.add(mapOf(
                            "packageName" to usageStats.packageName,
                            "appName" to appName,
                            "totalTimeInForeground" to usageStats.totalTimeInForeground,
                            "firstTimeStamp" to usageStats.firstTimeStamp,
                            "lastTimeStamp" to usageStats.lastTimeStamp,
                            "lastTimeUsed" to usageStats.lastTimeUsed
                        ))
                    } catch (e: Exception) {
                        // Skip apps that can't be found (might be uninstalled)
                    }
                }
            }
            
            return result.sortedByDescending { it["totalTimeInForeground"] as Long }
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error getting all usage stats: ${e.message}")
        }
        
        return emptyList()
    }

    private fun startAppBlockingService(
        blockedAppsJson: String? = null,
        focusMode: Boolean = false,
        startHour: Int = -1,
        startMinute: Int = -1,
        endHour: Int = -1,
        endMinute: Int = -1
    ) {
        try {
            Log.d("FocusFlow", "Starting sophisticated AppBlockingService with configuration...")
            val intent = Intent(this, AppBlockingService::class.java).apply {
                action = AppBlockingService.ACTION_START_BLOCKING
                // Use the correct constant key that the service expects
                putExtra(AppBlockingService.EXTRA_BLOCKED_APPS, blockedAppsJson ?: "")
                putExtra("focusMode", focusMode)
                putExtra("startHour", startHour)
                putExtra("startMinute", startMinute)
                putExtra("endHour", endHour)
                putExtra("endMinute", endMinute)
            }
            startForegroundService(intent)
            Log.d("FocusFlow", "✅ AppBlockingService started successfully with configuration")
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error starting blocking service: ${e.message}")
        }
    }

    private fun stopAppBlockingService() {
        try {
            Log.d("FocusFlow", "Stopping AppBlockingService...")
            val intent = Intent(this, AppBlockingService::class.java)
            stopService(intent)
            Log.d("FocusFlow", "✅ AppBlockingService stopped successfully")
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error stopping blocking service: ${e.message}")
        }
    }

    private fun getLastBlockingEvent(): Map<String, Any>? {
        try {
            // This would return the last app blocking event
            // For now, return a mock response
            return mapOf(
                "timestamp" to System.currentTimeMillis(),
                "blockedApp" to "",
                "action" to "none"
            )
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error getting last block event: ${e.message}")
            return null
        }
    }

    private fun sendLocalNotification(title: String, message: String) {
        try {
            Log.d("FocusFlow", "Notification request: $title - $message")
            // This would send a local notification
            // For now, just log the notification request
            // In a full implementation, you'd use NotificationManager here
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error sending notification: ${e.message}")
        }
    }

    private fun updateBlockedAppsList(blockedApps: List<Map<String, Any>>) {
        try {
            blockedAppsPackages.clear()
            Log.d("FocusFlow", "Processing ${blockedApps.size} blocked apps...")
            
            for (app in blockedApps) {
                val packageName = app["packageName"]?.toString()
                val appName = app["appName"]?.toString() ?: "Unknown"
                val isBlocked = app["isBlocked"] as? Boolean ?: false
                
                Log.d("FocusFlow", "Raw app data: $app")
                Log.d("FocusFlow", "App: $appName ($packageName) - Blocked: $isBlocked")
                
                if (packageName != null && packageName.isNotEmpty() && isBlocked) {
                    blockedAppsPackages.add(packageName)
                    Log.d("FocusFlow", "✅ Added to blocked list: $packageName")
                } else {
                    Log.d("FocusFlow", "❌ Not added - packageName: $packageName, isBlocked: $isBlocked")
                }
            }
            
            Log.d("FocusFlow", "🚫 Updated blocked apps list: ${blockedAppsPackages.size} apps blocked")
            if (blockedAppsPackages.isNotEmpty()) {
                Log.d("FocusFlow", "🚫 Blocked packages: ${blockedAppsPackages.joinToString(", ")}")
            } else {
                Log.d("FocusFlow", "📱 No apps currently blocked")
            }
            
            // Start monitoring if we have blocked apps and permissions
            if (blockedAppsPackages.isNotEmpty() && hasUsageStatsPermission()) {
                Log.d("FocusFlow", "🎯 Monitoring will be handled by AppBlockingService")
                // startAppMonitoring() - Disabled, AppBlockingService handles this
            } else {
                stopAppMonitoring()
                if (blockedAppsPackages.isNotEmpty() && !hasUsageStatsPermission()) {
                    Log.w("FocusFlow", "⚠️ Cannot start monitoring - Usage stats permission not granted")
                }
            }
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error updating blocked apps list: ${e.message}")
        }
    }

    private fun startAppMonitoring() {
        if (isMonitoring) return
        
        isMonitoring = true
        monitoringHandler = Handler(Looper.getMainLooper())
        monitoringRunnable = object : Runnable {
            override fun run() {
                checkForBlockedApps()
                monitoringHandler?.postDelayed(this, 2000) // Check every 2 seconds
            }
        }
        monitoringHandler?.post(monitoringRunnable!!)
        Log.d("FocusFlow", "Started app monitoring for ${blockedAppsPackages.size} blocked apps")
    }

    private fun stopAppMonitoring() {
        if (!isMonitoring) return
        
        isMonitoring = false
        monitoringHandler?.removeCallbacks(monitoringRunnable!!)
        monitoringHandler = null
        monitoringRunnable = null
        Log.d("FocusFlow", "Stopped app monitoring")
    }

    private fun checkForBlockedApps() {
        // This method is now handled by AppBlockingService
        // MainActivity only handles configuration and Flutter communication
        Log.d("FocusFlow", "🎯 App blocking is now handled by AppBlockingService with sophisticated overlay")
    }

    private fun isInBlockingWindow(): Boolean {
        if (!timeScheduleEnabled) {
            Log.d("FocusFlow", "⏰ No time schedule - blocking 24/7")
            return true // 24/7 blocking when no schedule is set
        }
        
        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentMinute = calendar.get(Calendar.MINUTE)
        val currentTotalMinutes = currentHour * 60 + currentMinute
        val startTotalMinutes = blockingStartHour * 60 + blockingStartMinute
        val endTotalMinutes = blockingEndHour * 60 + blockingEndMinute
        
        val isInWindow = if (startTotalMinutes <= endTotalMinutes) {
            // Same day schedule (e.g., 9:00 - 17:00)
            currentTotalMinutes >= startTotalMinutes && currentTotalMinutes <= endTotalMinutes
        } else {
            // Cross midnight schedule (e.g., 22:00 - 06:00)
            currentTotalMinutes >= startTotalMinutes || currentTotalMinutes <= endTotalMinutes
        }
        
        Log.d("FocusFlow", "⏰ Time check: $currentHour:$currentMinute (${String.format("%02d", currentHour)}:${String.format("%02d", currentMinute)})")
        Log.d("FocusFlow", "⏰ Schedule: ${String.format("%02d", blockingStartHour)}:${String.format("%02d", blockingStartMinute)} - ${String.format("%02d", blockingEndHour)}:${String.format("%02d", blockingEndMinute)}")
        Log.d("FocusFlow", "⏰ In blocking window: $isInWindow")
        
        return isInWindow
    }

    private fun parseBlockedAppsJson(jsonString: String): List<Map<String, Any>> {
        try {
            val jsonArray = JSONArray(jsonString)
            val result = mutableListOf<Map<String, Any>>()
            
            Log.d("FocusFlow", "JSON parsing - input: $jsonString")
            
            for (i in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.getJSONObject(i)
                val appMap = mutableMapOf<String, Any>()
                
                Log.d("FocusFlow", "Processing JSON object $i: $jsonObject")
                
                // Extract the app data - Fix key mismatch
                if (jsonObject.has("package")) {
                    val pkg = jsonObject.getString("package")
                    appMap["packageName"] = pkg
                    Log.d("FocusFlow", "Set packageName to: $pkg")
                }
                if (jsonObject.has("name")) {
                    val name = jsonObject.getString("name")
                    appMap["appName"] = name
                    Log.d("FocusFlow", "Set appName to: $name")
                }
                if (jsonObject.has("blocked")) {
                    val blocked = jsonObject.getBoolean("blocked")
                    appMap["isBlocked"] = blocked
                    Log.d("FocusFlow", "Set isBlocked to: $blocked")
                }
                
                Log.d("FocusFlow", "Final appMap: $appMap")
                result.add(appMap)
            }
            
            Log.d("FocusFlow", "Parsed ${result.size} blocked apps from JSON - result: $result")
            return result
        } catch (e: Exception) {
            Log.e("FocusFlow", "Error parsing blocked apps JSON: ${e.message}")
            return emptyList()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAppMonitoring()
    }
}