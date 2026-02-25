import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Mock Setup สำหรับ unit tests (Firebase Core v6+ / Pigeon API)
///
/// ใช้เมื่อ test file ต้อง import class ที่ใช้ Firebase (เช่น FirebaseFirestore.instance)
///
/// Usage:
/// ```dart
/// void main() {
///   setupFirebaseMocks();
///   // ... tests
/// }
/// ```
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ใช้ MockFirebasePlatform เพื่อ mock Firebase Core
  // สำหรับ firebase_core_platform_interface v6+ (Pigeon-based)
  final mockPlatform = _MockFirebasePlatform();
  FirebasePlatform.instance = mockPlatform;
}

/// Mock implementation ของ FirebasePlatform
/// เพียงพอสำหรับให้ Firebase.initializeApp() ไม่ crash
class _MockFirebasePlatform extends FirebasePlatform {
  _MockFirebasePlatform() : super();

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _MockFirebaseApp(name);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _MockFirebaseApp(name ?? defaultFirebaseAppName);
  }

  @override
  List<FirebaseAppPlatform> get apps => [
    _MockFirebaseApp(defaultFirebaseAppName),
  ];
}

/// Mock implementation ของ FirebaseAppPlatform
class _MockFirebaseApp extends FirebaseAppPlatform {
  _MockFirebaseApp(String name)
    : super(
        name,
        const FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: 'fake-app-id',
          messagingSenderId: 'fake-sender-id',
          projectId: 'fake-project-id',
        ),
      );

  @override
  bool get isAutomaticDataCollectionEnabled => false;
}
