package com.seniorproject.kid_guard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class ChildModeService : Service() {

    private val CHANNEL_ID = "ChildModeServiceChannel"
    private val NOTIFICATION_ID = 2001
    
    private var handler: Handler? = null
    private var updateRunnable: Runnable? = null
    
    // Firebase sync helper for background operation
    private var firebaseSyncHelper: FirebaseSyncHelper? = null
    
    companion object {
        const val ACTION_STOP_SERVICE = "com.kidguard.ACTION_STOP_CHILD_MODE"
        const val EXTRA_CHILD_NAME = "childName"
        const val EXTRA_SCREEN_TIME = "screenTime"
        const val EXTRA_DAILY_LIMIT = "dailyLimit"
        const val PREF_ALLOW_SHUTDOWN = "allowShutdown"
        
        private var isRunning = false
        
        fun isServiceRunning(): Boolean = isRunning
        
        /**
         * ตั้งค่า flag อนุญาตให้ปิดแอพได้ (เรียกหลังจากกรอก PIN ผู้ปกครองถูกต้อง)
         * - true = อนุญาตให้ปิด (ปัดทิ้งแล้วไม่เปิดกลับ)
         * - false = ไม่อนุญาต (ปัดทิ้งแล้วเปิดกลับอัตโนมัติ)
         */
        fun setAllowShutdown(context: Context, allow: Boolean) {
            context.getSharedPreferences("ChildModePrefs", Context.MODE_PRIVATE)
                .edit().putBoolean(PREF_ALLOW_SHUTDOWN, allow).apply()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        handler = Handler(Looper.getMainLooper())
        isRunning = true
        
        // Initialize Firebase sync helper
        firebaseSyncHelper = FirebaseSyncHelper(this).apply {
            initialize()
            onUnlockRequested = {
                // Hide overlay when parent unlocks
                val overlayIntent = Intent(this@ChildModeService, OverlayService::class.java)
                stopService(overlayIntent)
                println("ChildModeService: Parent unlock received, hiding overlay")
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val childName = intent?.getStringExtra(EXTRA_CHILD_NAME) ?: "ลูก"
        val screenTime = intent?.getIntExtra(EXTRA_SCREEN_TIME, 0) ?: 0
        val dailyLimit = intent?.getIntExtra(EXTRA_DAILY_LIMIT, 0) ?: 0
        
        startForeground(NOTIFICATION_ID, createNotification(childName, screenTime, dailyLimit))
        
        // Schedule periodic updates for notification
        scheduleUpdates()
        
        // Start real-time Firestore listeners (instant updates, replaces old 60s polling)
        firebaseSyncHelper?.startRealtimeListeners()
        
        return START_STICKY
    }
    
    private fun scheduleUpdates() {
        updateRunnable?.let { handler?.removeCallbacks(it) }
        
        updateRunnable = object : Runnable {
            override fun run() {
                // Read updated values from SharedPreferences
                val prefs = getSharedPreferences("ChildModePrefs", Context.MODE_PRIVATE)
                val childName = prefs.getString("childName", "ลูก") ?: "ลูก"
                val screenTime = prefs.getInt("screenTime", 0)
                val dailyLimit = prefs.getInt("dailyLimit", 0)
                
                updateNotification(childName, screenTime, dailyLimit)
                
                // Update every 30 seconds
                handler?.postDelayed(this, 30000)
            }
        }
        handler?.postDelayed(updateRunnable!!, 30000)
    }
    
    
    private fun updateNotification(childName: String, screenTime: Int, dailyLimit: Int) {
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, createNotification(childName, screenTime, dailyLimit))
    }

    private fun createNotification(childName: String, screenTime: Int, dailyLimit: Int): Notification {
        // Format screen time
        val hours = screenTime / 3600
        val minutes = (screenTime % 3600) / 60
        val screenTimeText = if (hours > 0) "${hours}ชม. ${minutes}น." else "${minutes}น."
        
        // Calculate remaining time
        val remainingText = if (dailyLimit > 0) {
            val remaining = (dailyLimit - screenTime).coerceAtLeast(0)
            val remHours = remaining / 3600
            val remMinutes = (remaining % 3600) / 60
            if (remHours > 0) "เหลือ ${remHours}ชม. ${remMinutes}น." else "เหลือ ${remMinutes}น."
        } else {
            "ไม่จำกัดเวลา"
        }
        
        // Content text with screen time and limit
        val contentText = "ใช้ไป $screenTimeText • $remainingText"
        
        // Intent to open app when notification is clicked
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Action intent to stop service (opens app with special action)
        val stopIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", ACTION_STOP_SERVICE)
        }
        val stopPendingIntent = PendingIntent.getActivity(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🛡️ Kid Guard กำลังปกป้อง $childName")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true) // Cannot be swiped away
            .setContentIntent(openPendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "หยุดบริการ",
                stopPendingIntent
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setShowWhen(false)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Kid Guard Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "แสดงสถานะการปกป้องเด็ก"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        
        // Stop realtime listeners and set offline status
        firebaseSyncHelper?.stopListeners()
        firebaseSyncHelper?.setOfflineStatus()
        
        // Cancel all runnables
        updateRunnable?.let { handler?.removeCallbacks(it) }
        handler = null
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        
        val prefs = getSharedPreferences("ChildModePrefs", Context.MODE_PRIVATE)
        val allowShutdown = prefs.getBoolean(PREF_ALLOW_SHUTDOWN, false)
        
        // ถ้าผู้ปกครองกรอก PIN แล้ว → ปล่อยให้ปิดจริง ไม่ต้อง restart
        if (allowShutdown) {
            prefs.edit().putBoolean(PREF_ALLOW_SHUTDOWN, false).apply()
            println("ChildModeService: PIN-authorized shutdown, not restarting")
            return
        }
        
        // ตรวจสอบว่าโหมดเด็กยังเปิดอยู่หรือไม่
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isChildModeActive = prefs.getBoolean("isChildModeActive", false) ||
            flutterPrefs.getBoolean("flutter.isChildModeActive", false)
        
        if (!isChildModeActive) {
            println("ChildModeService: Child mode not active, not restarting")
            return
        }
        
        // เปิดแอพกลับมาอัตโนมัติเมื่อเด็กปัดทิ้ง
        try {
            val relaunchIntent = Intent(applicationContext, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            applicationContext.startActivity(relaunchIntent)
            println("ChildModeService: App relaunched after swipe-away")
        } catch (e: Exception) {
            println("ChildModeService: Failed to relaunch app: ${e.message}")
        }
        
        // Restart service
        val restartIntent = Intent(applicationContext, ChildModeService::class.java)
        restartIntent.putExtra(EXTRA_CHILD_NAME, prefs.getString("childName", "ลูก"))
        restartIntent.putExtra(EXTRA_SCREEN_TIME, prefs.getInt("screenTime", 0))
        restartIntent.putExtra(EXTRA_DAILY_LIMIT, prefs.getInt("dailyLimit", 0))
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(restartIntent)
        } else {
            startService(restartIntent)
        }
    }
}

