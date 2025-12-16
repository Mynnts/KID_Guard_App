package com.seniorproject.kid_guard

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.SharedPreferences
import android.content.Context
import android.widget.Toast

import android.os.FileObserver
import java.io.File
import org.json.JSONArray

class AppAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private var blockedPackageSet: Set<String> = emptySet()
    private var fileObserver: FileObserver? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences("KidGuardPrefs", Context.MODE_PRIVATE)
        
        // Load initial from file if exists, else prefs
        loadBlocklistFromFile()
        
        // Setup FileObserver
        setupFileObserver()
        
        Toast.makeText(this, "Kid Guard Protection Active", Toast.LENGTH_SHORT).show()
    }

    private fun setupFileObserver() {
        val filesDir = applicationContext.filesDir
        val blocklistFile = File(filesDir, "blocked_apps.json")
        
        // Watch the directory because CREATE/DELETE/MODIFY might happen to the file
        fileObserver = object : FileObserver(filesDir.path, FileObserver.MODIFY or FileObserver.CREATE or FileObserver.MOVED_TO) {
            override fun onEvent(event: Int, path: String?) {
                if (path == "blocked_apps.json") {
                    loadBlocklistFromFile()
                }
            }
        }
        fileObserver?.startWatching()
    }

    private fun loadBlocklistFromFile() {
        try {
            val file = File(applicationContext.filesDir, "blocked_apps.json")
            if (file.exists()) {
                val jsonString = file.readText()
                val jsonArray = JSONArray(jsonString)
                val newSet = mutableSetOf<String>()
                for (i in 0 until jsonArray.length()) {
                    newSet.add(jsonArray.getString(i))
                }
                blockedPackageSet = newSet
                println("KidGuard: Updated blocklist from file: ${newSet.size} apps")
            } else {
                // Fallback to old prefs if file not found
                blockedPackageSet = prefs.getStringSet("blocked_apps", emptySet()) ?: emptySet()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
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
        // Use cached set for performance
        return blockedPackageSet.contains(packageName)
    }

    override fun onInterrupt() {
        fileObserver?.stopWatching()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        fileObserver?.stopWatching()
    }
}
