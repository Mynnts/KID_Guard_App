package com.seniorproject.kid_guard

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.SharedPreferences
import android.content.Context
import android.widget.Toast

class AppAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences("KidGuardPrefs", Context.MODE_PRIVATE)
        Toast.makeText(this, "Kid Guard Protection Active", Toast.LENGTH_SHORT).show()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            if (isAppBlocked(packageName)) {
                performGlobalAction(GLOBAL_ACTION_HOME)
                Toast.makeText(this, "This app is blocked by Kid Guard", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun isAppBlocked(packageName: String): Boolean {
        val blockedApps = prefs.getStringSet("blocked_apps", emptySet()) ?: emptySet()
        return blockedApps.contains(packageName)
    }

    override fun onInterrupt() {
        // Handle interruption
    }
}
