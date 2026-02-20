package com.seniorproject.kid_guard

// ==================== นำเข้า Libraries ====================
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.io.FileOutputStream
import java.io.FileInputStream
import java.security.KeyStore
import java.text.SimpleDateFormat
import java.util.*
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import android.util.Base64

/**
 * ==================== SecurityLogger ====================
 * ระบบบันทึก Log แบบเข้ารหัสสำหรับ Kid Guard
 * 
 * คุณสมบัติ:
 * - เก็บ Log แบบเข้ารหัสโดยใช้ Android Keystore (ปลอดภัย ดึง key ออกไม่ได้)
 * - ใช้ AES-GCM encryption (มี authentication ป้องกันการแก้ไข)
 * - หมุนเวียนไฟล์ Log อัตโนมัติ (log rotation)
 * - จำกัดขนาดไฟล์
 * - รองรับหลายระดับ log (DEBUG, INFO, WARN, ERROR, SECURITY)
 * 
 * การใช้งาน:
 *   SecurityLogger.init(context)  // เรียกครั้งแรก
 *   SecurityLogger.info(context, "ข้อความ")
 *   SecurityLogger.error(context, "เกิดข้อผิดพลาด", mapOf("key" to value))
 */
object SecurityLogger {
    
    // ==================== ค่าคงที่ (Constants) ====================
    private const val TAG = "SecurityLogger"
    private const val LOG_DIR = "security_logs"           // โฟลเดอร์เก็บ log
    private const val MAX_LOG_SIZE = 5 * 1024 * 1024      // ขนาดสูงสุด 5MB ต่อไฟล์
    private const val MAX_LOG_FILES = 5                    // เก็บไฟล์สูงสุด 5 ไฟล์
    private const val KEYSTORE_ALIAS = "KidGuardLogKey"   // ชื่อ key ใน Keystore
    private const val GCM_IV_LENGTH = 12                   // ความยาว IV สำหรับ GCM
    private const val GCM_TAG_LENGTH = 128                 // ความยาว authentication tag
    
    // ==================== ระดับความรุนแรงของ Log ====================
    enum class LogLevel {
        DEBUG,    // ข้อมูล debug สำหรับนักพัฒนา
        INFO,     // ข้อมูลทั่วไป
        WARN,     // คำเตือน
        ERROR,    // ข้อผิดพลาด
        SECURITY  // เหตุการณ์ด้านความปลอดภัย
    }
    
    // ==================== โครงสร้างข้อมูล Log ====================
    /**
     * LogEntry - โครงสร้างสำหรับเก็บข้อมูล log แต่ละรายการ
     * @param timestamp เวลาที่บันทึก (milliseconds)
     * @param level ระดับความรุนแรง
     * @param message ข้อความ log
     * @param data ข้อมูลเพิ่มเติม (optional)
     */
    data class LogEntry(
        val timestamp: Long,
        val level: LogLevel,
        val message: String,
        val data: Map<String, Any>? = null
    ) {
        override fun toString(): String {
            val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault())
            val timeStr = dateFormat.format(Date(timestamp))
            val dataStr = data?.let { " | Data: $it" } ?: ""
            return "[$timeStr] [${level.name}] $message$dataStr"
        }
    }
    
    // ==================== ฟังก์ชันสาธารณะ (Public Functions) ====================
    
    /**
     * เริ่มต้นระบบ Logger
     * - สร้างโฟลเดอร์เก็บ log (ถ้ายังไม่มี)
     * - หมุนเวียนไฟล์เก่าออก
     */
    fun init(context: Context) {
        val logDir = getLogDir(context)
        if (!logDir.exists()) {
            logDir.mkdirs()
        }
        performLogRotation(context)
    }
    
    /**
     * บันทึก log พร้อมระบุระดับ
     * @param level ระดับ log (DEBUG, INFO, WARN, ERROR, SECURITY)
     * @param message ข้อความที่ต้องการบันทึก
     * @param data ข้อมูลเพิ่มเติม (optional)
     */
    fun log(context: Context, level: LogLevel, message: String, data: Map<String, Any>? = null) {
        val entry = LogEntry(
            timestamp = System.currentTimeMillis(),
            level = level,
            message = message,
            data = data
        )
        writeLog(context, entry)
    }
    
    // ==================== ฟังก์ชันลัดสำหรับแต่ละระดับ ====================
    
    /** บันทึก log ระดับ DEBUG */
    fun debug(context: Context, message: String, data: Map<String, Any>? = null) {
        log(context, LogLevel.DEBUG, message, data)
    }
    
    /** บันทึก log ระดับ INFO */
    fun info(context: Context, message: String, data: Map<String, Any>? = null) {
        log(context, LogLevel.INFO, message, data)
    }
    
    /** บันทึก log ระดับ WARN */
    fun warn(context: Context, message: String, data: Map<String, Any>? = null) {
        log(context, LogLevel.WARN, message, data)
    }
    
    /**
     * Log error message
     */
    fun error(context: Context, message: String, data: Map<String, Any>? = null) {
        log(context, LogLevel.ERROR, message, data)
    }
    
    /**
     * Log security event
     */
    fun logSecurityEvent(context: Context, event: String, data: Map<String, Any>? = null) {
        log(context, LogLevel.SECURITY, "SecurityEvent: $event", data)
    }
    
    /**
     * Log authentication event
     */
    fun logAuthEvent(context: Context, event: String, success: Boolean, userId: String? = null) {
        log(context, LogLevel.SECURITY, "AuthEvent: $event", mapOf(
            "success" to success,
            "userId" to (userId ?: "unknown"),
            "timestamp" to System.currentTimeMillis()
        ))
    }
    
    /**
     * Log app usage event
     */
    fun logAppUsage(context: Context, packageName: String, action: String) {
        log(context, LogLevel.INFO, "AppUsage: $action", mapOf(
            "packageName" to packageName,
            "action" to action
        ))
    }
    
    /**
     * Get all logs
     */
    fun getLogs(context: Context): List<LogEntry> {
        val logs = mutableListOf<LogEntry>()
        val logDir = getLogDir(context)
        
        if (!logDir.exists()) return logs
        
        logDir.listFiles()?.sortedByDescending { it.name }?.forEach { file ->
            try {
                val decrypted = decryptFile(file)
                decrypted.lines().forEach { line ->
                    if (line.isNotBlank()) {
                        logs.add(parseLogLine(line))
                    }
                }
            } catch (e: Exception) {
                // Skip corrupted log files
            }
        }
        
        return logs
    }
    
    /**
     * Get logs as JSON-compatible list
     */
    fun getLogsAsList(context: Context): List<Map<String, Any>> {
        return getLogs(context).map { entry ->
            mapOf(
                "timestamp" to entry.timestamp,
                "level" to entry.level.name,
                "message" to entry.message,
                "data" to (entry.data ?: emptyMap())
            )
        }
    }
    
    /**
     * Clear all logs
     */
    fun clearLogs(context: Context) {
        val logDir = getLogDir(context)
        logDir.listFiles()?.forEach { it.delete() }
        logSecurityEvent(context, "LOGS_CLEARED", null)
    }
    
    /**
     * Export logs to plain text file
     */
    fun exportLogs(context: Context): File? {
        try {
            val exportFile = File(context.cacheDir, "kid_guard_logs_export.txt")
            val logs = getLogs(context)
            
            FileOutputStream(exportFile).bufferedWriter().use { writer ->
                writer.write("=== Kid Guard Security Logs Export ===\n")
                writer.write("Exported: ${SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())}\n")
                writer.write("Total entries: ${logs.size}\n")
                writer.write("========================================\n\n")
                
                logs.forEach { entry ->
                    writer.write("${entry}\n")
                }
            }
            
            return exportFile
        } catch (e: Exception) {
            return null
        }
    }
    
    // ==================== ฟังก์ชันภายใน (Private Methods) ====================
    
    /** ดึง path ของโฟลเดอร์เก็บ log */
    private fun getLogDir(context: Context): File {
        return File(context.filesDir, LOG_DIR)
    }
    
    /** ดึง path ของไฟล์ log วันนี้ */
    private fun getCurrentLogFile(context: Context): File {
        val logDir = getLogDir(context)
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val fileName = "log_${dateFormat.format(Date())}.enc"
        return File(logDir, fileName)
    }
    
    /**
     * เขียน log entry ลงไฟล์
     * - ตรวจสอบขนาดไฟล์ ถ้าเกินจะ rotate
     * - อ่านข้อมูลเก่า, เพิ่มข้อมูลใหม่, เข้ารหัสและเขียนกลับ
     */
    private fun writeLog(context: Context, entry: LogEntry) {
        try {
            val logFile = getCurrentLogFile(context)
            
            // Check if rotation needed
            if (logFile.exists() && logFile.length() > MAX_LOG_SIZE) {
                performLogRotation(context)
            }
            
            // Read existing content
            val existingContent = if (logFile.exists()) {
                try {
                    decryptFile(logFile)
                } catch (e: Exception) {
                    ""
                }
            } else {
                ""
            }
            
            // Append new entry
            val newContent = if (existingContent.isNotEmpty()) {
                "$existingContent\n$entry"
            } else {
                entry.toString()
            }
            
            // Write encrypted content
            encryptAndWrite(logFile, newContent)
            
        } catch (e: Exception) {
            // Fail silently to not disrupt app functionality
            e.printStackTrace()
        }
    }
    
    // ==================== ระบบเข้ารหัส (Encryption System) ====================
    
    /**
     * ดึงหรือสร้าง key จาก Android Keystore
     * - Key ถูกเก็บใน hardware security module
     * - ไม่สามารถดึงออกมาได้ (ปลอดภัยสูง)
     * - ใช้ AES-256 bits
     */
    private fun getOrCreateSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        
        // ตรวจสอบว่ามี key อยู่แล้วหรือไม่
        keyStore.getKey(KEYSTORE_ALIAS, null)?.let {
            return it as SecretKey
        }
        
        // สร้าง key ใหม่ถ้ายังไม่มี
        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore"
        )
        keyGenerator.init(
            KeyGenParameterSpec.Builder(
                KEYSTORE_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()
        )
        return keyGenerator.generateKey()
    }
    
    private fun encryptAndWrite(file: File, content: String) {
        try {
            val secretKey = getOrCreateSecretKey()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)
            
            val iv = cipher.iv // GCM generates random IV automatically
            val encrypted = cipher.doFinal(content.toByteArray(Charsets.UTF_8))
            
            // Prepend IV to encrypted data (IV + encrypted content)
            val combined = iv + encrypted
            val encoded = Base64.encodeToString(combined, Base64.NO_WRAP)
            
            FileOutputStream(file).use { it.write(encoded.toByteArray()) }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Encryption failed: ${e.message}")
        }
    }
    
    private fun decryptFile(file: File): String {
        return try {
            val encoded = FileInputStream(file).bufferedReader().use { it.readText() }
            val combined = Base64.decode(encoded, Base64.NO_WRAP)
            
            // Extract IV (first 12 bytes) and encrypted content
            val iv = combined.copyOfRange(0, GCM_IV_LENGTH)
            val encrypted = combined.copyOfRange(GCM_IV_LENGTH, combined.size)
            
            val secretKey = getOrCreateSecretKey()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
            
            String(cipher.doFinal(encrypted), Charsets.UTF_8)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Decryption failed: ${e.message}")
            "" // Return empty string if decryption fails (old logs may use old key)
        }
    }
    
    private fun performLogRotation(context: Context) {
        val logDir = getLogDir(context)
        val files = logDir.listFiles()?.sortedByDescending { it.lastModified() } ?: return
        
        // Keep only MAX_LOG_FILES
        if (files.size > MAX_LOG_FILES) {
            files.drop(MAX_LOG_FILES).forEach { it.delete() }
        }
    }
    
    private fun parseLogLine(line: String): LogEntry {
        // Parse format: [2024-01-02 12:00:00.000] [INFO] Message | Data: {...}
        try {
            val timestampMatch = Regex("\\[(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d{3})\\]").find(line)
            val levelMatch = Regex("\\[([A-Z]+)\\]").findAll(line).lastOrNull()
            
            val timestamp = if (timestampMatch != null) {
                val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault())
                dateFormat.parse(timestampMatch.groupValues[1])?.time ?: System.currentTimeMillis()
            } else {
                System.currentTimeMillis()
            }
            
            val level = if (levelMatch != null) {
                try {
                    LogLevel.valueOf(levelMatch.groupValues[1])
                } catch (e: Exception) {
                    LogLevel.INFO
                }
            } else {
                LogLevel.INFO
            }
            
            val messageStart = line.indexOf("] ", line.indexOf(level.name)) + 2
            val message = if (messageStart > 1 && messageStart < line.length) {
                line.substring(messageStart).split(" | Data:")[0]
            } else {
                line
            }
            
            return LogEntry(timestamp, level, message, null)
        } catch (e: Exception) {
            return LogEntry(System.currentTimeMillis(), LogLevel.INFO, line, null)
        }
    }
}
