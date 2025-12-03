import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackgroundService {
  Timer? _monitorTimer;
  bool _isMonitoring = false;
  String? _currentChildId;
  String? _currentParentId;
  int _sessionSeconds = 0;

  // Dynamic blocklist
  Set<String> _blockedPackages = {};
  StreamSubscription? _blocklistSubscription;

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
        // We can return here if we want to block EVERYTHING,
        // but usually we still want to check for specific blocked apps
        // if the time limit overlay isn't full screen or if we want to be double sure.
        // For now, let's assume onTimeLimitReached handles the blocking UI.
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
    // Optimistic local update for immediate feedback
    _currentScreenTime++;

    // Update Firestore every 10 seconds to reduce writes
    if (_sessionSeconds % 10 == 0) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_currentParentId)
            .collection('children')
            .doc(_currentChildId);

        await docRef.update({
          'screenTime': FieldValue.increment(10),
          'lastActive': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating screen time: $e');
      }
    }
  }

  bool _isBlocked(String packageName) {
    return _blockedPackages.contains(packageName);
  }
}
