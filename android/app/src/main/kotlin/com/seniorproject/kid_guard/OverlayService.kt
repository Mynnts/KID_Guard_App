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
        overlayView = inflater.inflate(R.layout.overlay_layout, null)

        updateOverlayContent(packageName)

        val button = overlayView?.findViewById<Button>(R.id.overlay_button)
        button?.setOnClickListener {
            val startMain = Intent(Intent.ACTION_MAIN)
            startMain.addCategory(Intent.CATEGORY_HOME)
            startMain.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(startMain)
        }
        
        // Add Unlock Button logic if needed (e.g. long press or specific button)
        // For now, let's keep it simple. If we want to unlock, we might need a separate button.
        // Let's assume the user wants to unlock via the app.
        // But since the overlay blocks everything, they can't open the app easily.
        // We should add an "Unlock" button to the overlay for Time Limit.
        
        if (packageName == "Time Limit Reached") {
             // Change button text or add another button
             button?.text = "Unlock with PIN"
             button?.setOnClickListener {
                 // Show PIN Dialog (Native) or Open App with specific intent
                 // Opening app is easier to handle PIN logic in Flutter
                 val intent = packageManager.getLaunchIntentForPackage(packageName)
                 if (intent != null) {
                     intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                     startActivity(intent)
                 } else {
                     // Fallback if we can't find our own package?
                     // We are in the same package, so:
                     val appIntent = Intent(this, MainActivity::class.java)
                     appIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                     appIntent.putExtra("action", "unlock_time_limit")
                     startActivity(appIntent)
                 }
                 // We don't hide overlay yet, Flutter will tell us to hide if PIN is correct
             }
        }

        windowManager?.addView(overlayView, params)
    }

    private fun updateOverlayContent(packageName: String) {
        val title = overlayView?.findViewById<TextView>(R.id.overlay_title)
        val message = overlayView?.findViewById<TextView>(R.id.overlay_message)
        val button = overlayView?.findViewById<Button>(R.id.overlay_button)

        if (packageName == "Time Limit Reached") {
            title?.text = "หมดเวลาใช้งาน"
            message?.text = "คุณใช้เวลาหน้าจอครบตามที่กำหนดแล้ว"
            button?.text = "ปลดล็อคด้วย PIN"
            button?.setOnClickListener {
                 val appIntent = Intent(this, MainActivity::class.java)
                 appIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                 appIntent.putExtra("action", "unlock_time_limit")
                 startActivity(appIntent)
                 
                 // HIDE OVERLAY temporarily to allow PIN entry
                 // We can remove it or set visibility to GONE
                 // If we remove it, we need to be careful about recreating it if they cancel.
                 // Setting visibility to GONE is safer if we keep the service running.
                 overlayView?.visibility = View.GONE
            }
        } else {
            title?.text = "แอพนี้ถูกล็อค"
            message?.text = "ไม่สามารถเข้าถึงแอพนี้ได้ในขณะนี้"
            button?.text = "รับทราบ"
            button?.setOnClickListener {
                val startMain = Intent(Intent.ACTION_MAIN)
                startMain.addCategory(Intent.CATEGORY_HOME)
                startMain.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(startMain)
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
