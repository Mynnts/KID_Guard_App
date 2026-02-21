package com.seniorproject.kid_guard

// ==================== นำเข้า Libraries ====================
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils.SimpleStringSplitter
import android.provider.Settings.Secure
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * ==================== MainActivity ====================
 * หน้าหลักของแอพ - เชื่อมต่อระหว่าง Flutter และ Native Android
 * 
 * MethodChannels ที่ใช้:
 * 1. com.kidguard/security - ตรวจสอบความปลอดภัย, จัดการ log
 * 2. com.kidguard/native - จัดการแอพ, blocklist, accessibility
 * 3. com.kidguard/childmode - ควบคุม foreground service
 * 4. com.example.kid_guard/overlay - แสดง/ซ่อน overlay บล็อกแอพ
 */
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.kidguard/native"
    private val SECURITY_CHANNEL = "com.kidguard/security"

    // ==================== Lifecycle Methods ====================
    
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // เริ่มต้นระบบ log
        SecurityLogger.init(this)
        SecurityLogger.info(this, "App started", mapOf("version" to getAppVersion()))
    }

    /** ดึงเวอร์ชันแอพ */
    private fun getAppVersion(): String {
        return try {
            val pInfo = packageManager.getPackageInfo(packageName, 0)
            pInfo.versionName ?: "unknown"
        } catch (e: Exception) {
            "unknown"
        }
    }

    // ==================== MethodChannel Configuration ====================
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // ==================== Security Channel ====================
        // ใช้สำหรับ: ตรวจสอบ root, emulator, จัดการ security logs
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // ตรวจสอบความปลอดภัยของเครื่อง (root, emulator, debugger, signature)
                "performSecurityCheck" -> {
                    val expectedSignature = call.argument<String>("expectedSignature")
                    val status = SecurityService.performSecurityCheck(this, expectedSignature)
                    result.success(status.toMap())
                }
                // ตรวจสอบ root แบบรวดเร็ว
                "quickRootCheck" -> {
                    result.success(SecurityService.quickRootCheck())
                }
                // ตรวจสอบ emulator แบบรวดเร็ว
                "quickEmulatorCheck" -> {
                    result.success(SecurityService.quickEmulatorCheck())
                }
                // ดึงรายการ log ทั้งหมด
                "getLogs" -> {
                    val logs = SecurityLogger.getLogsAsList(this)
                    result.success(logs)
                }
                // ล้าง log ทั้งหมด
                "clearLogs" -> {
                    SecurityLogger.clearLogs(this)
                    result.success(true)
                }
                // export log เป็นไฟล์ text
                "exportLogs" -> {
                    val file = SecurityLogger.exportLogs(this)
                    result.success(file?.absolutePath)
                }
                // บันทึก log จาก Flutter
                "logEvent" -> {
                    val level = call.argument<String>("level") ?: "INFO"
                    val message = call.argument<String>("message") ?: ""
                    val data = call.argument<Map<String, Any>>("data")
                    val logLevel = when (level.uppercase()) {
                        "DEBUG" -> SecurityLogger.LogLevel.DEBUG
                        "WARN" -> SecurityLogger.LogLevel.WARN
                        "ERROR" -> SecurityLogger.LogLevel.ERROR
                        "SECURITY" -> SecurityLogger.LogLevel.SECURITY
                        else -> SecurityLogger.LogLevel.INFO
                    }
                    SecurityLogger.log(this, logLevel, message, data)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // ==================== Native Channel ====================
        // ใช้สำหรับ: จัดการ accessibility, blocklist, ดึงรายการแอพ
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // ตรวจสอบว่า Accessibility Service เปิดอยู่หรือไม่
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilitySettingsOn(this))
                }
                // เปิดหน้าตั้งค่า Accessibility
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                // อัปเดตรายการแอพที่ถูกบล็อก
                "updateBlocklist" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps")
                    if (blockedApps != null) {
                        val prefs = getSharedPreferences("KidGuardPrefs", Context.MODE_PRIVATE)
                        prefs.edit().putStringSet("blocked_apps", blockedApps.toSet()).apply()
                        SecurityLogger.info(this, "Blocklist updated", mapOf("count" to blockedApps.size))
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Blocked apps list is null", null)
                    }
                }
                // ดึงรายการแอพทั้งหมดที่ติดตั้ง (launcher apps)
                "getLauncherApps" -> {
                    val pm = packageManager
                    val mainIntent = Intent(Intent.ACTION_MAIN, null)
                    mainIntent.addCategory(Intent.CATEGORY_LAUNCHER)
                    val apps = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                        pm.queryIntentActivities(mainIntent, android.content.pm.PackageManager.ResolveInfoFlags.of(0L))
                    } else {
                        pm.queryIntentActivities(mainIntent, 0)
                    }
                    
                    val appList = apps.map { resolveInfo ->
                        val activityInfo = resolveInfo.activityInfo
                        val packageName = activityInfo.packageName
                        val appInfo = pm.getApplicationInfo(packageName, 0)
                        val isSystem = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                        mapOf(
                            "packageName" to packageName,
                            "isSystem" to isSystem
                        )
                    }
                    result.success(appList)
                }
                // ดึง action ที่เปิดแอพมา (เช่น unlock_time_limit)
                "getLaunchIntentAction" -> {
                    val action = intent.getStringExtra("action")
                    result.success(action)
                }
                // ดึง path ของโฟลเดอร์ files
                "getFilesDir" -> {
                    result.success(applicationContext.filesDir.absolutePath)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // ==================== Child Mode Service Channel ====================
        // ใช้สำหรับ: ควบคุม foreground service ของโหมดเด็ก
        // - แสดง notification ถาวร
        // - รีสตาร์ทอัตโนมัติเมื่อแอพถูกปิด
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kidguard/childmode").setMethodCallHandler { call, result ->
            when (call.method) {
                // เริ่ม foreground service พร้อมแสดง notification
                "startService" -> {
                    val childName = call.argument<String>("childName") ?: "ลูก"
                    val screenTime = call.argument<Int>("screenTime") ?: 0
                    val dailyLimit = call.argument<Int>("dailyLimit") ?: 0
                    
                    // บันทึกลง SharedPreferences เพื่อให้ service อ่านได้
                    val prefs = getSharedPreferences("ChildModePrefs", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("childName", childName)
                        .putInt("screenTime", screenTime)
                        .putInt("dailyLimit", dailyLimit)
                        .apply()
                    
                    val serviceIntent = Intent(this, ChildModeService::class.java).apply {
                        putExtra(ChildModeService.EXTRA_CHILD_NAME, childName)
                        putExtra(ChildModeService.EXTRA_SCREEN_TIME, screenTime)
                        putExtra(ChildModeService.EXTRA_DAILY_LIMIT, dailyLimit)
                    }
                    
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                // หยุด foreground service
                "stopService" -> {
                    val serviceIntent = Intent(this, ChildModeService::class.java)
                    stopService(serviceIntent)
                    result.success(true)
                }
                // อัปเดตข้อมูลใน notification
                "updateService" -> {
                    val childName = call.argument<String>("childName") ?: "ลูก"
                    val screenTime = call.argument<Int>("screenTime") ?: 0
                    val dailyLimit = call.argument<Int>("dailyLimit") ?: 0
                    
                    // อัปเดต SharedPreferences สำหรับรอบ notification ถัดไป
                    val prefs = getSharedPreferences("ChildModePrefs", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("childName", childName)
                        .putInt("screenTime", screenTime)
                        .putInt("dailyLimit", dailyLimit)
                        .apply()
                    
                    result.success(true)
                }
                // ตรวจสอบว่า service กำลังทำงานอยู่หรือไม่
                "isServiceRunning" -> {
                    result.success(ChildModeService.isServiceRunning())
                }
                // ตั้งค่า flag อนุญาตให้ปิดแอพได้ (หลังกรอก PIN ผู้ปกครอง)
                "setAllowShutdown" -> {
                    val allow = call.argument<Boolean>("allow") ?: false
                    ChildModeService.setAllowShutdown(this, allow)
                    result.success(true)
                }
                // ดึง action ที่เปิดมา (เช่น จากการกด notification)
                "getLaunchAction" -> {
                    val action = intent.getStringExtra("action")
                    // ล้าง action เพื่อไม่ให้ทำงานซ้ำ
                    intent.removeExtra("action")
                    result.success(action)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // ==================== Overlay Channel ====================
        // ใช้สำหรับ: แสดง/ซ่อน overlay บล็อกแอพ (หน้าจอเต็มเมื่อเปิดแอพที่ถูกบล็อก)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.kid_guard/overlay").setMethodCallHandler { call, result ->
            when (call.method) {
                // ตรวจสอบ permission การแสดง overlay
                "checkPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                // ขอ permission การแสดง overlay
                "requestPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, android.net.Uri.parse("package:$packageName"))
                            startActivityForResult(intent, 1234)
                        }
                    }
                    result.success(true)
                }
                // แสดง overlay บล็อกแอพ
                "showOverlay" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                        return@setMethodCallHandler
                    }
                    val packageName = call.argument<String>("packageName") ?: "Blocked App"
                    val intent = Intent(this, OverlayService::class.java)
                    intent.putExtra("packageName", packageName)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                // ซ่อน overlay
                "hideOverlay" -> {
                    val intent = Intent(this, OverlayService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // ==================== Helper Functions ====================
    
    /**
     * ตรวจสอบว่า Accessibility Service เปิดใช้งานอยู่หรือไม่
     * - ใช้ตรวจสอบว่า AppAccessibilityService กำลังทำงาน
     * - จำเป็นสำหรับการบล็อกแอพและติดตามการใช้งาน
     */
    private fun isAccessibilitySettingsOn(mContext: Context): Boolean {
        var accessibilityEnabled = 0
        val service = packageName + "/" + AppAccessibilityService::class.java.canonicalName
        try {
            accessibilityEnabled = Secure.getInt(
                mContext.applicationContext.contentResolver,
                android.provider.Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            // Error finding setting, default to not enabled
        }
        val mStringColonSplitter = SimpleStringSplitter(':')
        if (accessibilityEnabled == 1) {
            val settingValue = Secure.getString(
                mContext.applicationContext.contentResolver,
                Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                mStringColonSplitter.setString(settingValue)
                while (mStringColonSplitter.hasNext()) {
                    val accessibilityService = mStringColonSplitter.next()
                    if (accessibilityService.equals(service, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }
}
