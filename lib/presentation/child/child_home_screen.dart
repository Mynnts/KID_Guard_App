import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/app_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/local/blocklist_storage.dart';
import '../../logic/services/background_service.dart';
import '../../logic/services/overlay_service.dart';
import '../../logic/services/location_service.dart';

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
  bool _isChildrenModeActive = false;
  StreamSubscription<bool>? _syncRequestSubscription;

  // Minimal Premium Colors
  static const _accentColor = Color(0xFFE67E22);
  static const _bgColor = Color(0xFFFAFAFC);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _startSyncing();
    _checkIntent();
  }

  void _checkIntent() {
    platform.invokeMethod('getLaunchIntentAction').then((action) {
      if (action == 'unlock_time_limit') {
        _showPinDialog(isTimeLimitUnlock: true);
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
    _updateOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  Future<void> _toggleChildMode(bool value) async {
    if (value) {
      bool overlayPerm = await _overlayService.checkPermission();
      if (!overlayPerm) {
        await _overlayService.requestPermission();
        overlayPerm = await _overlayService.checkPermission();
        if (!overlayPerm) return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final child = authProvider.currentChild;
      final user = authProvider.userModel;

      if (child != null && user != null) {
        await _backgroundService.startMonitoring(child.id, user.uid);
        await _locationService.startTracking(user.uid, child.id);
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
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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

  void _showPinDialog({bool isTimeLimitUnlock = false}) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTimeLimitUnlock ? 'ปลดล็อคเวลา' : 'กรอก PIN ผู้ปกครอง',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTimeLimitUnlock)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'กรอก PIN เพื่อขยายเวลาอีก 1 ชั่วโมง',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.5),
                  letterSpacing: 8,
                ),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentColor, width: 1.5),
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
                color: _accentColor,
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
            backgroundColor: const Color(0xFF22C55E),
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
    await _backgroundService.stopMonitoring();
    _locationService.stopTracking();

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
      await _appService.syncApps(user.uid, child.id);

      // Listen for sync requests from parent
      _syncRequestSubscription = _appService
          .streamSyncRequest(user.uid, child.id)
          .listen((syncRequested) async {
            if (syncRequested) {
              debugPrint('Sync requested by parent, syncing apps...');
              await _appService.syncApps(user.uid, child.id);
              await _appService.clearSyncRequest(user.uid, child.id);
              debugPrint('Apps synced and request cleared.');
            }
          });

      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .collection('apps')
          .where('isLocked', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
            final blockedPackages = snapshot.docs
                .map((doc) => doc['packageName'] as String)
                .toList();
            _updateNativeBlocklist(blockedPackages);
          });

      // Listen for parent unlock requests
      FirebaseFirestore.instance
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
                // Parent requested unlock - hide overlay
                _overlayService.hideOverlay();

                // Clear the unlock request
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
                      backgroundColor: const Color(0xFF22C55E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
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
            await _backgroundService.startMonitoring(child.id, user.uid);
            await _locationService.startTracking(user.uid, child.id);
            setState(() => _isChildrenModeActive = true);
          }
        }
      }
    }
  }

  Future<void> _updateNativeBlocklist(List<String> blockedApps) async {
    try {
      // Save to file for AccessibilityService to read
      await BlocklistStorage().saveBlocklist(blockedApps);

      // Also update via MethodChannel (SharedPreferences) as backup
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final childName = authProvider.currentChild?.name ?? 'น้อง';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _isChildrenModeActive
                                ? _accentColor
                                : const Color(0xFFF0F0F5),
                            shape: BoxShape.circle,
                            boxShadow: _isChildrenModeActive
                                ? [
                                    BoxShadow(
                                      color: _accentColor.withOpacity(0.3),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isChildrenModeActive
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            size: 56,
                            color: _isChildrenModeActive
                                ? Colors.white
                                : _textSecondary,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          'สวัสดี $childName',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Subtitle
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

                        const SizedBox(height: 48),

                        // Switch
                        GestureDetector(
                          onTap: () => _toggleChildMode(!_isChildrenModeActive),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 88,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isChildrenModeActive
                                  ? _accentColor
                                  : const Color(0xFFE5E5EA),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: _isChildrenModeActive
                                  ? [
                                      BoxShadow(
                                        color: _accentColor.withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
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
                                  _isChildrenModeActive
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  size: 20,
                                  color: _isChildrenModeActive
                                      ? _accentColor
                                      : _textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Status Badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _isChildrenModeActive
                                ? const Color(0xFF22C55E).withOpacity(0.1)
                                : const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isChildrenModeActive
                                  ? const Color(0xFF22C55E).withOpacity(0.3)
                                  : const Color(0xFFE5E5EA),
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
                                  color: _isChildrenModeActive
                                      ? const Color(0xFF22C55E)
                                      : _textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isChildrenModeActive
                                    ? 'กำลังป้องกัน'
                                    : 'ปิดอยู่',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isChildrenModeActive
                                      ? const Color(0xFF22C55E)
                                      : _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
