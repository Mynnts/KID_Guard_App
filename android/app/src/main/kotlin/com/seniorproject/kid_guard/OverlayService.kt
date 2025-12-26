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
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
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

        val button = overlayView?.findViewById<Button>(R.id.overlay_button)
        button?.setOnClickListener {
            val startMain = Intent(Intent.ACTION_MAIN)
            startMain.addCategory(Intent.CATEGORY_HOME)
            startMain.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(startMain)
        }
        
        if (packageName == "Time Limit Reached" || packageName.contains("หมดเวลา") || packageName.contains("⏰")) {
             button?.setOnClickListener {
                  val appIntent = Intent(this, MainActivity::class.java)
                  appIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                  appIntent.putExtra("action", "unlock_time_limit")
                  startActivity(appIntent)
                  overlayView?.visibility = View.GONE
             }
        }

        try {
            windowManager?.addView(overlayView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun updateOverlayContent(packageName: String) {
        val title = overlayView?.findViewById<TextView>(R.id.overlay_title)
        val message = overlayView?.findViewById<TextView>(R.id.overlay_message)
        val button = overlayView?.findViewById<Button>(R.id.overlay_button)

        // Friendly child-friendly messages based on reason
        when {
            packageName == "Time Limit Reached" || packageName.contains("หมดเวลา") || packageName.contains("⏰") -> {
                title?.text = "เก่งมากวันนี้! ⭐"
                message?.text = "ได้เวลาพักผ่อนแล้วนะ"
                button?.text = "ขอเวลาเพิ่ม 💝"
                button?.setOnClickListener {
                    val appIntent = Intent(this, MainActivity::class.java)
                    appIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    appIntent.putExtra("action", "unlock_time_limit")
                    startActivity(appIntent)
                    overlayView?.visibility = View.GONE
                }
            }
            packageName.contains("นอน") || packageName.contains("🌙") -> {
                title?.text = "ถึงเวลานอนแล้วจ้า 🌙"
                message?.text = "ราตรีสวัสดิ์ พรุ่งนี้เจอกันนะ"
                button?.text = "นอนหลับฝันดี 💤"
                button?.setOnClickListener {
                    val startMain = Intent(Intent.ACTION_MAIN)
                    startMain.addCategory(Intent.CATEGORY_HOME)
                    startMain.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(startMain)
                }
            }
            packageName.contains("พัก") || packageName.contains("🔕") -> {
                title?.text = "ช่วงเวลาพักผ่อน 🌸"
                message?.text = "ไปทำกิจกรรมอื่นกันเถอะ"
                button?.text = "โอเค 👍"
                button?.setOnClickListener {
                    val startMain = Intent(Intent.ACTION_MAIN)
                    startMain.addCategory(Intent.CATEGORY_HOME)
                    startMain.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(startMain)
                }
            }
            else -> {
                // Blocked app - still friendly
                title?.text = "แอปนี้ยังไม่พร้อมใช้ 🎮"
                message?.text = "ลองเล่นอย่างอื่นกันนะ"
                button?.text = "โอเค 👍"
                button?.setOnClickListener {
                    val startMain = Intent(Intent.ACTION_MAIN)
                    startMain.addCategory(Intent.CATEGORY_HOME)
                    startMain.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(startMain)
                }
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
