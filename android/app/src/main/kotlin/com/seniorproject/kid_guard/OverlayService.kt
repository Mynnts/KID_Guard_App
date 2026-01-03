package com.seniorproject.kid_guard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.media.AudioManager
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat

class OverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var audioManager: AudioManager? = null

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        createNotificationChannel()
        startForeground(1, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val packageName = intent?.getStringExtra("packageName") ?: "Restricted App"
        showOverlay(packageName)
        return START_STICKY
    }

    private fun pauseAllMedia() {
        try {
            // Request audio focus to pause other apps like YouTube
            if (audioManager?.isMusicActive == true) {
                @Suppress("DEPRECATION")
                audioManager?.requestAudioFocus(
                    null,
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                )
            }
            // Also dispatch media button event to pause
            val keyEvent = android.view.KeyEvent(
                android.view.KeyEvent.ACTION_DOWN,
                android.view.KeyEvent.KEYCODE_MEDIA_PAUSE
            )
            audioManager?.dispatchMediaKeyEvent(keyEvent)
            val keyEventUp = android.view.KeyEvent(
                android.view.KeyEvent.ACTION_UP,
                android.view.KeyEvent.KEYCODE_MEDIA_PAUSE
            )
            audioManager?.dispatchMediaKeyEvent(keyEventUp)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showOverlay(packageName: String) {
        // Pause all media when showing overlay
        pauseAllMedia()
        
        if (overlayView != null) {
            updateOverlayContent(packageName)
            return
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            // Block ALL touches - kids cannot interact, only parents can unlock via Firebase
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.CENTER

        val inflater = getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
        
        // Try friendly layout first, fallback to old layout if crash
        try {
            overlayView = inflater.inflate(R.layout.friendly_overlay_layout, null)
        } catch (e: Exception) {
            e.printStackTrace()
            try {
                overlayView = inflater.inflate(R.layout.overlay_layout, null)
            } catch (e2: Exception) {
                e2.printStackTrace()
                return // Can't show overlay
            }
        }

        updateOverlayContent(packageName)
        
        // Update clock and date display
        updateClockDisplay()

        // Button is now hidden/invisible in the new layout
        // Children cannot dismiss the overlay - only parents can unlock via Firebase

        try {
            windowManager?.addView(overlayView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun updateClockDisplay() {
        try {
            val clockView = overlayView?.findViewById<TextView>(R.id.clock_display)
            val dateView = overlayView?.findViewById<TextView>(R.id.date_display)
            
            val now = java.util.Calendar.getInstance()
            val timeFormat = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
            val dateFormat = java.text.SimpleDateFormat("EEEE, MMMM d", java.util.Locale.ENGLISH)
            
            clockView?.text = timeFormat.format(now.time)
            dateView?.text = dateFormat.format(now.time)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun updateOverlayContent(packageName: String) {
        val title = overlayView?.findViewById<TextView>(R.id.overlay_title)
        val message = overlayView?.findViewById<TextView>(R.id.overlay_message)

        // Super child-friendly cute messages - NO buttons for kids to dismiss
        when {
            packageName == "Time Limit Reached" || packageName.contains("หมดเวลา") || packageName.contains("⏰") -> {
                title?.text = "เก่งมากวันนี้! ⭐"
                message?.text = "พักสายตาสักครู่นะ 💕"
            }
            packageName.contains("นอน") || packageName.contains("🌙") -> {
                title?.text = "ฝันดีนะตัวน้อย 🌙"
                message?.text = "พรุ่งนี้เจอกันใหม่นะ ✨"
            }
            packageName.contains("พัก") || packageName.contains("🔕") -> {
                title?.text = "พักผ่อนกันเถอะ 🌸"
                message?.text = "ไปทำกิจกรรมสนุกๆ กันนะ"
            }
            packageName.contains("ระงับ") || packageName.contains("🔒") -> {
                title?.text = "พักสักครู่นะ 🔒"
                message?.text = "รอพ่อแม่มาปลดล็อคนะ"
            }
            packageName.contains("หลับ") || packageName.contains("💤") || packageName.contains("ไม่ได้เล่น") -> {
                // Screen timeout - device inactive
                title?.text = "แอปหลับแล้วนะ 💤"
                message?.text = "กดหน้าจอเพื่อเล่นต่อได้นะ"
            }
            else -> {
                // Blocked app - friendly message
                title?.text = "ไปเล่นอย่างอื่นกันนะ 🎮"
                message?.text = "มีอย่างอื่นเยอะเลย 🌈"
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (overlayView != null) {
            windowManager?.removeView(overlayView)
            overlayView = null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                "OverlayServiceChannel",
                "Overlay Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "OverlayServiceChannel")
            .setContentTitle("Kid Guard Protection")
            .setContentText("Kid Guard is running in the background")
            .setSmallIcon(android.R.drawable.ic_secure)
            .build()
    }
}
