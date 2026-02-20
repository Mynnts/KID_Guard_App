package com.seniorproject.kid_guard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Boot Receiver to auto-start ChildModeService when device boots
 * This ensures Kid Guard protection continues after device restart
 */
class BootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            // Check if child mode was active before reboot
            val prefs = context.getSharedPreferences("KidGuardPrefs", Context.MODE_PRIVATE)
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            val isChildModeActive = prefs.getBoolean("isChildModeActive", false) ||
                    flutterPrefs.getBoolean("flutter.isChildModeActive", false)
            
            if (isChildModeActive) {
                // Start ChildModeService
                val childModePrefs = context.getSharedPreferences("ChildModePrefs", Context.MODE_PRIVATE)
                val serviceIntent = Intent(context, ChildModeService::class.java).apply {
                    putExtra(ChildModeService.EXTRA_CHILD_NAME, childModePrefs.getString("childName", "ลูก"))
                    putExtra(ChildModeService.EXTRA_SCREEN_TIME, childModePrefs.getInt("screenTime", 0))
                    putExtra(ChildModeService.EXTRA_DAILY_LIMIT, childModePrefs.getInt("dailyLimit", 0))
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                
                println("BootReceiver: Auto-started ChildModeService on boot")
            }
        }
    }
}
