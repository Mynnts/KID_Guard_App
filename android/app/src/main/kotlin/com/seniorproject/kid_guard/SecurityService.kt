package com.seniorproject.kid_guard

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import java.io.File

/**
 * SecurityService - Runtime security checks for Kid Guard
 * Provides detection for:
 * - Root/Rooted devices
 * - Debugger attachment
 * - Emulator environments
 * - App signature tampering
 */
object SecurityService {
    
    private const val TAG = "SecurityService"
    
    // Known root management apps
    private val ROOT_APPS = arrayOf(
        "com.topjohnwu.magisk",
        "eu.chainfire.supersu",
        "com.koushikdutta.superuser",
        "com.noshufou.android.su",
        "com.thirdparty.superuser",
        "com.kingroot.kinguser",
        "com.kingo.root"
    )
    
    // Known root binaries
    private val ROOT_BINARIES = arrayOf(
        "su", "busybox", "magisk"
    )
    
    // Root paths to check
    private val ROOT_PATHS = arrayOf(
        "/system/app/Superuser.apk",
        "/sbin/su",
        "/system/bin/su",
        "/system/xbin/su",
        "/data/local/xbin/su",
        "/data/local/bin/su",
        "/system/sd/xbin/su",
        "/system/bin/failsafe/su",
        "/data/local/su",
        "/su/bin/su"
    )
    
    // Dangerous build properties indicating root
    private val DANGEROUS_PROPS = mapOf(
        "ro.debuggable" to "1",
        "ro.secure" to "0"
    )
    
    data class SecurityStatus(
        val isRooted: Boolean = false,
        val isDebugged: Boolean = false,
        val isEmulator: Boolean = false,
        val isTampered: Boolean = false,
        val riskLevel: Int = 0, // 0-100
        val details: List<String> = emptyList()
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "isRooted" to isRooted,
            "isDebugged" to isDebugged,
            "isEmulator" to isEmulator,
            "isTampered" to isTampered,
            "riskLevel" to riskLevel,
            "details" to details
        )
    }
    
    /**
     * Perform comprehensive security check
     */
    fun performSecurityCheck(context: Context, expectedSignature: String? = null): SecurityStatus {
        val details = mutableListOf<String>()
        var riskLevel = 0
        
        // Root Detection
        val isRooted = checkRootStatus(context, details)
        if (isRooted) riskLevel += 40
        
        // Debugger Detection
        val isDebugged = checkDebuggerStatus(details)
        if (isDebugged) riskLevel += 30
        
        // Emulator Detection
        val isEmulator = checkEmulatorStatus(details)
        if (isEmulator) riskLevel += 20
        
        // Signature Verification
        val isTampered = if (expectedSignature != null) {
            checkSignatureStatus(context, expectedSignature, details)
        } else {
            false
        }
        if (isTampered) riskLevel += 50
        
        val status = SecurityStatus(
            isRooted = isRooted,
            isDebugged = isDebugged,
            isEmulator = isEmulator,
            isTampered = isTampered,
            riskLevel = minOf(riskLevel, 100),
            details = details
        )
        
        // Log security check
        SecurityLogger.logSecurityEvent(
            context,
            if (riskLevel > 0) "SECURITY_RISK_DETECTED" else "SECURITY_CHECK_PASSED",
            status.toMap()
        )
        
        return status
    }
    
    /**
     * Check if device is rooted
     */
    private fun checkRootStatus(context: Context, details: MutableList<String>): Boolean {
        var isRooted = false
        
        // Check for root management apps
        val pm = context.packageManager
        for (app in ROOT_APPS) {
            try {
                pm.getPackageInfo(app, 0)
                details.add("Root app detected: $app")
                isRooted = true
            } catch (e: PackageManager.NameNotFoundException) {
                // App not installed, good
            }
        }
        
        // Check for su binary in common paths
        for (path in ROOT_PATHS) {
            val file = File(path)
            if (file.exists()) {
                details.add("Root binary found: $path")
                isRooted = true
            }
        }
        
        // Check for root binaries in PATH
        val paths = System.getenv("PATH")?.split(":") ?: emptyList()
        for (pathDir in paths) {
            for (binary in ROOT_BINARIES) {
                val file = File(pathDir, binary)
                if (file.exists() && file.canExecute()) {
                    details.add("Executable root binary: ${file.absolutePath}")
                    isRooted = true
                }
            }
        }
        
        // Check build tags
        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) {
            details.add("Test-keys build detected")
            isRooted = true
        }
        
        return isRooted
    }
    
    /**
     * Check if debugger is attached
     */
    private fun checkDebuggerStatus(details: MutableList<String>): Boolean {
        var isDebugged = false
        
        // Check if debugger is connected
        if (Debug.isDebuggerConnected()) {
            details.add("Debugger is connected")
            isDebugged = true
        }
        
        // Check if waiting for debugger
        if (Debug.waitingForDebugger()) {
            details.add("App is waiting for debugger")
            isDebugged = true
        }
        
        return isDebugged
    }
    
    /**
     * Check if running in emulator
     */
    private fun checkEmulatorStatus(details: MutableList<String>): Boolean {
        var isEmulator = false
        
        // Check Build properties
        val suspiciousProperties = listOf(
            Build.FINGERPRINT.contains("generic"),
            Build.FINGERPRINT.contains("unknown"),
            Build.MODEL.contains("google_sdk"),
            Build.MODEL.contains("Emulator"),
            Build.MODEL.contains("Android SDK built for x86"),
            Build.MANUFACTURER.contains("Genymotion"),
            Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"),
            Build.PRODUCT.contains("sdk"),
            Build.PRODUCT.contains("vbox"),
            Build.PRODUCT.contains("emulator"),
            Build.HARDWARE.contains("goldfish"),
            Build.HARDWARE.contains("ranchu")
        )
        
        for ((index, prop) in suspiciousProperties.withIndex()) {
            if (prop) {
                when (index) {
                    0, 1 -> details.add("Suspicious fingerprint: ${Build.FINGERPRINT}")
                    2, 3, 4 -> details.add("Suspicious model: ${Build.MODEL}")
                    5 -> details.add("Genymotion detected")
                    6 -> details.add("Generic brand/device combination")
                    7, 8, 9 -> details.add("Suspicious product: ${Build.PRODUCT}")
                    10, 11 -> details.add("Suspicious hardware: ${Build.HARDWARE}")
                }
                isEmulator = true
            }
        }
        
        // Check for QEMU
        if (Build.HARDWARE == "goldfish" || Build.HARDWARE == "ranchu") {
            details.add("QEMU-based emulator detected")
            isEmulator = true
        }
        
        return isEmulator
    }
    
    /**
     * Check if app signature has been tampered
     */
    @Suppress("DEPRECATION")
    private fun checkSignatureStatus(
        context: Context,
        expectedSignature: String,
        details: MutableList<String>
    ): Boolean {
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                context.packageManager.getPackageInfo(
                    context.packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
            } else {
                context.packageManager.getPackageInfo(
                    context.packageName,
                    PackageManager.GET_SIGNATURES
                )
            }
            
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }
            
            if (signatures != null && signatures.isNotEmpty()) {
                val currentSignature = signatures[0].toCharsString()
                val signatureHash = currentSignature.hashCode().toString()
                
                if (signatureHash != expectedSignature) {
                    details.add("Signature mismatch detected")
                    return true
                }
            }
        } catch (e: Exception) {
            details.add("Failed to verify signature: ${e.message}")
            return true
        }
        
        return false
    }
    
    /**
     * Quick root check (faster, less comprehensive)
     */
    fun quickRootCheck(): Boolean {
        // Check su binary
        for (path in ROOT_PATHS) {
            if (File(path).exists()) return true
        }
        
        // Check build tags
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }
    
    /**
     * Quick emulator check
     */
    fun quickEmulatorCheck(): Boolean {
        return Build.FINGERPRINT.contains("generic") ||
               Build.MODEL.contains("Emulator") ||
               Build.HARDWARE.contains("goldfish") ||
               Build.HARDWARE.contains("ranchu")
    }
}
