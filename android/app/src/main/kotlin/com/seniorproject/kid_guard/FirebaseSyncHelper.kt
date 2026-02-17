package com.seniorproject.kid_guard

import android.content.Context
import android.content.SharedPreferences
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Helper class to sync Firebase data in background for ChildModeService
 * Uses Firestore real-time snapshot listeners for instant updates
 * This allows the child device to receive updates without Flutter app running
 */
class FirebaseSyncHelper(private val context: Context) {
    
    private val firestore = FirebaseFirestore.getInstance()
    private val prefs: SharedPreferences = context.getSharedPreferences("KidGuardPrefs", Context.MODE_PRIVATE)
    
    private var parentId: String = ""
    private var childId: String = ""
    
    // Realtime listener registrations
    private var settingsListener: ListenerRegistration? = null
    private var blockedAppsListeners: MutableList<ListenerRegistration> = mutableListOf()
    private var devicesListener: ListenerRegistration? = null
    
    // Callback for unlock request
    var onUnlockRequested: (() -> Unit)? = null
    
    /**
     * Initialize with saved IDs from SharedPreferences
     */
    fun initialize() {
        parentId = prefs.getString("parentId", "") ?: ""
        childId = prefs.getString("childId", "") ?: ""
        
        // Also try from native settings file
        if (parentId.isEmpty() || childId.isEmpty()) {
            loadIdsFromSettingsFile()
        }
        
        println("FirebaseSyncHelper: Initialized with parentId=$parentId, childId=$childId")
    }
    
    private fun loadIdsFromSettingsFile() {
        try {
            val file = File(context.filesDir, "kid_guard_settings.json")
            if (file.exists()) {
                val json = JSONObject(file.readText())
                if (parentId.isEmpty()) parentId = json.optString("parentId", "")
                if (childId.isEmpty()) childId = json.optString("childId", "")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Start real-time Firestore listeners for instant updates
     * Replaces the old polling-based syncFromFirestore()
     */
    fun startRealtimeListeners() {
        if (parentId.isEmpty() || childId.isEmpty()) {
            println("FirebaseSyncHelper: No IDs, skipping realtime listeners")
            return
        }
        
        // Stop any existing listeners first
        stopListeners()
        
        // Start real-time listeners
        listenToBlockedApps()
        listenToChildSettings()
        updateOnlineStatus()
        
        println("FirebaseSyncHelper: Realtime listeners started")
    }
    
    /**
     * Listen to blocked apps across all devices in real-time
     * When parent blocks/unblocks an app, the change is reflected instantly
     */
    private fun listenToBlockedApps() {
        val devicesRef = firestore.collection("users")
            .document(parentId)
            .collection("children")
            .document(childId)
            .collection("devices")
        
        // Listen for device changes first, then listen to each device's apps
        devicesListener = devicesRef.addSnapshotListener { devicesSnapshot, error ->
            if (error != null) {
                println("FirebaseSyncHelper: Error listening to devices: ${error.message}")
                return@addSnapshotListener
            }
            
            if (devicesSnapshot == null) return@addSnapshotListener
            
            // Clear old per-device app listeners
            blockedAppsListeners.forEach { it.remove() }
            blockedAppsListeners.clear()
            
            val allBlockedPackages = mutableSetOf<String>()
            val deviceCount = devicesSnapshot.documents.size
            var devicesProcessed = 0
            
            if (deviceCount == 0) {
                saveBlocklistToFile(emptyList())
                return@addSnapshotListener
            }
            
            // Listen to each device's apps collection for real-time blocked app updates
            for (deviceDoc in devicesSnapshot.documents) {
                val listener = deviceDoc.reference.collection("apps")
                    .whereEqualTo("isLocked", true)
                    .addSnapshotListener { appsSnapshot, appsError ->
                        if (appsError != null) {
                            println("FirebaseSyncHelper: Error listening to apps: ${appsError.message}")
                            return@addSnapshotListener
                        }
                        
                        // Rebuild complete blocked list from all devices
                        // We need to re-query all devices to get complete picture
                        rebuildBlockedApps()
                    }
                blockedAppsListeners.add(listener)
            }
        }
    }
    
    /**
     * Rebuild blocked apps list from all devices
     * Called whenever any device's app status changes
     */
    private fun rebuildBlockedApps() {
        firestore.collection("users")
            .document(parentId)
            .collection("children")
            .document(childId)
            .collection("devices")
            .get()
            .addOnSuccessListener { devicesSnapshot ->
                val blockedPackages = mutableSetOf<String>()
                var pendingDevices = devicesSnapshot.documents.size
                
                if (pendingDevices == 0) {
                    saveBlocklistToFile(blockedPackages.toList())
                    return@addOnSuccessListener
                }
                
                for (deviceDoc in devicesSnapshot.documents) {
                    deviceDoc.reference.collection("apps")
                        .whereEqualTo("isLocked", true)
                        .get()
                        .addOnSuccessListener { appsSnapshot ->
                            for (appDoc in appsSnapshot.documents) {
                                val packageName = appDoc.getString("packageName")
                                if (packageName != null) {
                                    blockedPackages.add(packageName)
                                }
                            }
                            pendingDevices--
                            if (pendingDevices == 0) {
                                saveBlocklistToFile(blockedPackages.toList())
                            }
                        }
                        .addOnFailureListener {
                            pendingDevices--
                            if (pendingDevices == 0) {
                                saveBlocklistToFile(blockedPackages.toList())
                            }
                        }
                }
            }
            .addOnFailureListener { e ->
                println("FirebaseSyncHelper: Failed to rebuild blocked apps: ${e.message}")
            }
    }
    
    /**
     * Listen to child settings document in real-time
     * Detects unlock requests, time limit changes, schedule changes instantly
     */
    private fun listenToChildSettings() {
        settingsListener = firestore.collection("users")
            .document(parentId)
            .collection("children")
            .document(childId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    println("FirebaseSyncHelper: Error listening to settings: ${error.message}")
                    return@addSnapshotListener
                }
                
                if (snapshot == null || !snapshot.exists()) return@addSnapshotListener
                
                val data = snapshot.data ?: return@addSnapshotListener
                
                // Handle unlock request (instant response)
                val unlockRequested = data["unlockRequested"] as? Boolean ?: false
                val isLocked = data["isLocked"] as? Boolean ?: false
                
                if (unlockRequested && !isLocked) {
                    // Parent has unlocked - notify and clear flag
                    onUnlockRequested?.invoke()
                    clearUnlockRequest()
                    println("FirebaseSyncHelper: Parent unlock detected in realtime!")
                }
                
                // Save settings to file for AccessibilityService
                saveSettingsToFile(data)
                
                println("FirebaseSyncHelper: Settings updated in realtime")
            }
    }
    
    /**
     * Stop all real-time listeners
     */
    fun stopListeners() {
        settingsListener?.remove()
        settingsListener = null
        
        devicesListener?.remove()
        devicesListener = null
        
        blockedAppsListeners.forEach { it.remove() }
        blockedAppsListeners.clear()
        
        println("FirebaseSyncHelper: All listeners stopped")
    }
    
    /**
     * Legacy method - still useful for manual sync / fallback
     */
    fun syncFromFirestore() {
        if (parentId.isEmpty() || childId.isEmpty()) {
            println("FirebaseSyncHelper: No IDs, skipping sync")
            return
        }
        
        rebuildBlockedApps()
        syncChildSettings()
        updateOnlineStatus()
    }
    
    /**
     * One-time sync of child settings (fallback)
     */
    private fun syncChildSettings() {
        firestore.collection("users")
            .document(parentId)
            .collection("children")
            .document(childId)
            .get()
            .addOnSuccessListener { snapshot ->
                if (!snapshot.exists()) return@addOnSuccessListener
                
                val data = snapshot.data ?: return@addOnSuccessListener
                
                // Handle unlock request
                val unlockRequested = data["unlockRequested"] as? Boolean ?: false
                val isLocked = data["isLocked"] as? Boolean ?: false
                
                if (unlockRequested && !isLocked) {
                    onUnlockRequested?.invoke()
                    clearUnlockRequest()
                }
                
                saveSettingsToFile(data)
            }
            .addOnFailureListener { e ->
                println("FirebaseSyncHelper: Failed to sync settings: ${e.message}")
            }
    }
    
    private fun clearUnlockRequest() {
        firestore.collection("users")
            .document(parentId)
            .collection("children")
            .document(childId)
            .update("unlockRequested", false)
    }
    
    private fun saveBlocklistToFile(blockedApps: List<String>) {
        try {
            val file = File(context.filesDir, "blocked_apps.json")
            val jsonArray = JSONArray(blockedApps)
            file.writeText(jsonArray.toString())
            println("FirebaseSyncHelper: Saved ${blockedApps.size} blocked apps to file (realtime)")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun saveSettingsToFile(data: Map<String, Any>) {
        try {
            val file = File(context.filesDir, "kid_guard_settings.json")
            val json = JSONObject()
            
            json.put("parentId", parentId)
            json.put("childId", childId)
            json.put("isChildModeActive", data["isChildModeActive"] ?: false)
            json.put("dailyTimeLimit", data["dailyTimeLimit"] ?: 0)
            json.put("screenTime", data["screenTime"] ?: 0)
            json.put("limitUsedTime", data["limitUsedTime"] ?: 0)
            json.put("isLocked", data["isLocked"] ?: false)
            
            // Time limit disabled until
            val timeLimitDisabledUntil = data["timeLimitDisabledUntil"]
            if (timeLimitDisabledUntil is com.google.firebase.Timestamp) {
                json.put("timeLimitDisabledUntil", timeLimitDisabledUntil.toDate().time)
            }
            
            // Sleep schedule
            val sleepSchedule = data["sleepSchedule"] as? Map<*, *>
            if (sleepSchedule != null) {
                json.put("sleepScheduleEnabled", sleepSchedule["enabled"] ?: false)
                json.put("bedtimeHour", sleepSchedule["bedtimeHour"] ?: 20)
                json.put("bedtimeMinute", sleepSchedule["bedtimeMinute"] ?: 0)
                json.put("wakeHour", sleepSchedule["wakeHour"] ?: 7)
                json.put("wakeMinute", sleepSchedule["wakeMinute"] ?: 0)
            }
            
            // Quiet times
            val quietTimes = data["quietTimes"] as? List<*>
            if (quietTimes != null) {
                json.put("quietTimes", JSONArray(quietTimes))
            }
            
            json.put("lastUpdate", System.currentTimeMillis())
            
            file.writeText(json.toString())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Update online status in Firestore
     */
    fun updateOnlineStatus() {
        if (parentId.isEmpty() || childId.isEmpty()) return
        
        firestore.collection("users")
            .document(parentId)
            .collection("children")
            .document(childId)
            .update(mapOf(
                "isOnline" to true,
                "lastActive" to com.google.firebase.firestore.FieldValue.serverTimestamp()
            ))
            .addOnSuccessListener {
                println("FirebaseSyncHelper: Online status updated")
            }
            .addOnFailureListener { e ->
                println("FirebaseSyncHelper: Failed to update online status: ${e.message}")
            }
    }
    
    /**
     * Set locked status in Firestore so parent can see unlock FAB
     * Called by AppAccessibilityService when overlay is shown/hidden
     */
    fun setLockedStatus(isLocked: Boolean, reason: String) {
        if (parentId.isEmpty() || childId.isEmpty()) return
        
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
                println("FirebaseSyncHelper: isLocked=$isLocked, reason=$reason - updated in Firestore")
            }
            .addOnFailureListener { e ->
                println("FirebaseSyncHelper: Failed to update lock status: ${e.message}")
            }
    }
    
    /**
     * Set offline status when service stops
     */
    fun setOfflineStatus() {
        if (parentId.isEmpty() || childId.isEmpty()) return
        
        firestore.collection("users")
            .document(parentId)
            .collection("children")
            .document(childId)
            .update(mapOf(
                "isOnline" to false,
                "lastActive" to com.google.firebase.firestore.FieldValue.serverTimestamp()
            ))
    }
}
