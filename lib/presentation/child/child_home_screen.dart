import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/app_service.dart';
import '../../data/services/auth_service.dart';
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
  bool _isChildrenModeActive = false;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _startSyncing();
    _checkIntent();
  }

  void _checkIntent() {
    // We can't easily check intent extras in pure Flutter initState without a plugin or method channel check
    // But since we launched MainActivity, we can check if we were triggered by a specific action
    // However, standard Flutter doesn't expose intent extras directly in initState.
    // We might need to use a method channel to ask "why was I opened?" or listen to new intents.
    // For simplicity, let's assume if the user is here and the overlay was just shown, they might want to unlock.
    // Actually, let's use the method channel to check for pending actions.

    // A better way for MVP: The OverlayService launched MainActivity.
    // We can just show the PIN dialog if we detect we are in a "Time Limit Reached" state but the user is in the app.
    // But the user might just be opening the app normally.

    // Let's add a method to check if we should show unlock dialog.
    platform.invokeMethod('getLaunchIntentAction').then((action) {
      if (action == 'unlock_time_limit') {
        _showPinDialog(isTimeLimitUnlock: true);
      }
    });
  }

  void _initializeServices() {
    _backgroundService = BackgroundService(
      onBlockedAppDetected: (packageName) {
        print('Blocked app detected: $packageName');
        OverlayService().showBlockOverlay(packageName);
      },
      onTimeLimitReached: () {
        print('Time limit reached!');
        OverlayService().showBlockOverlay("Time Limit Reached");
      },
      onAppAllowed: () {
        print('App allowed, hiding overlay');
        OverlayService().hideOverlay();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      // Turn ON
      bool overlayPerm = await _overlayService.checkPermission();
      if (!overlayPerm) {
        await _overlayService.requestPermission();
        // Re-check after returning from settings
        overlayPerm = await _overlayService.checkPermission();
        if (!overlayPerm) return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final child = authProvider.currentChild;
      final user = authProvider.userModel;

      if (child != null && user != null) {
        await _backgroundService.startMonitoring(child.id, user.uid);
        await _locationService.startTracking(user.uid, child.id);
        setState(() {
          _isChildrenModeActive = true;
        });

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('children')
            .doc(child.id)
            .update({'isChildModeActive': true});

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Child Mode Activated')));
        }
      }
    } else {
      // Turn OFF - Require PIN
      _showPinDialog();
    }
  }

  void _showPinDialog({bool isTimeLimitUnlock = false}) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isTimeLimitUnlock ? 'Unlock Time Limit' : 'Enter Parent PIN',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTimeLimitUnlock)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text('Enter PIN to extend time by 1 hour.'),
              ),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: '****',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isTimeLimitUnlock) {
                setState(() {
                  _isUnlocking = false;
                });
                // Re-show overlay
                OverlayService().showBlockOverlay("Time Limit Reached");
              }
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final correctPin = authProvider.userModel?.pin;

              if (pinController.text == correctPin) {
                Navigator.pop(context); // Close dialog
                if (isTimeLimitUnlock) {
                  setState(() {
                    _isUnlocking = false;
                  });
                  await _extendTimeLimit();
                } else {
                  await _disableChildMode();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Unlock'),
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
      // Extend by 1 hour (3600 seconds)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .update({'dailyTimeLimit': FieldValue.increment(3600)});

      // Hide overlay immediately (BackgroundService will pick up the change shortly)
      OverlayService().hideOverlay();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time extended by 1 hour')),
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

    setState(() {
      _isChildrenModeActive = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Child Mode Deactivated')));
    }
  }

  Future<void> _startSyncing() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final child = authProvider.currentChild;
    final user = authProvider.userModel;

    if (child != null && user != null) {
      // 1. Sync Installed Apps to Firestore
      await AppService().syncApps(user.uid, child.id);

      // 2. Listen for Blocked Apps from Firestore and update Native Service
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

      _updateOnlineStatus(true);

      // Check initial state from Firestore
      final childDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .get();

      if (childDoc.exists && mounted) {
        final isActive = childDoc.data()?['isChildModeActive'] ?? false;
        if (isActive) {
          // Auto-start if it was active
          // We need to check permissions silently or prompt?
          // For now, let's just update UI state, user might need to re-enable if killed
          // Or we can try to start monitoring if we have permission
          bool overlayPerm = await _overlayService.checkPermission();
          if (overlayPerm) {
            await _backgroundService.startMonitoring(child.id, user.uid);
            await _locationService.startTracking(user.uid, child.id);
            setState(() {
              _isChildrenModeActive = true;
            });
          }
        }
      }
    }
  }

  Future<void> _updateNativeBlocklist(List<String> blockedApps) async {
    try {
      await platform.invokeMethod('updateBlocklist', {
        'blockedApps': blockedApps,
      });
      print("Updated native blocklist: $blockedApps");
    } catch (e) {
      print("Failed to update native blocklist: $e");
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
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Light Cyan
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.child_care, size: 100, color: Colors.cyan),
              const SizedBox(height: 32),
              Text(
                'Children Mode',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade900,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Turn on to protect this device and sync apps to parent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 48),
              Transform.scale(
                scale: 2.0,
                child: Switch(
                  value: _isChildrenModeActive,
                  onChanged: (value) => _toggleChildMode(value),
                  activeColor: Colors.cyan,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isChildrenModeActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isChildrenModeActive ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
