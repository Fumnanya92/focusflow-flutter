package com.example.focusflow

import android.app.*
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.*
import kotlin.collections.HashMap
import java.text.SimpleDateFormat
import java.util.Calendar

class AppBlockingService : Service() {
    companion object {
        private const val TAG = "AppBlockingService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "app_blocking_channel"
        const val ACTION_START_BLOCKING = "start_blocking"
        const val ACTION_STOP_BLOCKING = "stop_blocking"
        const val ACTION_UPDATE_BLOCKED_APPS = "update_blocked_apps"
        
        // Intent extras
        const val EXTRA_BLOCKED_APPS = "blocked_apps"
        const val EXTRA_START_TIME = "start_time"
        const val EXTRA_END_TIME = "end_time"
        const val EXTRA_FOCUS_MODE = "focus_mode"
    }

    private var isMonitoring = false
    private var monitoringHandler: Handler? = null
    private var monitoringRunnable: Runnable? = null
    
    // Task reminder system
    private var taskReminderHandler: Handler? = null
    private var taskReminderRunnable: Runnable? = null
    private var lastTaskReminderTime = 0L
    
    // Accountability partner reminder schedule
    private var morningReminderHour = 8
    private var morningReminderMinute = 0
    private var eveningReminderHour = 18  // 6 PM for evening review
    private var eveningReminderMinute = 0
    private var middayReminderHour = 12
    private var middayReminderMinute = 30
    
    private val TASK_REMINDER_COOLDOWN = 60 * 60 * 1000L // 1 hour between reminders
    private val TASK_REMINDER_COOLDOWN_MINUTES = 30
    private var taskReminderOverlayView: View? = null
    
    // Blocking configuration
    private var blockedApps = mutableMapOf<String, String>() // package -> name
    private var blockingStartHour = -1
    private var blockingStartMinute = -1
    private var blockingEndHour = -1
    private var blockingEndMinute = -1
    private var isFocusModeEnabled = false
    
    // System services
    private lateinit var windowManager: WindowManager
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var notificationManager: NotificationManager
    private lateinit var sharedPrefs: SharedPreferences
    
    // Overlay management
    private var overlayView: View? = null
    private var isOverlayShowing = false
    private var lastBlockedApp = ""
    
    // Grace period tracking
    private val gracePeriodApps = mutableMapOf<String, Long>()
    private val blockingCooldowns = mutableMapOf<String, Long>() // Prevent overlay spam
    private val gracePeriodDuration = 30000L // 30 seconds
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "🚀 AppBlockingService created")
        
        // Initialize system services
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        sharedPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // Create notification channel
        createNotificationChannel()
        
        // Load saved configuration
        loadConfiguration()
        
        // Initialize monitoring handler
        monitoringHandler = Handler(Looper.getMainLooper())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "📡 Service started with action: ${intent?.action}")
        
        when (intent?.action) {
            ACTION_START_BLOCKING -> {
                startForegroundService()
                updateBlockingConfiguration(intent)
                startMonitoring()
                // Reset cooldown and start task reminders
                lastTaskReminderTime = System.currentTimeMillis() - TASK_REMINDER_COOLDOWN - (60 * 1000L)
                Log.d(TAG, "📝 🚀 Starting task reminder system with blocking service")
                startTaskReminderSystem()
            }
            ACTION_STOP_BLOCKING -> {
                stopMonitoring()
                stopForeground(true)
                stopSelf()
            }
            ACTION_UPDATE_BLOCKED_APPS -> {
                updateBlockingConfiguration(intent)
            }
            else -> {
                // Service restarted by system, restore previous state
                startForegroundService()
                if (shouldRestoreMonitoring()) {
                    startMonitoring()
                }
                // Initialize reminder system for accountability partnership
                Log.d(TAG, "📝 🤝 Starting accountability partner system")
                startTaskReminderSystem()
            }
        }
        
        // Return START_STICKY to restart service if killed
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Blocking Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors and blocks distracting apps"
                setSound(null, null)
                enableLights(false)
                enableVibration(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundService() {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🛡️ FocusFlow Active")
            .setContentText("Protecting your focus time")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock) // Using system icon for now
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        Log.d(TAG, "✅ Foreground service started")
    }

    private fun updateBlockingConfiguration(intent: Intent) {
        try {
            // Update blocked apps
            intent.getStringExtra(EXTRA_BLOCKED_APPS)?.let { appsJson ->
                val jsonArray = JSONArray(appsJson)
                blockedApps.clear()
                
                for (i in 0 until jsonArray.length()) {
                    val appObj = jsonArray.getJSONObject(i)
                    val packageName = appObj.getString("package")
                    val appName = appObj.getString("name")
                    val isBlocked = appObj.optBoolean("blocked", true)
                    
                    if (isBlocked) {
                        blockedApps[packageName] = appName
                    }
                }
                
                Log.d(TAG, "📱 Updated blocked apps: ${blockedApps.size} apps")
            }
            
            // Update time schedule
            blockingStartHour = intent.getIntExtra("startHour", -1)
            blockingStartMinute = intent.getIntExtra("startMinute", -1)
            blockingEndHour = intent.getIntExtra("endHour", -1)
            blockingEndMinute = intent.getIntExtra("endMinute", -1)
            
            // Update focus mode
            isFocusModeEnabled = intent.getBooleanExtra(EXTRA_FOCUS_MODE, false)
            
            // Save configuration
            saveConfiguration()
            
            Log.d(TAG, "⚙️ Configuration updated - Focus: $isFocusModeEnabled, Schedule: $blockingStartHour:$blockingStartMinute - $blockingEndHour:$blockingEndMinute")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error updating configuration: ${e.message}", e)
        }
    }

    private fun startMonitoring() {
        if (isMonitoring) return
        
        isMonitoring = true
        Log.d(TAG, "🔍 Starting continuous app monitoring...")
        
        monitoringRunnable = object : Runnable {
            override fun run() {
                if (isMonitoring) {
                    try {
                        checkCurrentApp()
                        // More frequent checking for instant response
                        monitoringHandler?.postDelayed(this, 500) // Check every 500ms
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Monitoring error: ${e.message}", e)
                        // Keep monitoring even on errors
                        monitoringHandler?.postDelayed(this, 1000)
                    }
                }
            }
        }
        
        monitoringHandler?.post(monitoringRunnable!!)
    }

    private fun stopMonitoring() {
        isMonitoring = false
        monitoringRunnable?.let { monitoringHandler?.removeCallbacks(it) }
        hideOverlay()
        Log.d(TAG, "🛑 Monitoring stopped")
    }

    private fun checkCurrentApp() {
        try {
            val currentApp = getCurrentForegroundApp()
            
            if (currentApp.isNullOrEmpty() || currentApp == packageName) {
                // Skip if no app or our own app
                return
            }
            
            // Check if this app should be blocked
            if (shouldBlockApp(currentApp)) {
                Log.d(TAG, "🚫 Blocking app: $currentApp")
                blockAppImmediately(currentApp)
            } else {
                // Log why app is not being blocked
                if (blockedApps.containsKey(currentApp)) {
                    Log.v(TAG, "📱 App $currentApp in blocked list but not blocking - checking conditions...")
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking current app: ${e.message}", e)
        }
    }

    private fun getCurrentForegroundApp(): String? {
        return try {
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 2000 // Last 2 seconds for more immediate detection
            
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            // Filter out system apps and find most recent user app
            val filteredStats = usageStats.filter { stat ->
                val timeSinceLastUsed = endTime - stat.lastTimeUsed
                timeSinceLastUsed < 3000 && // Used within last 3 seconds
                stat.packageName != packageName && // Not our own package
                !stat.packageName.startsWith("com.android.") && // Not system UI
                !stat.packageName.startsWith("com.google.android.") // Not Google system apps
            }
            
            // Find the most recently used app
            val mostRecent = filteredStats.maxByOrNull { it.lastTimeUsed }
            val result = mostRecent?.packageName
            
            if (result != null) {
                Log.v(TAG, "🔍 Current foreground app: $result")
            }
            
            result
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting foreground app: ${e.message}", e)
            null
        }
    }

    private fun shouldBlockApp(packageName: String): Boolean {
        // Check if app is in blocked list
        if (!blockedApps.containsKey(packageName)) {
            Log.v(TAG, "📱 App $packageName not in blocked list")
            return false
        }
        
        // Check ONLY user-requested grace periods (2 min or 30 min emergency)
        val graceEndTime = gracePeriodApps[packageName] ?: 0
        if (System.currentTimeMillis() < graceEndTime) {
            val remainingMinutes = (graceEndTime - System.currentTimeMillis()) / 60000
            Log.d(TAG, "⏰ Grace period active for $packageName: ${remainingMinutes} minutes remaining")
            return false // User requested grace period still active
        }
        
        // Check focus mode
        if (isFocusModeEnabled) {
            Log.d(TAG, "🎯 Focus mode enabled - blocking $packageName")
            return true
        }
        
        // Check time schedule
        if (blockingStartHour >= 0 && blockingEndHour >= 0) {
            val withinSchedule = isWithinBlockingSchedule()
            if (withinSchedule) {
                Log.d(TAG, "⏰ Within blocking schedule - blocking $packageName")
            } else {
                Log.d(TAG, "⏰ Outside blocking schedule - not blocking $packageName")
            }
            return withinSchedule
        }
        
        Log.d(TAG, "❓ No blocking conditions met for $packageName")
        return false
    }

    private fun isWithinBlockingSchedule(): Boolean {
        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentMinute = calendar.get(Calendar.MINUTE)
        val currentTimeInMinutes = currentHour * 60 + currentMinute
        
        val startTimeInMinutes = blockingStartHour * 60 + blockingStartMinute
        val endTimeInMinutes = blockingEndHour * 60 + blockingEndMinute
        
        val isWithinSchedule = if (startTimeInMinutes <= endTimeInMinutes) {
            // Same day schedule (e.g., 9:00 AM to 5:00 PM)
            currentTimeInMinutes in startTimeInMinutes..endTimeInMinutes
        } else {
            // Cross-midnight schedule (e.g., 10:00 PM to 6:00 AM)
            currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes <= endTimeInMinutes
        }
        
        Log.d(TAG, "⏰ TIME CHECK - Current: ${currentHour}:${String.format("%02d", currentMinute)} ($currentTimeInMinutes min), Schedule: ${blockingStartHour}:${String.format("%02d", blockingStartMinute)} - ${blockingEndHour}:${String.format("%02d", blockingEndMinute)} ($startTimeInMinutes-$endTimeInMinutes min), Within: $isWithinSchedule")
        
        return isWithinSchedule
    }

    private fun blockAppImmediately(packageName: String) {
        val appName = blockedApps[packageName] ?: packageName
        
        // Force close the app FIRST
        forceCloseApp(packageName)
        
        // Show beautiful native overlay (no Flutter dependency!)
        showBlockingOverlay(appName, packageName)
        
        // NO automatic grace period - user should be blocked every time they try to open the app
        // Grace period only applies when user explicitly requests it
        
        Log.d(TAG, "🔒 Successfully blocked: $appName with beautiful native overlay")
    }

    private fun forceCloseApp(packageName: String) {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // Modern approach for API 21+
                val intent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            } else {
                // Legacy approach for older versions
                activityManager.killBackgroundProcesses(packageName)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error closing app: ${e.message}", e)
        }
    }

    private fun showBlockingOverlay(appName: String, packageName: String) {
        try {
            if (isOverlayShowing && lastBlockedApp == packageName) {
                return // Overlay already showing for this app
            }
            
            // Short cooldown to prevent rapid overlay spam (only 2 seconds)
            val lastBlockTime = blockingCooldowns[packageName] ?: 0
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastBlockTime < 2000) {
                Log.d(TAG, "⏱️ Cooldown active for $packageName")
                return
            }
            
            // Set very short cooldown (2 seconds) - separate from grace periods
            blockingCooldowns[packageName] = currentTime
            
            hideOverlay() // Hide any existing overlay
            
            // Check overlay permission
            if (!Settings.canDrawOverlays(this)) {
                Log.w(TAG, "⚠️ No overlay permission - sending notification instead")
                sendBlockingNotification(appName)
                return
            }
            
            // Create overlay view
            val layoutParams = WindowManager.LayoutParams(
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
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }
            
            // Create simple blocking UI
            overlayView = createBlockingOverlayView(appName, packageName)
            windowManager.addView(overlayView, layoutParams)
            
            isOverlayShowing = true
            lastBlockedApp = packageName
            
            Log.d(TAG, "👁️ Overlay shown for: $appName")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing overlay: ${e.message}", e)
            // Fallback to notification
            sendBlockingNotification(appName)
        }
    }

    private fun createBlockingOverlayView(appName: String, packageName: String): View {
        // Create beautiful Material Design 3 blocking overlay exactly like overlay_screen.dart
        val mainLayout = android.widget.FrameLayout(this).apply {
            background = createGradientBackground()
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        
        val scrollView = android.widget.ScrollView(this).apply {
            layoutParams = android.widget.FrameLayout.LayoutParams(
                android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                android.widget.FrameLayout.LayoutParams.MATCH_PARENT
            )
            isFillViewport = true
        }
        
        val contentLayout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 120, 48, 120)
        }
        
        // 🚫 Large emoji
        val blockedEmoji = TextView(this).apply {
            text = "🚫"
            textSize = 96f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        
        // "Time to Refocus" title
        val titleText = TextView(this).apply {
            text = "Time to Refocus"
            textSize = 28f
            setTextColor(0xFFFFFFFF.toInt())
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }
        
        // Dynamic motivational message
        val messageText = TextView(this).apply {
            text = getRandomMotivationalMessage()
            textSize = 16f
            setTextColor(0xE5FFFFFF.toInt()) // 90% white opacity
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(40, 0, 40, 32)
        }
        
        // Points container (Material Design card-like)
        val pointsContainer = createPointsContainer()
        
        // Points consequence info
        val consequenceText = TextView(this).apply {
            text = "Closing app now: +2 points • Emergency unlock: -25 points"
            textSize = 12f
            setTextColor(0x99FFFFFF.toInt()) // 60% white opacity
            gravity = Gravity.CENTER
            setPadding(40, 16, 40, 48)
            typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.ITALIC)
        }
        
        // Action buttons container
        val buttonsContainer = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        
        // Close App Button (Primary - Green) - matches Flutter design exactly
        val closeButton = createMaterialButton(
            text = "Close App",
            backgroundColor = 0xFF19E66B.toInt(),
            textColor = 0xFF112117.toInt(),
            isPrimary = true
        ) {
            awardPointsForClosing()
            // Clear both grace period and cooldown - app should be blocked immediately if user tries again
            gracePeriodApps.remove(packageName) 
            blockingCooldowns.remove(packageName)
            hideOverlay()
            forceHomeScreen()
        }
        
        // Grace Period Button (Secondary) - matches Flutter design
        val gracePeriodButton = createMaterialButton(
            text = "Give me 2 minutes",
            backgroundColor = 0x33FFFFFF.toInt(), // 20% white opacity
            textColor = 0xFFFFFFFF.toInt(),
            isPrimary = false
        ) {
            startGracePeriod(packageName, 2)
            deductPointsForGracePeriod()
            hideOverlay()
        }
        
        // Emergency Unlock Button (Text button) - matches Flutter design
        val emergencyButton = createTextButton(
            text = "Emergency Unlock",
            textColor = 0xB3FFFFFF.toInt() // 70% white opacity
        ) {
            showEmergencyUnlockDialog(packageName)
        }
        
        // Add buttons with proper spacing (matching Flutter layout)
        buttonsContainer.addView(closeButton)
        buttonsContainer.addView(createSpacing(24))
        buttonsContainer.addView(gracePeriodButton)
        buttonsContainer.addView(createSpacing(24))
        buttonsContainer.addView(emergencyButton)
        
        // Assemble the complete overlay (exactly like Flutter layout)
        contentLayout.addView(blockedEmoji)
        contentLayout.addView(titleText)
        contentLayout.addView(messageText)
        contentLayout.addView(pointsContainer)
        contentLayout.addView(consequenceText)
        contentLayout.addView(buttonsContainer)
        
        scrollView.addView(contentLayout)
        mainLayout.addView(scrollView)
        
        return mainLayout
    }

    private fun hideOverlay() {
        try {
            overlayView?.let {
                windowManager.removeView(it)
                overlayView = null
                isOverlayShowing = false
                lastBlockedApp = ""
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error hiding overlay: ${e.message}", e)
        }
    }

    private fun sendBlockingNotification(appName: String) {
        try {
            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("🚫 App Blocked")
                .setContentText("$appName blocked during focus time")
                .setSmallIcon(android.R.drawable.ic_delete)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .build()

            notificationManager.notify(2000, notification)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending notification: ${e.message}", e)
        }
    }

    private fun notifyFlutterAppBlocked(packageName: String, appName: String) {
        try {
            // Save the block event to SharedPreferences for Flutter to read
            val blockData = JSONObject().apply {
                put("package", packageName)
                put("name", appName)
                put("timestamp", System.currentTimeMillis())
                put("shouldShowOverlay", true)
            }
            
            sharedPrefs.edit()
                .putString("flutter.last_block_event", blockData.toString())
                .putLong("flutter.last_block_timestamp", System.currentTimeMillis())
                .apply()
            
            Log.d(TAG, "📝 Saved block event to SharedPrefs: ${blockData.toString()}")
                
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error notifying Flutter: ${e.message}", e)
        }
    }



    private fun saveConfiguration() {
        try {
            val config = JSONObject().apply {
                put("blockedApps", JSONObject(blockedApps as Map<*, *>))
                put("startHour", blockingStartHour)
                put("startMinute", blockingStartMinute)
                put("endHour", blockingEndHour)
                put("endMinute", blockingEndMinute)
                put("focusMode", isFocusModeEnabled)
                put("isMonitoring", isMonitoring)
            }
            
            sharedPrefs.edit()
                .putString("blocking_config", config.toString())
                .apply()
                
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error saving configuration: ${e.message}", e)
        }
    }

    private fun loadConfiguration() {
        try {
            val configJson = sharedPrefs.getString("blocking_config", null)
            if (configJson != null) {
                val config = JSONObject(configJson)
                
                // Load blocked apps
                val blockedAppsJson = config.optJSONObject("blockedApps")
                if (blockedAppsJson != null) {
                    blockedApps.clear()
                    val keys = blockedAppsJson.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        blockedApps[key] = blockedAppsJson.getString(key)
                    }
                }
                
                // Load schedule
                blockingStartHour = config.optInt("startHour", -1)
                blockingStartMinute = config.optInt("startMinute", -1)
                blockingEndHour = config.optInt("endHour", -1)
                blockingEndMinute = config.optInt("endMinute", -1)
                
                // Load focus mode
                isFocusModeEnabled = config.optBoolean("focusMode", false)
                
                Log.d(TAG, "📁 Configuration loaded successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error loading configuration: ${e.message}", e)
        }
    }

    private fun shouldRestoreMonitoring(): Boolean {
        val configJson = sharedPrefs.getString("blocking_config", null)
        return if (configJson != null) {
            try {
                val config = JSONObject(configJson)
                val wasMonitoring = config.optBoolean("isMonitoring", false)
                val hasBlockedApps = config.optJSONObject("blockedApps")?.length() ?: 0 > 0
                val hasFocusMode = config.optBoolean("focusMode", false)
                val hasSchedule = config.optInt("startHour", -1) >= 0
                
                // Restore monitoring if we had blocked apps, focus mode, or schedule
                return wasMonitoring || hasBlockedApps || hasFocusMode || hasSchedule
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error checking restore state: ${e.message}", e)
                // Default to restore monitoring if we can't determine state
                true
            }
        } else {
            // No config found, but restore anyway to be safe
            true
        }
    }

    // Helper methods for beautiful overlay matching overlay_screen.dart exactly
    
    private fun createEmergencyUnlockWarningDialog(appName: String, currentPoints: Int, pointsToLose: Int, gracePeriod: Int, callback: (Boolean) -> Unit): View {
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN,
            android.graphics.PixelFormat.TRANSLUCENT
        )
        
        val rootView = android.widget.FrameLayout(this)
        rootView.setBackgroundColor(android.graphics.Color.parseColor("#CC000000"))
        rootView.layoutParams = layoutParams
        
        // Create warning card container
        val cardView = android.widget.LinearLayout(this)
        cardView.orientation = android.widget.LinearLayout.VERTICAL
        cardView.gravity = Gravity.CENTER
        cardView.background = createRoundedBackground(android.graphics.Color.parseColor("#E53935"), 16f)
        cardView.setPadding(48, 48, 48, 48)
        cardView.layoutParams = android.widget.FrameLayout.LayoutParams(
            (resources.displayMetrics.widthPixels * 0.9).toInt(),
            android.widget.FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        )
        
        // Add warning icon
        val iconView = android.widget.TextView(this)
        iconView.text = "⚠️"
        iconView.textSize = 48f
        iconView.gravity = Gravity.CENTER
        val iconParams = android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        )
        iconParams.setMargins(0, 0, 0, 24)
        iconView.layoutParams = iconParams
        
        // Add title
        val titleView = android.widget.TextView(this)
        titleView.text = "Emergency Unlock Warning"
        titleView.textSize = 22f
        titleView.setTextColor(android.graphics.Color.WHITE)
        titleView.typeface = android.graphics.Typeface.DEFAULT_BOLD
        titleView.gravity = Gravity.CENTER
        val titleParams = android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        )
        titleParams.setMargins(0, 0, 0, 16)
        titleView.layoutParams = titleParams
        
        // Add message
        val messageView = android.widget.TextView(this)
        messageView.text = "You are about to emergency unlock $appName.\n\n" +
                "• You will LOSE $pointsToLose points\n" +
                "• Current balance: $currentPoints points\n" +
                "• New balance: ${currentPoints - pointsToLose} points\n" +
                "• You'll get $gracePeriod minutes access\n\n" +
                "Are you sure you want to continue?"
        messageView.textSize = 16f
        messageView.setTextColor(android.graphics.Color.parseColor("#FFCCCB"))
        messageView.gravity = Gravity.CENTER
        messageView.setLineSpacing(8f, 1f)
        val msgParams = android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        )
        msgParams.setMargins(0, 0, 0, 32)
        messageView.layoutParams = msgParams
        
        // Create button container
        val buttonContainer = android.widget.LinearLayout(this)
        buttonContainer.orientation = android.widget.LinearLayout.HORIZONTAL
        buttonContainer.gravity = Gravity.CENTER
        buttonContainer.layoutParams = android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        )
        
        // Cancel button
        val cancelBtn = android.widget.Button(this)
        cancelBtn.text = "Cancel"
        cancelBtn.textSize = 16f
        cancelBtn.setTextColor(android.graphics.Color.WHITE)
        cancelBtn.background = createRoundedBackground(android.graphics.Color.parseColor("#4CAF50"), 12f)
        val cancelParams = android.widget.LinearLayout.LayoutParams(0, 120)
        cancelParams.weight = 1f
        cancelParams.setMargins(0, 0, 16, 0)
        cancelBtn.layoutParams = cancelParams
        cancelBtn.setOnClickListener {
            windowManager.removeView(rootView)
            callback(false)
        }
        
        // Confirm button
        val confirmBtn = android.widget.Button(this)
        confirmBtn.text = "Unlock Anyway"
        confirmBtn.textSize = 16f
        confirmBtn.setTextColor(android.graphics.Color.WHITE)
        confirmBtn.background = createRoundedBackground(android.graphics.Color.parseColor("#D32F2F"), 12f)
        val confirmParams = android.widget.LinearLayout.LayoutParams(0, 120)
        confirmParams.weight = 1f
        confirmParams.setMargins(16, 0, 0, 0)
        confirmBtn.layoutParams = confirmParams
        confirmBtn.setOnClickListener {
            windowManager.removeView(rootView)
            callback(true)
        }
        
        // Assemble the dialog
        buttonContainer.addView(cancelBtn)
        buttonContainer.addView(confirmBtn)
        
        cardView.addView(iconView)
        cardView.addView(titleView)
        cardView.addView(messageView)
        cardView.addView(buttonContainer)
        
        rootView.addView(cardView)
        return rootView
    }
    
    private fun createGradientBackground(): android.graphics.drawable.Drawable {
        return android.graphics.drawable.GradientDrawable().apply {
            colors = intArrayOf(
                0xF2112117.toInt(), // 95% opacity #112117
                0xF21A3224.toInt()  // 95% opacity #1A3224
            )
            orientation = android.graphics.drawable.GradientDrawable.Orientation.TL_BR
        }
    }
    
    private fun getRandomMotivationalMessage(): String {
        val messages = arrayOf(
            "🎯 Your focus session is active. Every time you resist adds +2 points!",
            "🌟 Stay strong! You're building discipline that creates success.",
            "🔥 This urge will pass. Your future self will thank you for staying focused.",
            "🏆 Champions choose discipline over distraction. You've got this!",
            "⚡ Redirect this energy into your important work instead.",
            "🎨 Your focus is creating something meaningful right now.",
            "🚀 You're training your brain for peak performance.",
            "💎 Resistance creates resilience. Keep building your mental strength.",
            "🌱 Each 'no' to distraction grows your willpower stronger.",
            "🎪 Break free from the scroll trap. Your goals are waiting."
        )
        val messageIndex = (System.currentTimeMillis() % messages.size).toInt()
        return messages[messageIndex]
    }
    
    private fun createPointsContainer(): View {
        val container = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            background = createRoundedBackground(0x1AFFFFFF.toInt(), 40f) // 10% white with rounded corners
            setPadding(32, 16, 32, 16)
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, 16)
            }
        }
        
        val starIcon = TextView(this).apply {
            text = "⭐"
            textSize = 16f
            setPadding(0, 0, 16, 0)
        }
        
        val pointsText = TextView(this).apply {
            text = "Current Points: ${getCurrentPoints()}"
            textSize = 14f
            setTextColor(0xFF19E66B.toInt())
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        
        container.addView(starIcon)
        container.addView(pointsText)
        return container
    }
    
    private fun createRoundedBackground(color: Int, radius: Float): android.graphics.drawable.Drawable {
        return android.graphics.drawable.GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius
            if (color == 0x1AFFFFFF.toInt()) {
                setStroke(2, 0x4D19E66B.toInt()) // 30% green border for points container
            }
        }
    }
    
    private fun createMaterialButton(
        text: String, 
        backgroundColor: Int, 
        textColor: Int, 
        isPrimary: Boolean,
        onClick: () -> Unit
    ): Button {
        return Button(this).apply {
            this.text = text
            textSize = 16f
            setTextColor(textColor)
            background = createRoundedBackground(backgroundColor, 56f) // 28dp radius = 56f
            setPadding(0, 32, 0, 32) // 16dp = 32 pixels
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            isAllCaps = false
            
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            )
            
            setOnClickListener { onClick() }
        }
    }
    
    private fun createTextButton(text: String, textColor: Int, onClick: () -> Unit): Button {
        return Button(this).apply {
            this.text = text
            textSize = 16f
            setTextColor(textColor)
            background = null // Transparent background
            setPadding(0, 32, 0, 32)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            isAllCaps = false
            
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            )
            
            setOnClickListener { onClick() }
        }
    }
    
    private fun createSpacing(heightDp: Int): View {
        return android.widget.Space(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT, 
                heightDp * 2 // Convert dp to pixels (rough conversion)
            )
        }
    }
    
    private fun getCurrentPoints(): Int {
        return sharedPrefs.getInt("total_points", 0)
    }
    
    private fun awardPointsForClosing() {
        val currentPoints = getCurrentPoints()
        val newPoints = currentPoints + 2
        sharedPrefs.edit().putInt("total_points", newPoints).apply()
        Log.d(TAG, "⭐ +2 points awarded for proper app closure. Total: $newPoints")
    }
    
    private fun deductPointsForGracePeriod() {
        val currentPoints = getCurrentPoints()
        val newPoints = maxOf(0, currentPoints - 5)
        sharedPrefs.edit().putInt("total_points", newPoints).apply()
        Log.d(TAG, "⭐ -5 points deducted for grace period. Total: $newPoints")
    }
    
    private fun deductPointsForEmergency() {
        val currentPoints = getCurrentPoints()
        val newPoints = maxOf(0, currentPoints - 25)
        sharedPrefs.edit().putInt("total_points", newPoints).apply()
        Log.d(TAG, "⭐ -25 points deducted for emergency unlock. Total: $newPoints")
    }
    
    private fun forceHomeScreen() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }
    
    private fun startGracePeriod(packageName: String, minutes: Int) {
        val graceEndTime = System.currentTimeMillis() + (minutes * 60 * 1000)
        gracePeriodApps[packageName] = graceEndTime
        Log.d(TAG, "⏰ Grace period started for $packageName: $minutes minutes")
    }
    
    private fun showEmergencyUnlockDialog(packageName: String) {
        val appName = blockedApps[packageName] ?: packageName
        val currentPoints = getCurrentPoints()
        val pointsToLose = 25
        val gracePeriod = 30
        
        // Create warning dialog overlay
        val dialogView = createEmergencyUnlockWarningDialog(appName, currentPoints, pointsToLose, gracePeriod) { confirmed ->
            if (confirmed) {
                // User confirmed emergency unlock
                startGracePeriod(packageName, gracePeriod)
                deductPointsForEmergency()
                hideOverlay()
                
                // Send notification about emergency unlock
                val notification = android.app.Notification.Builder(this, CHANNEL_ID)
                    .setContentTitle("🚨 Emergency Unlock Active")
                    .setContentText("$gracePeriod minutes granted. $pointsToLose points deducted. New balance: ${getCurrentPoints()} points")
                    .setSmallIcon(android.R.drawable.ic_dialog_alert)
                    .setAutoCancel(true)
                    .build()
                    
                notificationManager.notify(System.currentTimeMillis().toInt(), notification)
                Log.d(TAG, "🚨 Emergency unlock granted for $packageName")
            }
            // If not confirmed, do nothing (stay on blocking screen)
        }
        
        // Show warning dialog as overlay
        try {
            windowManager.addView(dialogView, dialogView.layoutParams)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing emergency unlock dialog", e)
            // Fallback to direct unlock if dialog fails
            startGracePeriod(packageName, gracePeriod)
            deductPointsForEmergency()
            hideOverlay()
        }
    }

    // Task Reminder System Implementation
    
    private fun startTaskReminderSystem() {
        taskReminderHandler = Handler(Looper.getMainLooper())
        
        taskReminderRunnable = object : Runnable {
            override fun run() {
                checkForTaskReminders()
                // Check every 10 minutes for optimal performance
                taskReminderHandler?.postDelayed(this, 10 * 60 * 1000L)
            }
        }
        
        taskReminderHandler?.post(taskReminderRunnable!!)
        val calendar = Calendar.getInstance()
        val currentTime = "${calendar.get(Calendar.HOUR_OF_DAY)}:${String.format("%02d", calendar.get(Calendar.MINUTE))}"
        Log.d(TAG, "📝 🤝 Accountability partner system started at $currentTime")
        Log.d(TAG, "📝 📅 Reminder schedule: Morning $morningReminderHour:${String.format("%02d", morningReminderMinute)}, Midday $middayReminderHour:${String.format("%02d", middayReminderMinute)}, Evening $eveningReminderHour:${String.format("%02d", eveningReminderMinute)}")
    }
    
    private fun checkForTaskReminders() {
        val currentTime = System.currentTimeMillis()
        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentMinute = calendar.get(Calendar.MINUTE)
        
        Log.d(TAG, "📝 🤝 ACCOUNTABILITY CHECK - Time: $currentHour:${String.format("%02d", currentMinute)}")
        
        // Check cooldown
        val timeSinceLast = currentTime - lastTaskReminderTime
        if (timeSinceLast < TASK_REMINDER_COOLDOWN) {
            val cooldownRemaining = (TASK_REMINDER_COOLDOWN - timeSinceLast) / (60 * 1000)
            Log.d(TAG, "📝 ⏰ Cooldown active: ${cooldownRemaining} minutes remaining")
            return
        }
        
        // Check if it's time for any accountability reminders
        val morningMatch = shouldShowMorningReminder(currentHour, currentMinute)
        val middayMatch = shouldShowMiddayReminder(currentHour, currentMinute)
        val eveningMatch = shouldShowEveningReminder(currentHour, currentMinute)
        
        Log.d(TAG, "📝 Reminder windows - Morning: $morningMatch, Midday: $middayMatch, Evening: $eveningMatch")
        
        when {
            morningMatch -> {
                Log.d(TAG, "📝 🌅 Morning accountability check triggered!")
                checkTaskStatusAndShowMorningReminder()
            }
            middayMatch -> {
                Log.d(TAG, "📝 ⏰ Midday accountability check triggered!")
                checkTaskStatusAndShowMiddayReminder()
            }
            eveningMatch -> {
                Log.d(TAG, "📝 🌆 Evening accountability check triggered!")
                checkTaskStatusAndShowEveningReminder()
            }
            else -> {
                Log.v(TAG, "📝 No accountability reminder windows active")
            }
        }
    }
    
    private fun shouldShowMorningReminder(hour: Int, minute: Int): Boolean {
        val inTimeWindow = hour == morningReminderHour && minute >= morningReminderMinute && minute < morningReminderMinute + 10
        Log.d(TAG, "📝 Morning check: $hour:$minute vs $morningReminderHour:$morningReminderMinute -> $inTimeWindow")
        return inTimeWindow
    }
    
    private fun shouldShowMiddayReminder(hour: Int, minute: Int): Boolean {
        val inTimeWindow = hour == middayReminderHour && minute >= middayReminderMinute && minute < middayReminderMinute + 10
        Log.d(TAG, "📝 Midday check: $hour:$minute vs $middayReminderHour:$middayReminderMinute -> $inTimeWindow")
        return inTimeWindow
    }
    
    private fun shouldShowEveningReminder(hour: Int, minute: Int): Boolean {
        val inTimeWindow = hour == eveningReminderHour && minute >= eveningReminderMinute && minute < eveningReminderMinute + 10
        Log.d(TAG, "📝 Evening check: $hour:$minute vs $eveningReminderHour:$eveningReminderMinute -> $inTimeWindow")
        return inTimeWindow
    }
    
    // Accountability Partner Check Functions
    private fun checkTaskStatusAndShowMorningReminder() {
        lastTaskReminderTime = System.currentTimeMillis()
        
        // Get task status from Flutter (we'll implement a simple method channel call)
        getTaskStatusFromFlutter { taskData ->
            val hasTasksToday = taskData["hasTasksToday"] as? Boolean ?: false
            val taskCount = taskData["taskCount"] as? Int ?: 0
            
            val (title, message) = if (hasTasksToday) {
                Pair(
                    "🌟 Morning Check-in",
                    "Great! I see you have $taskCount tasks planned. You're already ahead of most people. Let's make today amazing! 💪"
                )
            } else {
                Pair(
                    "🌅 Good Morning, Champion!",
                    "Ready to plan your day? What are your main goals today? I'm here to help you stay accountable! 🎯"
                )
            }
            
            showTaskReminderOverlay(title, message, "morning_planning")
        }
    }
    
    private fun checkTaskStatusAndShowMiddayReminder() {
        lastTaskReminderTime = System.currentTimeMillis()
        
        getTaskStatusFromFlutter { taskData ->
            val totalTasks = taskData["taskCount"] as? Int ?: 0
            val completedTasks = taskData["completedTasks"] as? Int ?: 0
            val progress = if (totalTasks > 0) (completedTasks * 100) / totalTasks else 0
            
            val (title, message) = when {
                totalTasks == 0 -> Pair(
                    "⏰ Midday Reality Check",
                    "Half the day is gone! No tasks planned yet? That's okay - it's never too late to get organized. What's one thing you can accomplish today? 🚀"
                )
                progress >= 70 -> Pair(
                    "🔥 You're Crushing It!",
                    "Wow! $completedTasks out of $totalTasks tasks done ($progress%). You're absolutely smashing your goals! Keep this momentum going! 💪⚡"
                )
                progress >= 40 -> Pair(
                    "📈 Great Progress!",
                    "Nice work! $completedTasks out of $totalTasks tasks completed ($progress%). You're on track! What's next on your list? 🎯"
                )
                completedTasks > 0 -> Pair(
                    "💪 Keep Moving Forward",
                    "$completedTasks out of $totalTasks tasks done ($progress%). You've started strong! Don't lose momentum - which task will you tackle next? 🚀"
                )
                else -> Pair(
                    "⚡ Time for Action!",
                    "The day is half over and $totalTasks tasks are still waiting. No judgment - let's get ONE thing done right now! Which task feels easiest to start? 💫"
                )
            }
            
            showTaskReminderOverlay(title, message, "midday_progress")
        }
    }
    
    private fun checkTaskStatusAndShowEveningReminder() {
        lastTaskReminderTime = System.currentTimeMillis()
        
        getTaskStatusFromFlutter { taskData ->
            val totalTasks = taskData["taskCount"] as? Int ?: 0
            val completedTasks = taskData["completedTasks"] as? Int ?: 0
            val pendingTasks = totalTasks - completedTasks
            val progress = if (totalTasks > 0) (completedTasks * 100) / totalTasks else 0
            
            val (title, message) = when {
                totalTasks == 0 -> Pair(
                    "🌅 Tomorrow is a New Day",
                    "Today was unplanned, but that doesn't define you! Let's make tomorrow intentional. What's one goal you want to achieve? 🌟"
                )
                completedTasks == totalTasks -> Pair(
                    "🏆 INCREDIBLE! 100% Complete!",
                    "You absolutely CRUSHED every single task today! $completedTasks out of $totalTasks done. You're proof that dreams become reality through action! 🎉✨"
                )
                progress >= 80 -> Pair(
                    "🌟 Amazing Day!",
                    "Outstanding! $completedTasks out of $totalTasks completed ($progress%)! You're in the top 5% of achievers. $pendingTasks tasks left - tackle them tomorrow and keep this winning streak alive! 🚀"
                )
                progress >= 50 -> Pair(
                    "💪 Solid Progress!",
                    "Great work today! $completedTasks out of $totalTasks done ($progress%). You're building the habit of follow-through. $pendingTasks tasks remaining - carry that momentum into tomorrow! 🎯"
                )
                completedTasks > 0 -> Pair(
                    "🌱 Progress is Progress!",
                    "You got $completedTasks tasks done today - that's more than zero! Every action counts. $pendingTasks tasks are waiting for tomorrow. You've got this! 💫"
                )
                else -> Pair(
                    "🌙 Rest and Reset",
                    "Today didn't go as planned with $totalTasks tasks still pending. That's human! Tomorrow is your comeback story. Which ONE task will you definitely complete tomorrow? 🌅"
                )
            }
            
            showTaskReminderOverlay(title, message, "evening_review")
        }
    }
    
    private fun getTaskStatusFromFlutter(callback: (Map<String, Any>) -> Unit) {
        try {
            // Send method channel call to Flutter to get task data
            val intent = Intent().apply {
                setClassName(packageName, "com.example.focusflow.MainActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("methodChannel", "getTaskStatus")
            }
            
            // For now, use mock data until we implement the method channel
            // In production, this would make an actual call to Flutter
            val mockData = mapOf(
                "hasTasksToday" to true,
                "taskCount" to 3,
                "completedTasks" to 1
            )
            
            callback(mockData)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting task status: ${e.message}", e)
            // Fallback to generic message
            val fallbackData = mapOf(
                "hasTasksToday" to false,
                "taskCount" to 0,
                "completedTasks" to 0
            )
            callback(fallbackData)
        }
    }
    
    private fun showTaskReminderOverlay(title: String, message: String, type: String) {
        Log.d(TAG, "📝 🎨 Creating task reminder overlay: $title")
        try {
            // Check overlay permission
            if (!Settings.canDrawOverlays(this)) {
                Log.w(TAG, "📝 ⚠️ No overlay permission, sending notification instead")
                sendTaskReminderNotification(title, message)
                return
            }
            Log.d(TAG, "📝 ✅ Overlay permission granted, creating overlay...")
            
            // Hide any existing overlays
            hideOverlay()
            
            val layoutParams = WindowManager.LayoutParams(
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
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }
            
            overlayView = createTaskReminderOverlayView(title, message, type)
            windowManager.addView(overlayView, layoutParams)
            
            isOverlayShowing = true
            // Update reminder timestamp for proper cooldown
            // lastTaskReminderTime = System.currentTimeMillis()
            
            Log.d(TAG, "📝 ✨ Task reminder overlay successfully displayed!")
            Log.d(TAG, "📝 📅 Title: $title")
            Log.d(TAG, "📝 💬 Message: $message")
            Log.d(TAG, "📝 🏷️ Type: $type")
            Log.d(TAG, "📝 🖱️ Overlay should be visible with clickable buttons")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing task reminder overlay: ${e.message}", e)
            sendTaskReminderNotification(title, message)
        }
    }
    
    private fun createTaskReminderOverlayView(title: String, message: String, type: String): View {
        val mainLayout = android.widget.FrameLayout(this).apply {
            background = createTaskReminderGradientBackground()
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        
        val contentLayout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(64, 120, 64, 120)
        }
        
        // Icon based on reminder type
        val iconEmoji = when (type) {
            "morning_planning" -> "🌅"
            "midday_progress" -> "⏰"
            "evening_review" -> "🌆"
            else -> "📝"
        }
        
        val emojiIcon = TextView(this).apply {
            text = iconEmoji
            textSize = 72f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        
        val titleText = TextView(this).apply {
            text = title
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }
        
        val messageText = TextView(this).apply {
            text = message
            textSize = 16f
            setTextColor(0xE5FFFFFF.toInt())
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(0, 0, 0, 48)
        }
        
        // Action buttons
        val buttonsContainer = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        
        val openTasksButton = createMaterialButton(
            text = "Open Tasks",
            backgroundColor = 0xFF19E66B.toInt(),
            textColor = 0xFF112117.toInt(),
            isPrimary = true
        ) {
            Log.d(TAG, "📝 💆 BUTTON CLICKED: Open Tasks button pressed!")
            hideOverlay()
            openTasksApp()
            Log.d(TAG, "📝 ✅ Opening tasks app...")
        }
        
        val remindLaterButton = createMaterialButton(
            text = "Remind Later",
            backgroundColor = 0x33FFFFFF.toInt(),
            textColor = 0xFFFFFFFF.toInt(),
            isPrimary = false
        ) {
            Log.d(TAG, "📝 💆 BUTTON CLICKED: Remind Later button pressed!")
            hideOverlay()
            scheduleReminderLater()
            Log.d(TAG, "📝 ⏰ Scheduling reminder for later...")
        }
        
        // Add margin between buttons
        openTasksButton.layoutParams = android.widget.LinearLayout.LayoutParams(
            0, android.widget.LinearLayout.LayoutParams.WRAP_CONTENT, 1f
        ).apply {
            setMargins(0, 0, 16, 0)
        }
        
        remindLaterButton.layoutParams = android.widget.LinearLayout.LayoutParams(
            0, android.widget.LinearLayout.LayoutParams.WRAP_CONTENT, 1f
        ).apply {
            setMargins(16, 0, 0, 0)
        }
        
        buttonsContainer.addView(openTasksButton)
        buttonsContainer.addView(remindLaterButton)
        
        contentLayout.addView(emojiIcon)
        contentLayout.addView(titleText)
        contentLayout.addView(messageText)
        contentLayout.addView(buttonsContainer)
        
        mainLayout.addView(contentLayout)
        return mainLayout
    }
    
    private fun createTaskReminderGradientBackground(): android.graphics.drawable.Drawable {
        return android.graphics.drawable.GradientDrawable().apply {
            colors = intArrayOf(
                0xF0134E4A.toInt(), // Deep teal
                0xF0112117.toInt()  // Dark green
            )
            orientation = android.graphics.drawable.GradientDrawable.Orientation.TL_BR
        }
    }
    

    
    private fun scheduleReminderLater() {
        // Schedule reminder for 1 hour later
        lastTaskReminderTime = System.currentTimeMillis() - TASK_REMINDER_COOLDOWN + (60 * 60 * 1000L)
        
        val notification = android.app.Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("📝 Task Reminder Snoozed")
            .setContentText("We'll remind you again in 1 hour")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
            .build()
            
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
        Log.d(TAG, "⏰ Task reminder snoozed for 1 hour")
    }
    
    private fun sendTaskReminderNotification(title: String, message: String) {
        val notification = android.app.Notification.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
            .build()
            
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
        Log.d(TAG, "📬 Task reminder notification sent")
    }
    




    private fun hideTaskReminderOverlay() {
        try {
            taskReminderOverlayView?.let { overlay ->
                windowManager.removeView(overlay)
                taskReminderOverlayView = null
                Log.d(TAG, "✅ Task reminder overlay hidden")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error hiding task reminder overlay", e)
        }
    }

    private fun openTasksApp() {
        try {
            val intent = Intent().apply {
                setClassName(packageName, "com.example.focusflow.MainActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("route", "/tasks")
            }
            startActivity(intent)
            Log.d(TAG, "📱 Tasks app opened")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error opening tasks app", e)
        }
    }

    private fun shouldShowTaskReminder(): Boolean {
        val now = Calendar.getInstance()
        val currentHour = now.get(Calendar.HOUR_OF_DAY)
        val currentMinute = now.get(Calendar.MINUTE)
        
        // Check if it's a reminder time (±5 minutes window)
        val reminderTimes = listOf(
            Pair(morningReminderHour, 0), // 8:00 AM
            Pair(12, 30), // 12:30 PM
            Pair(eveningReminderHour, 0)  // 6:00 PM
        )
        
        for ((hour, minute) in reminderTimes) {
            val timeDiff = Math.abs((currentHour * 60 + currentMinute) - (hour * 60 + minute))
            if (timeDiff <= 5) { // Within 5-minute window
                // Check cooldown
                val lastReminder = sharedPrefs.getLong("last_task_reminder", 0)
                val cooldownPeriod = TASK_REMINDER_COOLDOWN_MINUTES * 60 * 1000L
                
                if (System.currentTimeMillis() - lastReminder >= cooldownPeriod) {
                    // Update last reminder time
                    sharedPrefs.edit()
                        .putLong("last_task_reminder", System.currentTimeMillis())
                        .apply()
                    return true
                }
            }
        }
        return false
    }

    private fun stopTaskReminderSystem() {
        taskReminderRunnable?.let { taskReminderHandler?.removeCallbacks(it) }
        taskReminderHandler = null
        Log.d(TAG, "🛑 Task reminder system stopped")
    }

    override fun onDestroy() {
        super.onDestroy()
        stopMonitoring()
        stopTaskReminderSystem()
        Log.d(TAG, "💀 AppBlockingService destroyed")
    }
}