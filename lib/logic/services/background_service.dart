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
  int _currentLimitUsedTime = 0; // For time limit checking
  DateTime? _timeLimitDisabledUntil;
  StreamSubscription? _childSubscription;

  String? _lastBlockedPackage;

  // Sleep Schedule
  bool _sleepScheduleEnabled = false;
  int _bedtimeHour = 20;
  int _bedtimeMinute = 0;
  int _wakeHour = 7;
  int _wakeMinute = 0;

  // Quiet Times
  List<Map<String, dynamic>> _quietTimes = [];

  // Track if currently in restricted time
  bool _isInRestrictedTime = false;

  // Instant Pause / Lock
  bool _isDeviceLocked = false;
  DateTime? _pauseUntil;

  final Function(String) onBlockedAppDetected;
  final Function() onTimeLimitReached;
  final Function() onAppAllowed;

  BackgroundService({
    required this.onBlockedAppDetected,
    required this.onTimeLimitReached,
    required this.onAppAllowed,
  });

  Future<void> startMonitoring(String childId, String parentId) async {
    // If already monitoring same child, skip
    if (_isMonitoring &&
        _currentChildId == childId &&
        _currentParentId == parentId) {
      return;
    }

    // If monitoring different child, stop first then restart
    if (_isMonitoring) {
      await stopMonitoring();
    }

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
    // Listen for child settings (Time Limit + Schedules)
    _listenToChildSettings();

    // Set online status and session start time
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentParentId)
          .collection('children')
          .doc(_currentChildId)
          .update({
            'isOnline': true,
            'sessionStartTime': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Error setting online status
    }

    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _checkForegroundApp();
      _updateScreenTime();
    });
  }

  Future<void> stopMonitoring() async {
    // Set offline status before stopping
    if (_currentChildId != null && _currentParentId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentParentId)
            .collection('children')
            .doc(_currentChildId)
            .update({
              'isOnline': false,
              'sessionStartTime': null,
              'lastActive': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        // Error setting offline status
      }
    }

    _monitorTimer?.cancel();
    _blocklistSubscription?.cancel();
    _childSubscription?.cancel();
    _isMonitoring = false;
    _sessionSeconds = 0;
    _blockedPackages.clear();
    _lastBlockedPackage = null;
    _isInRestrictedTime = false;
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
            // Blocklist updated
            // Save to local storage for Native Service (and offline backup)
            BlocklistStorage().saveBlocklist(_blockedPackages.toList());
          },
          onError: (e) {
            // Error listening to blocklist
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
                // Time Limit
                _dailyTimeLimit = data['dailyTimeLimit'] ?? 0;
                // Use limitUsedTime for limit checking, fallback to screenTime for older data
                _currentLimitUsedTime =
                    data['limitUsedTime'] ?? data['screenTime'] ?? 0;

                // Time Limit Disabled Until (set by parent unlock)
                if (data['timeLimitDisabledUntil'] != null) {
                  _timeLimitDisabledUntil =
                      (data['timeLimitDisabledUntil'] as Timestamp).toDate();
                } else {
                  _timeLimitDisabledUntil = null;
                }

                // Sleep Schedule
                if (data['sleepSchedule'] != null) {
                  final sleep = data['sleepSchedule'] as Map<String, dynamic>;
                  _sleepScheduleEnabled = sleep['enabled'] ?? false;
                  _bedtimeHour = sleep['bedtimeHour'] ?? 20;
                  _bedtimeMinute = sleep['bedtimeMinute'] ?? 0;
                  _wakeHour = sleep['wakeHour'] ?? 7;
                  _wakeMinute = sleep['wakeMinute'] ?? 0;
                }

                // Quiet Times
                if (data['quietTimes'] != null) {
                  _quietTimes = List<Map<String, dynamic>>.from(
                    (data['quietTimes'] as List).map(
                      (item) => Map<String, dynamic>.from(item),
                    ),
                  );
                } else {
                  _quietTimes = [];
                }

                // Global Lock & Pause
                _isDeviceLocked = data['isLocked'] ?? false;
                if (data['pauseUntil'] != null) {
                  _pauseUntil = DateTime.parse(data['pauseUntil']);
                } else {
                  _pauseUntil = null;
                }

                // Check for auto-unlock
                if (_pauseUntil != null &&
                    DateTime.now().isAfter(_pauseUntil!)) {
                  _unlockDevice();
                }

                // Handle parent unlock request
                final unlockRequested = data['unlockRequested'] ?? false;
                if (unlockRequested && !_isDeviceLocked) {
                  // Parent has unlocked the device - hide overlay and reset
                  onAppAllowed(); // This calls OverlayService().hideOverlay()
                  _isInRestrictedTime = false;

                  // Reset unlockRequested flag in Firestore
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentParentId)
                      .collection('children')
                      .doc(_currentChildId)
                      .update({'unlockRequested': false});

                  // Parent unlock received
                }
              }
            }
          },
          onError: (e) {
            // Error listening to child settings
          },
        );
  }

  /// Update isLocked status in Firestore so parent can see unlock button
  Future<void> _setLockedInFirestore(bool isLocked, String reason) async {
    if (_currentChildId == null || _currentParentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentParentId)
          .collection('children')
          .doc(_currentChildId)
          .update({
            'isLocked': isLocked,
            'lockReason': reason,
            'lockedAt': isLocked ? FieldValue.serverTimestamp() : null,
          });
      // Firestore locked status updated
    } catch (e) {
      // Error updating isLocked in Firestore
    }
  }

  /// Check if current time is within sleep schedule
  bool _isInSleepTime() {
    if (!_sleepScheduleEnabled) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final bedtimeMinutes = _bedtimeHour * 60 + _bedtimeMinute;
    final wakeMinutes = _wakeHour * 60 + _wakeMinute;

    // Handle overnight sleep (e.g., 20:00 - 07:00)
    if (bedtimeMinutes > wakeMinutes) {
      // Overnight: current time is in sleep if >= bedtime OR < wake time
      return currentMinutes >= bedtimeMinutes || currentMinutes < wakeMinutes;
    } else {
      // Same day: current time is in sleep if >= bedtime AND < wake time
      return currentMinutes >= bedtimeMinutes && currentMinutes < wakeMinutes;
    }
  }

  /// Check if current time is within any quiet time period
  bool _isInQuietTime() {
    if (_quietTimes.isEmpty) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (final period in _quietTimes) {
      final enabled = period['enabled'] ?? false;
      if (!enabled) continue;

      final startMinutes =
          (period['startHour'] ?? 0) * 60 + (period['startMinute'] ?? 0);
      final endMinutes =
          (period['endHour'] ?? 0) * 60 + (period['endMinute'] ?? 0);

      // Check if current time is within this period
      if (startMinutes <= endMinutes) {
        // Same day period
        if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
          return true;
        }
      } else {
        // Overnight period (rare for quiet time but handle it)
        if (currentMinutes >= startMinutes || currentMinutes < endMinutes) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get the reason for current restriction
  String _getRestrictionReason() {
    if (_isInSleepTime()) {
      return 'เวลานอน 🌙';
    }
    if (_isInQuietTime()) {
      return 'เวลาพักผ่อน 🔕';
    }
    if (_dailyTimeLimit > 0 && _currentLimitUsedTime >= _dailyTimeLimit) {
      return 'หมดเวลาใช้งาน ⏰';
    }
    return '';
  }

  Future<void> _checkForegroundApp() async {
    try {
      // Check Schedule Restrictions (Sleep Time & Quiet Time)
      final inSleep = _isInSleepTime();
      final inQuiet = _isInQuietTime();
      final isRestricted = inSleep || inQuiet;

      if (isRestricted || _isDeviceLocked) {
        if (!_isInRestrictedTime) {
          // Just entered restricted time
          _isInRestrictedTime = true;

          // Set isLocked in Firestore so parent can see unlock button
          final reason = _isDeviceLocked
              ? 'pause'
              : (inSleep ? 'sleep' : 'quiet');
          _setLockedInFirestore(true, reason);

          onBlockedAppDetected(
            _isDeviceLocked
                ? 'อุปกรณ์ถูกระงับชั่วคราว 🔒'
                : _getRestrictionReason(),
          );
        }

        // Auto-unlock check
        if (_isDeviceLocked &&
            _pauseUntil != null &&
            DateTime.now().isAfter(_pauseUntil!)) {
          _unlockDevice();
        }
        return; // Don't process further, device should be locked
      } else {
        if (_isInRestrictedTime) {
          // Just exited restricted time - update Firestore
          _isInRestrictedTime = false;
          _setLockedInFirestore(false, '');
          onAppAllowed();
        }
      }

      // Check Time Limit (skip if disabled by parent)
      final isTimeLimitDisabled =
          _timeLimitDisabledUntil != null &&
          DateTime.now().isBefore(_timeLimitDisabledUntil!);

      if (!isTimeLimitDisabled &&
          _dailyTimeLimit > 0 &&
          _currentLimitUsedTime >= _dailyTimeLimit) {
        // Set isLocked in Firestore so parent can see unlock button
        _setLockedInFirestore(true, 'time_limit');
        onTimeLimitReached();
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
      // Error checking usage stats
    }
  }

  Future<void> _updateScreenTime() async {
    // Don't count screen time during restricted periods
    if (_isInRestrictedTime) return;

    if (_currentChildId == null || _currentParentId == null) return;

    _sessionSeconds++;
    _currentLimitUsedTime++;

    // Update Firestore every 10 seconds to reduce writes
    if (_sessionSeconds % 10 == 0) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_currentParentId)
            .collection('children')
            .doc(_currentChildId);

        // 1. Update Realtime (Quick View) - both screenTime and limitUsedTime
        await docRef.update({
          'screenTime': FieldValue.increment(10), // For statistics
          'limitUsedTime': FieldValue.increment(10), // For limit checking
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
        // Error updating screen time
      }
    }
  }

  bool _isBlocked(String packageName) {
    return _blockedPackages.contains(packageName);
  }

  /// Get current schedule status for debugging/UI
  Map<String, dynamic> getScheduleStatus() {
    return {
      'sleepEnabled': _sleepScheduleEnabled,
      'bedtime': '$_bedtimeHour:$_bedtimeMinute',
      'wakeTime': '$_wakeHour:$_wakeMinute',
      'isInSleepTime': _isInSleepTime(),
      'quietTimesCount': _quietTimes.length,
      'isInQuietTime': _isInQuietTime(),
      'isRestricted': _isInRestrictedTime,
      'restrictionReason': _getRestrictionReason(),
    };
  }

  Future<void> _unlockDevice() async {
    if (_currentChildId == null || _currentParentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentParentId)
          .collection('children')
          .doc(_currentChildId)
          .update({'isLocked': false, 'pauseUntil': null});
      // Local state will be updated via listener
    } catch (e) {
      // Error unlocking device
    }
  }
}
