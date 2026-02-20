import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/app_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/device_service.dart';
import '../../data/local/blocklist_storage.dart';
import '../../logic/services/background_service.dart';
import '../../logic/services/overlay_service.dart';
import '../../logic/services/location_service.dart';
import '../../logic/services/native_settings_sync.dart';
import '../../logic/services/child_mode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'child_rewards_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen>
    with WidgetsBindingObserver {
  static const platform = MethodChannel('com.kidguard/native');

  late final BackgroundService _backgroundService;
  final OverlayService _overlayService = OverlayService();
  final LocationService _locationService = LocationService();
  final AppService _appService = AppService();
  final DeviceService _deviceService = DeviceService();
  bool _isChildrenModeActive = false;
  StreamSubscription<bool>? _syncRequestSubscription;
  StreamSubscription<List<String>>? _blockedAppsSubscription;
  StreamSubscription<DocumentSnapshot>? _childDocSubscription;
  Timer? _screenTimeTimer;

  // Modern Sage Green Theme Colors
  static const _primaryColor = Color(0xFF6B9080);
  static const _secondaryColor = Color(0xFF84A98C);
  static const _tertiaryColor = Color(0xFFCCE3DE);
  static const _bgColor = Color(0xFFF6FBF4);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _successColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreState();
    _initializeServices();
    _startSyncing();
    _checkIntent();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    bool isActive = prefs.getBool('isChildModeActive') ?? false;

    // Check if service is actually running to be more accurate
    final isServiceRunning = await ChildModeService.isRunning();
    if (isServiceRunning) {
      isActive = true;
    }

    if (isActive) {
      if (mounted) {
        setState(() {
          _isChildrenModeActive = true;
        });
      }
    }
  }

  void _checkIntent() {
    platform.invokeMethod('getLaunchIntentAction').then((action) {
      if (action == 'unlock_time_limit') {
        _showPinDialog(isTimeLimitUnlock: true);
      }
    });

    // Check if launched from ChildModeService notification stop button
    ChildModeService.getLaunchAction().then((action) {
      if (action == 'com.kidguard.ACTION_STOP_CHILD_MODE') {
        _showPinDialog(isStopService: true);
      }
    });
  }

  void _initializeServices() {
    _backgroundService = BackgroundService(
      onBlockedAppDetected: (packageName) {
        OverlayService().showBlockOverlay(packageName);
      },
      onTimeLimitReached: () {
        OverlayService().showBlockOverlay("Time Limit Reached");
      },
      onAppAllowed: () {
        OverlayService().hideOverlay();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncRequestSubscription?.cancel();
    _blockedAppsSubscription?.cancel();
    _childDocSubscription?.cancel();
    _screenTimeTimer?.cancel();
    _updateOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
      // Check if user tapped "หยุดบริการ" from notification
      _checkIntentOnResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  void _checkIntentOnResume() {
    ChildModeService.getLaunchAction().then((action) {
      if (action == 'com.kidguard.ACTION_STOP_CHILD_MODE') {
        _showPinDialog(isStopService: true);
      }
    });
  }

  Future<void> _toggleChildMode(bool value) async {
    if (value) {
      // Check overlay permission
      bool overlayPerm = await _overlayService.checkPermission();
      if (!overlayPerm) {
        await _overlayService.requestPermission();
        overlayPerm = await _overlayService.checkPermission();
        if (!overlayPerm) return;
      }

      // Check Accessibility Service permission
      final isAccessibilityEnabled = await platform.invokeMethod(
        'isAccessibilityEnabled',
      );
      if (isAccessibilityEnabled != true) {
        // Show dialog to enable Accessibility Service
        if (mounted) {
          final shouldOpen = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.accessibility_new, color: _primaryColor),
                  SizedBox(width: 12),
                  Text('ต้องเปิด Accessibility'),
                ],
              ),
              content: const Text(
                'กรุณาเปิด Accessibility Service เพื่อให้แอพทำงานเบื้องหลังและบล็อคแอพได้\n\n'
                'ไป Settings → Accessibility → Kid Guard → เปิด',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  child: const Text(
                    'ไปตั้งค่า',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );

          if (shouldOpen == true) {
            await platform.invokeMethod('openAccessibilitySettings');
          }
        }
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final child = authProvider.currentChild;
      final user = authProvider.userModel;

      if (child != null && user != null) {
        // Sync blocklist immediately before enabling child mode
        await _deviceService.registerDevice(user.uid, child.id);
        await _appService.syncAppsForDevice(user.uid, child.id);

        // Get and save blocklist to local file immediately
        final blockedApps = await _appService
            .streamBlockedApps(user.uid, child.id)
            .first;
        await _updateNativeBlocklist(blockedApps);
        debugPrint(
          'Initial blocklist synced: ${blockedApps.length} blocked apps',
        );

        await NativeSettingsSync().enableChildMode(user.uid, child.id);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isChildModeActive', true);

        await _backgroundService.startMonitoring(child.id, user.uid);
        await _locationService.startTracking(user.uid, child.id);

        // Start foreground notification service
        await ChildModeService.start(
          childName: child.name,
          screenTime: child.screenTime,
          dailyLimit: child.dailyTimeLimit,
        );

        setState(() => _isChildrenModeActive = true);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('children')
            .doc(child.id)
            .update({'isChildModeActive': true});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Text('เปิดใช้งานโหมดเด็กแล้ว'),
                ],
              ),
              backgroundColor: _successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      }
    } else {
      _showPinDialog();
    }
  }

  void _showPinDialog({
    bool isTimeLimitUnlock = false,
    bool isStopService = false,
  }) {
    final pinController = TextEditingController();

    // Determine dialog title and subtitle based on mode
    String dialogTitle;
    String? dialogSubtitle;

    if (isTimeLimitUnlock) {
      dialogTitle = 'ปลดล็อคเวลา';
      dialogSubtitle = 'กรอก PIN เพื่อขยายเวลาอีก 1 ชั่วโมง';
    } else if (isStopService) {
      dialogTitle = 'หยุดการป้องกัน';
      dialogSubtitle = 'กรอก PIN ผู้ปกครองเพื่อปิดโหมดเด็ก';
    } else {
      dialogTitle = 'กรอก PIN ผู้ปกครอง';
      dialogSubtitle = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          dialogTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dialogSubtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  dialogSubtitle,
                  style: const TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6, // Parent PIN is 6 digits
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '••••••',
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.5),
                  letterSpacing: 8,
                ),
                counterText: '',
                filled: true,
                fillColor: _tertiaryColor.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isTimeLimitUnlock) {
                OverlayService().showBlockOverlay("Time Limit Reached");
              }
            },
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final correctPin = authProvider.userModel?.pin;

              if (pinController.text == correctPin) {
                Navigator.pop(context);
                if (isTimeLimitUnlock) {
                  await _extendTimeLimit();
                } else {
                  // Both isStopService and normal mode will disable child mode
                  await _disableChildMode();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('PIN ไม่ถูกต้อง'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'ยืนยัน',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _extendTimeLimit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final child = authProvider.currentChild;
    final user = authProvider.userModel;

    if (child != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .update({'dailyTimeLimit': FieldValue.increment(3600)});

      OverlayService().hideOverlay();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ขยายเวลาอีก 1 ชั่วโมง'),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _disableChildMode() async {
    await NativeSettingsSync().disableChildMode();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isChildModeActive', false);

    await _backgroundService.stopMonitoring();
    _locationService.stopTracking();

    // Stop foreground notification service
    await ChildModeService.stop();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final child = authProvider.currentChild;
    final user = authProvider.userModel;

    if (child != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .update({'isChildModeActive': false});
    }

    setState(() => _isChildrenModeActive = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ปิดโหมดเด็กแล้ว'),
          backgroundColor: _textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _startSyncing() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final child = authProvider.currentChild;
    final user = authProvider.userModel;

    if (child != null && user != null) {
      // Register this device and sync apps immediately when child opens home screen
      final deviceId = await _deviceService.getDeviceId();
      debugPrint(
        '📱 ChildHome: Registering device $deviceId for child ${child.name}',
      );
      await _deviceService.registerDevice(user.uid, child.id);
      await _appService.syncAppsForDevice(user.uid, child.id);
      debugPrint('✅ ChildHome: Apps synced for device $deviceId');

      // Listen for sync requests for this device
      _syncRequestSubscription = _deviceService
          .streamSyncRequest(user.uid, child.id)
          .listen((syncRequested) async {
            if (syncRequested) {
              await _appService.syncAppsForDevice(user.uid, child.id);
              await _deviceService.clearSyncRequest(user.uid, child.id);
            }
          });

      // Listen for blocked apps from all devices
      _blockedAppsSubscription = _appService
          .streamBlockedApps(user.uid, child.id)
          .listen((blockedPackages) {
            _updateNativeBlocklist(blockedPackages);
          });

      // Cancel previous listener if exists to prevent duplicates
      await _childDocSubscription?.cancel();
      _childDocSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .snapshots()
          .listen((snapshot) async {
            if (snapshot.exists) {
              final unlockRequested =
                  snapshot.data()?['unlockRequested'] ?? false;
              if (unlockRequested) {
                _overlayService.hideOverlay();

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('children')
                    .doc(child.id)
                    .update({'unlockRequested': false});

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.lock_open, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text('ผู้ปกครองปลดล็อคให้แล้ว'),
                        ],
                      ),
                      backgroundColor: _successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }

              await NativeSettingsSync().loadFromFirebaseAndSync(
                user.uid,
                child.id,
              );
            }
          });

      // Cancel previous timer if exists
      _screenTimeTimer?.cancel();
      _screenTimeTimer = Timer.periodic(const Duration(seconds: 30), (
        timer,
      ) async {
        if (!mounted || !_isChildrenModeActive) {
          timer.cancel();
          return;
        }
        await NativeSettingsSync().syncScreenTimeToFirebase(user.uid, child.id);

        // Update notification with latest screen time
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentChild = authProvider.currentChild;
        if (currentChild != null) {
          await ChildModeService.update(
            childName: currentChild.name,
            screenTime: currentChild.screenTime,
            dailyLimit: currentChild.dailyTimeLimit,
          );
        }
      });

      _updateOnlineStatus(true);

      final childDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .get();

      if (childDoc.exists && mounted) {
        final isActive = childDoc.data()?['isChildModeActive'] ?? false;
        if (isActive) {
          bool overlayPerm = await _overlayService.checkPermission();
          if (overlayPerm) {
            await NativeSettingsSync().enableChildMode(user.uid, child.id);
            await _backgroundService.startMonitoring(child.id, user.uid);
            await _locationService.startTracking(user.uid, child.id);

            // Re-start foreground notification service if it was killed
            final data = childDoc.data();
            await ChildModeService.start(
              childName: child.name,
              screenTime: data?['screenTime'] ?? 0,
              dailyLimit: data?['dailyTimeLimit'] ?? 0,
            );

            setState(() => _isChildrenModeActive = true);
          }
        }
      }
    }
  }

  Future<void> _updateNativeBlocklist(List<String> blockedApps) async {
    try {
      await BlocklistStorage().saveBlocklist(blockedApps);
      await platform.invokeMethod('updateBlocklist', {
        'blockedApps': blockedApps,
      });
    } catch (e) {
      debugPrint("Failed to update native blocklist: $e");
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final child = authProvider.currentChild;
    final user = authProvider.userModel;

    if (child != null && user != null) {
      await AuthService().updateChildStatus(user.uid, child.id, isOnline);
      // Also update device status
      await _deviceService.updateDeviceStatus(user.uid, child.id, isOnline);
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}ชม. ${minutes}น.';
    }
    return '${minutes}น.';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final child = authProvider.currentChild;
    final childName = child?.name ?? 'น้อง';
    final points = child?.points ?? 0;
    // Total screen time today (resets at midnight)
    final screenTime = child?.screenTime ?? 0;
    // Time used towards limit (resettable by parent)
    final limitUsedTime = child?.limitUsedTime ?? 0;
    final dailyLimit = child?.dailyTimeLimit ?? 0;
    final remainingTime = dailyLimit > 0
        ? (dailyLimit - limitUsedTime).clamp(0, dailyLimit)
        : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (Platform.isAndroid) {
          const intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            category: 'android.intent.category.HOME',
            flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          try {
            await intent.launch();
          } catch (e) {
            debugPrint("Failed to launch home intent: $e");
          }
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Points Card
                  _buildPointsCard(points, childName),

                  const SizedBox(height: 32),

                  // Shield Icon
                  _buildShieldIcon(),

                  const SizedBox(height: 32),

                  // Title & Subtitle
                  Text(
                    'สวัสดี $childName',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isChildrenModeActive
                        ? 'โหมดป้องกันกำลังทำงาน'
                        : 'เปิดใช้งานเพื่อเริ่มการป้องกัน',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Toggle Switch
                  _buildToggleSwitch(),

                  const SizedBox(height: 20),

                  // Status Badge
                  _buildStatusBadge(),

                  const SizedBox(height: 32),

                  // Screen Time Info - pass both values
                  if (dailyLimit > 0 || screenTime > 0 || limitUsedTime > 0)
                    _buildScreenTimeCard(
                      screenTime,
                      limitUsedTime,
                      remainingTime,
                      dailyLimit,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(int points, String childName) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: _primaryColor.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChildRewardsScreen()),
          ),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Star Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Points Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'แต้มสะสม',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: points),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Text(
                            '$value pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShieldIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: _isChildrenModeActive
            ? const LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _isChildrenModeActive ? null : _tertiaryColor.withOpacity(0.5),
        shape: BoxShape.circle,
        boxShadow: _isChildrenModeActive
            ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.30),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: _primaryColor.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(
        _isChildrenModeActive ? Icons.shield_rounded : Icons.shield_outlined,
        size: 56,
        color: _isChildrenModeActive ? Colors.white : _textSecondary,
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return GestureDetector(
      onTap: () => _toggleChildMode(!_isChildrenModeActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 88,
        height: 48,
        decoration: BoxDecoration(
          gradient: _isChildrenModeActive
              ? const LinearGradient(colors: [_primaryColor, _secondaryColor])
              : null,
          color: _isChildrenModeActive ? null : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isChildrenModeActive
              ? [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: _isChildrenModeActive
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(4),
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isChildrenModeActive ? Icons.check_rounded : Icons.close_rounded,
              size: 20,
              color: _isChildrenModeActive ? _primaryColor : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _isChildrenModeActive
            ? _successColor.withOpacity(0.1)
            : _tertiaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isChildrenModeActive
              ? _successColor.withOpacity(0.3)
              : _tertiaryColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isChildrenModeActive ? _successColor : _textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isChildrenModeActive ? 'กำลังป้องกัน' : 'ปิดอยู่',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isChildrenModeActive ? _successColor : _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeCard(
    int screenTime,
    int limitUsedTime,
    int remainingTime,
    int dailyLimit,
  ) {
    return Column(
      children: [
        // Section 1: Total Daily Screen Time (resets at midnight)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFCFDFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _tertiaryColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tertiaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.today_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'เวลาเล่นทั้งหมดวันนี้',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(screenTime),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Resets at midnight badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _tertiaryColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: _textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Reset เที่ยงคืน',
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section 2: Time Limit Progress (if limit is set)
        if (dailyLimit > 0) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  remainingTime < 1800 ? const Color(0xFFFEF2F2) : Colors.white,
                  remainingTime < 1800
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFFCFDFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: remainingTime < 1800
                    ? const Color(0xFFEF4444).withOpacity(0.3)
                    : _tertiaryColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: remainingTime < 1800
                      ? const Color(0xFFEF4444).withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: remainingTime < 1800
                            ? const Color(0xFFEF4444).withOpacity(0.1)
                            : _tertiaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: remainingTime < 1800
                            ? const Color(0xFFEF4444)
                            : _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'ขีดจำกัดเวลาเล่น',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats Row
                Row(
                  children: [
                    // Used Time
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(limitUsedTime),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ใช้ไปแล้ว',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(width: 1, height: 50, color: _tertiaryColor),
                    // Remaining Time
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(remainingTime),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: remainingTime < 1800
                                  ? const Color(0xFFEF4444)
                                  : _successColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'เหลืออีก',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Progress Bar
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (limitUsedTime / dailyLimit).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: _tertiaryColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (limitUsedTime / dailyLimit) > 0.8
                          ? const Color(0xFFEF4444)
                          : _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
