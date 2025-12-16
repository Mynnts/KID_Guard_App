package com.seniorproject.kid_guard

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils.SimpleStringSplitter
import android.provider.Settings.Secure
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.kidguard/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilitySettingsOn(this))
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "updateBlocklist" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps")
                    if (blockedApps != null) {
                        val prefs = getSharedPreferences("KidGuardPrefs", Context.MODE_PRIVATE)
                        prefs.edit().putStringSet("blocked_apps", blockedApps.toSet()).apply()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Blocked apps list is null", null)
                    }
                }
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
                "getLaunchIntentAction" -> {
                    val action = intent.getStringExtra("action")
                    result.success(action)
                }
                "getFilesDir" -> {
                    result.success(applicationContext.filesDir.absolutePath)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.kid_guard/overlay").setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, android.net.Uri.parse("package:$packageName"))
                            startActivityForResult(intent, 1234)
                        }
                    }
                    result.success(true)
                }
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
