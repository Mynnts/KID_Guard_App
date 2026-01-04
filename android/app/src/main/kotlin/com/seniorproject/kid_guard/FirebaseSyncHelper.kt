package com.seniorproject.kid_guard

import android.content.Context
import android.content.SharedPreferences
import com.google.firebase.firestore.FirebaseFirestore
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Helper class to sync Firebase data in background for ChildModeService
 * This allows the child device to receive updates without Flutter app running
 */
class FirebaseSyncHelper(private val context: Context) {
    
    private val firestore = FirebaseFirestore.getInstance()
    private val prefs: SharedPreferences = context.getSharedPreferences("KidGuardPrefs", Context.MODE_PRIVATE)
    
    private var parentId: String = ""
    private var childId: String = ""
    
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
     * Sync all data from Firestore
     */
    fun syncFromFirestore() {
        if (parentId.isEmpty() || childId.isEmpty()) {
            println("FirebaseSyncHelper: No IDs, skipping sync")
            return
        }
        
        syncBlockedApps()
        syncChildSettings()
        updateOnlineStatus()
    }
    
    /**
     * Sync blocked apps from all devices
     */
    private fun syncBlockedApps() {
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
                println("FirebaseSyncHelper: Failed to sync blocked apps: ${e.message}")
            }
    }
    
    private fun saveBlocklistToFile(blockedApps: List<String>) {
        try {
            val file = File(context.filesDir, "blocked_apps.json")
            val jsonArray = JSONArray(blockedApps)
            file.writeText(jsonArray.toString())
            println("FirebaseSyncHelper: Saved ${blockedApps.size} blocked apps to file")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Sync child settings (time limit, schedules, unlock request)
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
                    // Parent has unlocked - notify and clear flag
                    onUnlockRequested?.invoke()
                    clearUnlockRequest()
                }
                
                // Save settings to file for AccessibilityService
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
            println("FirebaseSyncHelper: Settings saved to file")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Update online status in Firestore
     */
    private fun updateOnlineStatus() {
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
