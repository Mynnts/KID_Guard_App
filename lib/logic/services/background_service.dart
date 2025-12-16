import 'dart:async';
import 'package:usage_stats/usage_stats.dart' hide NetworkType;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/local/blocklist_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:device_apps/device_apps.dart';

class BackgroundService {
  Timer? _monitorTimer;
  bool _isMonitoring = false;
  String? _currentChildId;
  String? _currentParentId;
  int _sessionSeconds = 0;

  // Dynamic blocklist
  Set<String> _blockedPackages = {};
  StreamSubscription? _blocklistSubscription;

  // App Usage Tracking
  final Map<String, int> _appUsageSession = {}; // Package -> Seconds
  final Map<String, String> _appNames = {}; // Cache Package -> Name

  // Time Limit
  int _dailyTimeLimit = 0;
  int _currentScreenTime = 0;
  StreamSubscription? _childSubscription;

  String? _lastBlockedPackage;

  final Function(String) onBlockedAppDetected;
  final Function() onTimeLimitReached;
  final Function() onAppAllowed;

  BackgroundService({
    required this.onBlockedAppDetected,
    required this.onTimeLimitReached,
    required this.onAppAllowed,
  });

  Future<void> startMonitoring(String childId, String parentId) async {
    if (_isMonitoring) return;

    _currentChildId = childId;
    _currentParentId = parentId;

    // Save IDs for Background Worker (WorkManager)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_child_id', childId);
    await prefs.setString('current_parent_uid', parentId);

    // Register Periodic Task
    Workmanager().registerPeriodicTask(
      "sync_blocklist",
      "syncBlocklistTask",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Check for permission
    bool? isPermissionGranted = await UsageStats.checkUsagePermission();
    if (isPermissionGranted != true) {
      await UsageStats.grantUsagePermission();
      return;
    }

    _isMonitoring = true;

    // Listen for blocked apps
    _listenToBlocklist();
    // Listen for child settings (Time Limit)
    _listenToChildSettings();

    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _checkForegroundApp();
      _updateScreenTime();
    });
  }

  Future<void> stopMonitoring() async {
    _monitorTimer?.cancel();
    _blocklistSubscription?.cancel();
    _childSubscription?.cancel();
    _isMonitoring = false;
    _sessionSeconds = 0;
    _blockedPackages.clear();
    _lastBlockedPackage = null;
  }

  void _listenToBlocklist() {
    if (_currentChildId == null || _currentParentId == null) return;

    _blocklistSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentParentId)
        .collection('children')
        .doc(_currentChildId)
        .collection('apps')
        .where('isLocked', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) {
            _blockedPackages = snapshot.docs
                .map((doc) => doc['packageName'] as String)
                .toSet();
            print('Updated blocklist: $_blockedPackages');
            // Save to local storage for Native Service (and offline backup)
            BlocklistStorage().saveBlocklist(_blockedPackages.toList());
          },
          onError: (e) {
            print('Error listening to blocklist: $e');
          },
        );
  }

  void _listenToChildSettings() {
    if (_currentChildId == null || _currentParentId == null) return;

    _childSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentParentId)
        .collection('children')
        .doc(_currentChildId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data();
              if (data != null) {
                _dailyTimeLimit = data['dailyTimeLimit'] ?? 0;
                _currentScreenTime = data['screenTime'] ?? 0;
                print(
                  'Updated settings: Limit=$_dailyTimeLimit, Current=$_currentScreenTime',
                );
              }
            }
          },
          onError: (e) {
            print('Error listening to child settings: $e');
          },
        );
  }

  Future<void> _checkForegroundApp() async {
    try {
      // Check Time Limit first
      if (_dailyTimeLimit > 0 && _currentScreenTime >= _dailyTimeLimit) {
        onTimeLimitReached();
        // Return but still allow background checks if needed, but here we block.
        return;
      }

      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(seconds: 2));

      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      // Sort by last time used
      usageStats.sort(
        (a, b) =>
            int.parse(b.lastTimeUsed!).compareTo(int.parse(a.lastTimeUsed!)),
      );

      if (usageStats.isNotEmpty) {
        String currentPackage = usageStats.first.packageName!;

        // Track App Usage
        // We only track meaningful usage if screen is ON (implicit since this runs in timer)
        _appUsageSession[currentPackage] =
            (_appUsageSession[currentPackage] ?? 0) + 1;

        // Cache Name
        if (!_appNames.containsKey(currentPackage)) {
          _appNames[currentPackage] = currentPackage; // Fallback
          DeviceApps.getApp(currentPackage)
              .then((app) {
                if (app != null) {
                  _appNames[currentPackage] = app.appName;
                }
              })
              .catchError((_) {});
        }

        if (_isBlocked(currentPackage)) {
          if (_lastBlockedPackage != currentPackage) {
            onBlockedAppDetected(currentPackage);
            _lastBlockedPackage = currentPackage;
          }
        } else {
          if (_lastBlockedPackage != null) {
            onAppAllowed();
            _lastBlockedPackage = null;
          }
        }
      }
    } catch (e) {
      print('Error checking usage stats: $e');
    }
  }

  Future<void> _updateScreenTime() async {
    if (_currentChildId == null || _currentParentId == null) return;

    _sessionSeconds++;
    _currentScreenTime++;

    // Update Firestore every 10 seconds to reduce writes
    if (_sessionSeconds % 10 == 0) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_currentParentId)
            .collection('children')
            .doc(_currentChildId);

        // 1. Update Realtime (Quick View)
        await docRef.update({
          'screenTime': FieldValue.increment(10),
          'lastActive': FieldValue.serverTimestamp(),
        });

        // 2. Update History (Chart & Apps)
        final dateStr = DateTime.now().toIso8601String().split(
          'T',
        )[0]; // YYYY-MM-DD

        // Prepare App Updates
        Map<String, dynamic> appUpdates = {};
        _appUsageSession.forEach((pkg, seconds) {
          if (seconds > 0) {
            final safeKey = pkg.replaceAll('.', '_');
            final appName = _appNames[pkg] ?? pkg;
            appUpdates['apps.$safeKey.duration'] = FieldValue.increment(
              seconds,
            );
            appUpdates['apps.$safeKey.name'] = appName;
            appUpdates['apps.$safeKey.packageName'] = pkg;
          }
        });

        // Add Timestamp & Total
        appUpdates['screenTime'] = FieldValue.increment(10);
        appUpdates['timestamp'] = FieldValue.serverTimestamp();

        // Use Set with Merge
        await docRef
            .collection('daily_stats')
            .doc(dateStr)
            .set(appUpdates, SetOptions(merge: true));

        // Clear session buffer
        _appUsageSession.clear();
      } catch (e) {
        print('Error updating screen time: $e');
      }
    }
  }

  bool _isBlocked(String packageName) {
    return _blockedPackages.contains(packageName);
  }
}
