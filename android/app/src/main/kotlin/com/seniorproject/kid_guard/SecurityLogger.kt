package com.seniorproject.kid_guard

import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.io.FileInputStream
import java.text.SimpleDateFormat
import java.util.*
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec
import android.util.Base64

/**
 * SecurityLogger - Encrypted logging system for Kid Guard
 * Features:
 * - Encrypted log storage
 * - Log rotation
 * - Size limits
 * - Different log levels
 */
object SecurityLogger {
    
    private const val TAG = "SecurityLogger"
    private const val LOG_DIR = "security_logs"
    private const val MAX_LOG_SIZE = 5 * 1024 * 1024 // 5MB
    private const val MAX_LOG_FILES = 5
    private const val ENCRYPTION_KEY = "K1dGu4rdS3cur1ty" // 16 bytes for AES-128
    
    enum class LogLevel {
        DEBUG, INFO, WARN, ERROR, SECURITY
    }
    
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
    
    /**
     * Initialize logger
     */
    fun init(context: Context) {
        val logDir = getLogDir(context)
        if (!logDir.exists()) {
            logDir.mkdirs()
        }
        performLogRotation(context)
    }
    
    /**
     * Log a message with specified level
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
    
    /**
     * Log debug message
     */
    fun debug(context: Context, message: String, data: Map<String, Any>? = null) {
        log(context, LogLevel.DEBUG, message, data)
    }
    
    /**
     * Log info message
     */
    fun info(context: Context, message: String, data: Map<String, Any>? = null) {
        log(context, LogLevel.INFO, message, data)
    }
    
    /**
     * Log warning message
     */
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
    
    // ==================== Private Methods ====================
    
    private fun getLogDir(context: Context): File {
        return File(context.filesDir, LOG_DIR)
    }
    
    private fun getCurrentLogFile(context: Context): File {
        val logDir = getLogDir(context)
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val fileName = "log_${dateFormat.format(Date())}.enc"
        return File(logDir, fileName)
    }
    
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
    
    private fun encryptAndWrite(file: File, content: String) {
        val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
        val keySpec = SecretKeySpec(ENCRYPTION_KEY.toByteArray(), "AES")
        cipher.init(Cipher.ENCRYPT_MODE, keySpec)
        
        val encrypted = cipher.doFinal(content.toByteArray())
        val encoded = Base64.encodeToString(encrypted, Base64.DEFAULT)
        
        FileOutputStream(file).use { it.write(encoded.toByteArray()) }
    }
    
    private fun decryptFile(file: File): String {
        val encoded = FileInputStream(file).bufferedReader().use { it.readText() }
        val encrypted = Base64.decode(encoded, Base64.DEFAULT)
        
        val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
        val keySpec = SecretKeySpec(ENCRYPTION_KEY.toByteArray(), "AES")
        cipher.init(Cipher.DECRYPT_MODE, keySpec)
        
        val decrypted = cipher.doFinal(encrypted)
        return String(decrypted)
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
