package com.seniorproject.kid_guard

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.View
import android.view.LayoutInflater
import android.widget.TextView
import android.content.SharedPreferences
import android.content.Context
import android.content.Intent
import android.widget.Toast
import android.os.Handler
import android.os.Looper
import android.os.FileObserver
import java.io.File
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*
import com.google.firebase.firestore.FirebaseFirestore

/**
 * Enhanced Accessibility Service that runs in the background
 * - Monitors app usage
 * - Tracks screen time
 * - Enforces time limits
 * - Checks sleep schedule and quiet times
 * - Shows overlay when needed
 */
class AppAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private var blockedPackageSet: Set<String> = emptySet()
    private var fileObserver: FileObserver? = null
    
    // Screen Time Tracking
    private var isChildModeActive = false
    private var screenTimeSeconds = 0
    private var limitUsedSeconds = 0
    private var dailyTimeLimit = 0  // 0 = no limit
    private var lastDateString = ""
    
    // Schedule Settings
    private var sleepScheduleEnabled = false
    private var bedtimeHour = 20
    private var bedtimeMinute = 0
    private var wakeHour = 7
    private var wakeMinute = 0
    private var quietTimes: List<QuietTimePeriod> = emptyList()
    
    // Time Limit Disabled Until
    private var timeLimitDisabledUntil: Long = 0
    
    // Child/Parent IDs for Firebase sync (optional, can work offline)
    private var childId: String = ""
    private var parentId: String = ""
    
    // Timer for screen time
    private val handler = Handler(Looper.getMainLooper())
    private var screenTimeRunnable: Runnable? = null
    
    // Current state
    private var isOverlayShowing = false
    private var lastBlockedPackage: String? = null
    private var currentRestrictionType: RestrictionType = RestrictionType.NONE
    
    // Screen Timeout Feature
    private var screenTimeoutMinutes = 5 // Default 5 minutes, configurable by parent
    private var lastActivityTime: Long = System.currentTimeMillis()
    private var screenTimeoutRunnable: Runnable? = null
    
    // Auto-exit blocked app after countdown (10 seconds)
    private var autoExitRunnable: Runnable? = null
    private val autoExitDelayMs = 10000L // 10 seconds
    
    // Restriction type enum for proper tracking
    enum class RestrictionType {
        NONE, SLEEP, QUIET, TIME_LIMIT, BLOCKED_APP, DEVICE_LOCKED, SCREEN_TIMEOUT
    }

    // Firestore reference for updating lock status
    private val firestore = FirebaseFirestore.getInstance()

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences("KidGuardPrefs", Context.MODE_PRIVATE)
        
        // Load all settings
        loadBlocklistFromFile()
        loadSettings()
        
        // Setup FileObserver for blocklist changes
        setupFileObserver()
        
        // Setup SharedPreferences listener for Flutter changes
        setupPrefsListener()
        
        // Start screen time tracking if child mode is active
        if (isChildModeActive) {
            startScreenTimeTracking()
        }
        
        // Periodic settings reload (every 5 seconds) to catch Flutter changes
        handler.post(object : Runnable {
            override fun run() {
                loadSettings()
                handler.postDelayed(this, 5000)
            }
        })
        
        // Start screen timeout checking
        startScreenTimeoutCheck()
        
        Toast.makeText(this, "Kid Guard Protection Active", Toast.LENGTH_SHORT).show()
    }
    
    private fun setupPrefsListener() {
        // Listen to Flutter SharedPreferences changes
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        flutterPrefs.registerOnSharedPreferenceChangeListener { _, key ->
            if (key == "flutter.isChildModeActive") {
                loadSettings()
            }
        }
    }

    private fun setupFileObserver() {
        val filesDir = applicationContext.filesDir
        
        fileObserver = object : FileObserver(filesDir.path, MODIFY or CREATE or MOVED_TO) {
            override fun onEvent(event: Int, path: String?) {
                when (path) {
                    "blocked_apps.json" -> loadBlocklistFromFile()
                    "kid_guard_settings.json" -> loadSettings()
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
                println("KidGuard: Updated blocklist: ${newSet.size} apps")
            } else {
                blockedPackageSet = prefs.getStringSet("blocked_apps", emptySet()) ?: emptySet()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Load settings from SharedPreferences (primary) or JSON file (backup)
     */
    private fun loadSettings() {
        try {
            val wasActive = isChildModeActive
            
            // Try Flutter SharedPreferences first
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val flutterChildMode = flutterPrefs.getBoolean("flutter.isChildModeActive", false)
            val prefsChildMode = prefs.getBoolean("isChildModeActive", false)
            
            isChildModeActive = flutterChildMode || prefsChildMode
            
            // Load from prefs
            childId = prefs.getString("childId", "") ?: ""
            parentId = prefs.getString("parentId", "") ?: ""
            screenTimeSeconds = prefs.getInt("screenTime", 0)
            limitUsedSeconds = prefs.getInt("limitUsedTime", 0)
            dailyTimeLimit = prefs.getInt("dailyTimeLimit", 0)
            timeLimitDisabledUntil = prefs.getLong("timeLimitDisabledUntil", 0)
            sleepScheduleEnabled = prefs.getBoolean("sleepScheduleEnabled", false)
            bedtimeHour = prefs.getInt("bedtimeHour", 20)
            bedtimeMinute = prefs.getInt("bedtimeMinute", 0)
            wakeHour = prefs.getInt("wakeHour", 7)
            wakeMinute = prefs.getInt("wakeMinute", 0)
            
            // Also try JSON file backup
            val file = File(applicationContext.filesDir, "kid_guard_settings.json")
            if (file.exists()) {
                try {
                    val json = JSONObject(file.readText())
                    if (!isChildModeActive) isChildModeActive = json.optBoolean("isChildModeActive", false)
                    if (dailyTimeLimit == 0) dailyTimeLimit = json.optInt("dailyTimeLimit", 0)
                    if (childId.isEmpty()) childId = json.optString("childId", "")
                    if (parentId.isEmpty()) parentId = json.optString("parentId", "")
                    if (!sleepScheduleEnabled) {
                        sleepScheduleEnabled = json.optBoolean("sleepScheduleEnabled", false)
                        bedtimeHour = json.optInt("bedtimeHour", 20)
                        bedtimeMinute = json.optInt("bedtimeMinute", 0)
                        wakeHour = json.optInt("wakeHour", 7)
                        wakeMinute = json.optInt("wakeMinute", 0)
                    }
                    val quietTimesArray = json.optJSONArray("quietTimes")
                    if (quietTimesArray != null && quietTimes.isEmpty()) {
                        val list = mutableListOf<QuietTimePeriod>()
                        for (i in 0 until quietTimesArray.length()) {
                            val qt = quietTimesArray.getJSONObject(i)
                            list.add(QuietTimePeriod(
                                name = qt.optString("name", ""),
                                startHour = qt.optInt("startHour", 0),
                                startMinute = qt.optInt("startMinute", 0),
                                endHour = qt.optInt("endHour", 0),
                                endMinute = qt.optInt("endMinute", 0),
                                enabled = qt.optBoolean("enabled", false)
                            ))
                        }
                        quietTimes = list
                    }
                    
                    // Screen timeout setting (default 5 minutes, 0 = disabled)
                    screenTimeoutMinutes = json.optInt("screenTimeoutMinutes", 5)
                } catch (e: Exception) { e.printStackTrace() }
            }
            
            println("KidGuard: Settings loaded - ChildMode=$isChildModeActive, Limit=$dailyTimeLimit, Timeout=$screenTimeoutMinutes min")
            
            if (isChildModeActive && !wasActive) startScreenTimeTracking()
            else if (!isChildModeActive && wasActive) stopScreenTimeTracking()
            
            checkDateChange()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Check if date changed and reset daily counters
     */
    private fun checkDateChange() {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val savedDate = prefs.getString("lastDate", "") ?: ""
        
        if (savedDate != today) {
            // New day - reset counters
            screenTimeSeconds = 0
            limitUsedSeconds = 0
            prefs.edit().putString("lastDate", today).apply()
            saveScreenTime()
            println("KidGuard: New day detected, counters reset")
        }
        lastDateString = today
    }

    /**
     * Start screen time tracking
     */
    private fun startScreenTimeTracking() {
        if (screenTimeRunnable != null) return
        
        screenTimeRunnable = object : Runnable {
            override fun run() {
                try {
                    if (isChildModeActive && !isInRestrictedTime()) {
                        screenTimeSeconds++
                        limitUsedSeconds++
                        
                        // Save every 10 seconds
                        if (screenTimeSeconds % 10 == 0) {
                            saveScreenTime()
                        }
                        
                        // Check time limit
                        checkTimeLimit()
                    }
                    
                    // Check schedule restrictions
                    checkScheduleRestrictions()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(screenTimeRunnable!!)
        println("KidGuard: Screen time tracking started")
    }

    /**
     * Stop screen time tracking
     */
    private fun stopScreenTimeTracking() {
        screenTimeRunnable?.let { handler.removeCallbacks(it) }
        screenTimeRunnable = null
        saveScreenTime()
        println("KidGuard: Screen time tracking stopped")
    }

    /**
     * Save screen time to file (Flutter will sync to Firebase)
     */
    private fun saveScreenTime() {
        try {
            val file = File(applicationContext.filesDir, "screen_time_data.json")
            val json = JSONObject()
            json.put("screenTime", screenTimeSeconds)
            json.put("limitUsedTime", limitUsedSeconds)
            json.put("lastUpdate", System.currentTimeMillis())
            json.put("date", lastDateString)
            file.writeText(json.toString())
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        // Also save to prefs as backup
        prefs.edit()
            .putInt("screenTime", screenTimeSeconds)
            .putInt("limitUsedTime", limitUsedSeconds)
            .apply()
    }

    /**
     * Check if time limit is reached
     */
    private var hasShownOneMinuteWarning = false
    private var warningView: View? = null
    
    private fun checkTimeLimit() {
        if (dailyTimeLimit <= 0) return
        
        // Check if limit is disabled
        if (timeLimitDisabledUntil > System.currentTimeMillis()) return
        
        val remainingSeconds = dailyTimeLimit - limitUsedSeconds
        
        // 1-minute warning (show banner with sleeping bear)
        if (remainingSeconds in 1..60) {
            if (!hasShownOneMinuteWarning) {
                hasShownOneMinuteWarning = true
                showWarningBanner()
            }
            // Update countdown
            updateWarningCountdown(remainingSeconds)
        }
        
        // Reset warning flag when new day or limit extended
        if (remainingSeconds > 60) {
            hasShownOneMinuteWarning = false
            hideWarningBanner()
        }
        
        // Time limit reached - show full overlay
        if (limitUsedSeconds >= dailyTimeLimit && !isOverlayShowing) {
            hideWarningBanner()
            showOverlay("Time Limit Reached")
        }
    }
    
    private fun showWarningBanner() {
        try {
            if (warningView != null) return
            
            val wm = getSystemService(WINDOW_SERVICE) as? android.view.WindowManager ?: return
            val inflater = getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
            
            warningView = inflater.inflate(R.layout.warning_overlay_layout, null)
            
            val params = android.view.WindowManager.LayoutParams(
                android.view.WindowManager.LayoutParams.MATCH_PARENT,
                android.view.WindowManager.LayoutParams.WRAP_CONTENT,
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O)
                    android.view.WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    android.view.WindowManager.LayoutParams.TYPE_PHONE,
                android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                android.graphics.PixelFormat.TRANSLUCENT
            )
            params.gravity = android.view.Gravity.TOP
            
            wm.addView(warningView, params)
        } catch (e: Exception) {
            e.printStackTrace()
            // Fallback to toast
            Toast.makeText(this, "🐻💤 อีก 1 นาทีจะหมดเวลาแล้ว!", Toast.LENGTH_LONG).show()
        }
    }
    
    private fun updateWarningCountdown(seconds: Int) {
        try {
            val countdown = warningView?.findViewById<TextView>(R.id.warning_countdown)
            handler.post {
                countdown?.text = seconds.toString()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun hideWarningBanner() {
        try {
            if (warningView != null) {
                val wm = getSystemService(WINDOW_SERVICE) as? android.view.WindowManager
                wm?.removeView(warningView)
                warningView = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Check schedule restrictions (sleep time, quiet time)
     */
    private fun checkScheduleRestrictions() {
        try {
            if (!isChildModeActive) return
            
            val reason = getRestrictionReason()
            if (reason.isNotEmpty() && !isOverlayShowing) {
                // Determine restriction type for tracking
                currentRestrictionType = when {
                    isInSleepTime() -> RestrictionType.SLEEP
                    isInQuietTime() -> RestrictionType.QUIET
                    dailyTimeLimit > 0 && limitUsedSeconds >= dailyTimeLimit -> RestrictionType.TIME_LIMIT
                    else -> RestrictionType.NONE
                }
                showOverlay(reason)
            } else if (reason.isEmpty() && isOverlayShowing && 
                       currentRestrictionType in listOf(RestrictionType.SLEEP, RestrictionType.QUIET, RestrictionType.TIME_LIMIT)) {
                // Schedule/time limit ended - hide overlay and re-evaluate
                hideOverlay()
                currentRestrictionType = RestrictionType.NONE
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Start screen timeout monitoring
     * Checks inactivity every 30 seconds and locks if idle for too long
     */
    private fun startScreenTimeoutCheck() {
        screenTimeoutRunnable = object : Runnable {
            override fun run() {
                if (isChildModeActive && screenTimeoutMinutes > 0) {
                    val nowMillis = System.currentTimeMillis()
                    val idleTimeMillis = nowMillis - lastActivityTime
                    val timeoutMillis = screenTimeoutMinutes * 60 * 1000L
                    
                    // If idle for longer than timeout, show lock
                    if (idleTimeMillis >= timeoutMillis && !isOverlayShowing) {
                        currentRestrictionType = RestrictionType.SCREEN_TIMEOUT
                        showOverlay("แอปหลับเพราะไม่ได้เล่น 💤")
                    }
                }
                // Check every 30 seconds
                handler.postDelayed(this, 30000)
            }
        }
        handler.post(screenTimeoutRunnable!!)
    }
    
    /**
     * Stop screen timeout monitoring
     */
    private fun stopScreenTimeoutCheck() {
        screenTimeoutRunnable?.let { handler.removeCallbacks(it) }
        screenTimeoutRunnable = null
    }
    
    /**
     * Reset activity timer when user interacts with device
     */
    private fun resetActivityTimer() {
        lastActivityTime = System.currentTimeMillis()
        
        // If screen timeout overlay was showing, hide it
        if (isOverlayShowing && currentRestrictionType == RestrictionType.SCREEN_TIMEOUT) {
            hideOverlay()
            currentRestrictionType = RestrictionType.NONE
        }
    }

    /**
     * Check if currently in restricted time
     */
    private fun isInRestrictedTime(): Boolean {
        return isInSleepTime() || isInQuietTime()
    }

    /**
     * Check if in sleep time
     */
    private fun isInSleepTime(): Boolean {
        if (!sleepScheduleEnabled) return false
        
        val now = Calendar.getInstance()
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val bedtimeMinutes = bedtimeHour * 60 + bedtimeMinute
        val wakeMinutes = wakeHour * 60 + wakeMinute
        
        return if (bedtimeMinutes > wakeMinutes) {
            // Overnight (e.g., 20:00 - 07:00)
            currentMinutes >= bedtimeMinutes || currentMinutes < wakeMinutes
        } else {
            // Same day
            currentMinutes >= bedtimeMinutes && currentMinutes < wakeMinutes
        }
    }

    /**
     * Check if in quiet time
     */
    private fun isInQuietTime(): Boolean {
        if (quietTimes.isEmpty()) return false
        
        val now = Calendar.getInstance()
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        
        for (period in quietTimes) {
            if (!period.enabled) continue
            
            val startMinutes = period.startHour * 60 + period.startMinute
            val endMinutes = period.endHour * 60 + period.endMinute
            
            val inPeriod = if (startMinutes <= endMinutes) {
                currentMinutes >= startMinutes && currentMinutes < endMinutes
            } else {
                currentMinutes >= startMinutes || currentMinutes < endMinutes
            }
            
            if (inPeriod) return true
        }
        return false
    }

    /**
     * Get restriction reason for overlay message
     */
    private fun getRestrictionReason(): String {
        if (isInSleepTime()) return "เวลานอน 🌙"
        if (isInQuietTime()) return "เวลาพักผ่อน 🔕"
        if (dailyTimeLimit > 0 && limitUsedSeconds >= dailyTimeLimit) {
            if (timeLimitDisabledUntil <= System.currentTimeMillis()) {
                return "หมดเวลาใช้งาน ⏰"
            }
        }
        return ""
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isChildModeActive) return
        
        // Reset activity timer on any accessibility event (user interaction)
        resetActivityTimer()
        
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            // Skip our own app and system UI
            if (packageName == applicationContext.packageName) return
            if (packageName.contains("launcher") || packageName.contains("systemui")) return
            
            // Check schedule restrictions first (highest priority)
            val restrictionReason = getRestrictionReason()
            if (restrictionReason.isNotEmpty()) {
                // Determine restriction type for tracking
                currentRestrictionType = when {
                    isInSleepTime() -> RestrictionType.SLEEP
                    isInQuietTime() -> RestrictionType.QUIET
                    else -> RestrictionType.TIME_LIMIT
                }
                if (!isOverlayShowing) {
                    showOverlay(restrictionReason)
                }
                return
            }
            
            // Check blocked apps - ส่งกลับ Home ทันทีไม่แสดง overlay
            if (isAppBlocked(packageName)) {
                currentRestrictionType = RestrictionType.BLOCKED_APP
                lastBlockedPackage = packageName
                // เด้งกลับ Home screen ทันที
                performGlobalAction(GLOBAL_ACTION_HOME)
            } else {
                // App is allowed - clear blocked state
                if (currentRestrictionType == RestrictionType.BLOCKED_APP) {
                    lastBlockedPackage = null
                    currentRestrictionType = RestrictionType.NONE
                }
            }
        }
    }

    private fun isAppBlocked(packageName: String): Boolean {
        return blockedPackageSet.contains(packageName)
    }

    /**
     * Show overlay via OverlayService
     */
    private fun showOverlay(reason: String) {
        try {
            val intent = Intent(this, OverlayService::class.java)
            intent.putExtra("packageName", reason)
            // Use startService - OverlayService will call startForeground itself
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            isOverlayShowing = true
            lastBlockedPackage = reason
            
            // Update Firestore so parent sees unlock FAB
            setLockedInFirestore(true, currentRestrictionType.name.lowercase())
            
            // Start auto-exit timer for blocked apps (10 seconds)
            startAutoExitTimer()
        } catch (e: Exception) {
            e.printStackTrace()
            // Fallback: just go home and show toast
            try {
                performGlobalAction(GLOBAL_ACTION_HOME)
                android.widget.Toast.makeText(this, reason, android.widget.Toast.LENGTH_LONG).show()
            } catch (e2: Exception) {
                e2.printStackTrace()
            }
        }
    }
    
    /**
     * Start 10-second countdown then automatically go home
     */
    private fun startAutoExitTimer() {
        // Cancel any existing timer
        cancelAutoExitTimer()
        
        autoExitRunnable = Runnable {
            if (isOverlayShowing) {
                try {
                    // Go to home screen after 10 seconds
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    println("KidGuard: Auto-exit triggered after ${autoExitDelayMs/1000}s")
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
        handler.postDelayed(autoExitRunnable!!, autoExitDelayMs)
    }
    
    /**
     * Cancel auto-exit timer
     */
    private fun cancelAutoExitTimer() {
        autoExitRunnable?.let { handler.removeCallbacks(it) }
        autoExitRunnable = null
    }

    /**
     * Hide overlay
     */
    private fun hideOverlay() {
        try {
            cancelAutoExitTimer() // Cancel auto-exit when overlay is hidden
            val intent = Intent(this, OverlayService::class.java)
            stopService(intent)
            isOverlayShowing = false
            
            // Clear lock in Firestore for temporary blocks (blocked app, screen timeout)
            if (currentRestrictionType == RestrictionType.BLOCKED_APP || 
                currentRestrictionType == RestrictionType.SCREEN_TIMEOUT) {
                setLockedInFirestore(false, "")
            }
            // Note: currentRestrictionType is reset by the caller based on context
        } catch (e: Exception) {
            e.printStackTrace()
            isOverlayShowing = false
        }
    }

    /**
     * Update isLocked status in Firestore so parent can see unlock FAB
     * This makes the unlock button appear on parent's device for ALL blocking events
     */
    private fun setLockedInFirestore(isLocked: Boolean, reason: String) {
        if (parentId.isEmpty() || childId.isEmpty()) return
        
        try {
            val updates = mutableMapOf<String, Any?>(
                "isLocked" to isLocked,
                "lockReason" to reason
            )
            
            if (isLocked) {
                updates["lockedAt"] = com.google.firebase.firestore.FieldValue.serverTimestamp()
            }
            
            firestore.collection("users")
                .document(parentId)
                .collection("children")
                .document(childId)
                .update(updates as Map<String, Any>)
                .addOnSuccessListener {
                    println("KidGuard: Firestore isLocked=$isLocked, reason=$reason")
                }
                .addOnFailureListener { e ->
                    println("KidGuard: Failed to update lock status: ${e.message}")
                }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onInterrupt() {
        fileObserver?.stopWatching()
        stopScreenTimeTracking()
        stopScreenTimeoutCheck()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        fileObserver?.stopWatching()
        stopScreenTimeTracking()
        stopScreenTimeoutCheck()
    }

    /**
     * Data class for quiet time period
     */
    data class QuietTimePeriod(
        val name: String,
        val startHour: Int,
        val startMinute: Int,
        val endHour: Int,
        val endMinute: Int,
        val enabled: Boolean
    )
}
