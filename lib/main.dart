// ==================== นำเข้า Packages ====================
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kidguard/l10n/app_localizations.dart' show AppLocalizations;
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/theme_provider.dart';
import 'logic/providers/locale_provider.dart';
import 'data/services/security_service.dart';
import 'core/utils/security_logger.dart';

import 'package:workmanager/workmanager.dart';
import 'logic/background_worker.dart';
import 'data/services/local_notification_service.dart';

// ==================== จุดเริ่มต้นแอพ ====================
/// ฟังก์ชัน main() - จุดเริ่มต้นของแอพ
/// 1. Initialize Firebase
/// 2. Initialize WorkManager สำหรับ background tasks
/// 3. รัน MyApp widget
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Local Notifications
  await LocalNotificationService.initialize();

  // ตั้งค่า WorkManager สำหรับงาน background (sync, tracking)
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  runApp(const MyApp());
}

// ==================== Widget หลัก ====================
/// MyApp - Widget หลักที่ครอบทั้งแอพ
/// - ตรวจสอบความปลอดภัยของเครื่องเมื่อเริ่มแอพ
/// - ตั้งค่า Providers (Auth, Theme, Locale)
/// - ตั้งค่า routes และ themes
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SecurityService _securityService = SecurityService();
  bool _securityCheckDone = false; // ตรวจสอบเสร็จแล้วหรือยัง
  SecurityStatus? _securityStatus; // ผลการตรวจสอบความปลอดภัย

  @override
  void initState() {
    super.initState();
    _performSecurityCheck(); // ตรวจสอบความปลอดภัยทันทีเมื่อเปิดแอพ
  }

  // ==================== ตรวจสอบความปลอดภัย ====================
  /// ตรวจสอบว่าเครื่องมีความเสี่ยงหรือไม่
  /// - Root detection
  /// - Emulator detection
  /// - Debugger detection
  Future<void> _performSecurityCheck() async {
    try {
      final status = await _securityService.performSecurityCheck();
      setState(() {
        _securityStatus = status;
        _securityCheckDone = true;
      });

      // บันทึก log ถ้าพบปัญหาความปลอดภัย
      if (status.hasSecurityIssue) {
        await SecurityLogger.security(
          'Security risk detected on startup',
          data: {
            'isRooted': status.isRooted,
            'isEmulator': status.isEmulator,
            'isDebugged': status.isDebugged,
            'riskLevel': status.riskLevel,
          },
        );
      }
    } catch (e) {
      setState(() {
        _securityCheckDone = true;
      });
    }
  }

  // ==================== สร้าง UI ====================
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ==================== Providers ====================
      // AuthProvider - จัดการ login, user data, children data
      // ThemeProvider - จัดการ light/dark mode
      // LocaleProvider - จัดการภาษา (ไทย/อังกฤษ)
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'Kid Guard (BETA)',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: const [Locale('th'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute:
                AppRoutes.selectUser, // เริ่มที่หน้าเลือก parent/child
            routes: AppRoutes.getRoutes(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // แสดง dialog เตือนความปลอดภัยถ้าพบปัญหา
              if (_securityCheckDone &&
                  _securityStatus != null &&
                  _securityStatus!.hasSecurityIssue) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showSecurityWarningDialog(context);
                });
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  // ==================== Dialog เตือนความปลอดภัย ====================

  bool _dialogShown = false;

  void _showSecurityWarningDialog(BuildContext context) {
    if (_dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Security Warning'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security issues detected on this device:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ..._securityStatus!.details
                .take(3)
                .map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            detail,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            Text(
              'Risk Level: ${_securityStatus!.riskLevel}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _securityStatus!.riskLevel > 50
                    ? Colors.red
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Some features may be restricted for security reasons.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
