package com.focusflow.productivity

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📡 Boot/Package event received: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                
                // Check if we should auto-start the blocking service
                val prefs = context.getSharedPreferences("focusflow_blocking", Context.MODE_PRIVATE)
                val wasMonitoring = try {
                    val configJson = prefs.getString("blocking_config", null)
                    if (configJson != null) {
                        org.json.JSONObject(configJson).optBoolean("isMonitoring", false)
                    } else {
                        false
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error checking monitoring state: ${e.message}", e)
                    false
                }
                
                if (wasMonitoring) {
                    Log.d(TAG, "🔄 Restarting AppBlockingService after boot/update")
                    
                    val serviceIntent = Intent(context, AppBlockingService::class.java).apply {
                        action = AppBlockingService.ACTION_START_BLOCKING
                    }
                    
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }
                        Log.d(TAG, "✅ Service restart initiated")
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error restarting service: ${e.message}", e)
                    }
                } else {
                    Log.d(TAG, "💤 Service was not monitoring before, skipping restart")
                }
            }
        }
    }
}