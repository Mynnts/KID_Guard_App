import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../core/utils/responsive_helper.dart';

// Extracted widgets
import 'activity/activity_header_widget.dart';
import 'activity/activity_child_selector.dart';
import 'activity/online_status_card.dart';
import 'activity/stats_row_widget.dart';
import 'activity/weekly_chart_widget.dart';

/// Parent Activity Screen - displays screen time activity charts and app usage
class ParentActivityScreen extends StatefulWidget {
  const ParentActivityScreen({super.key});

  @override
  State<ParentActivityScreen> createState() => _ParentActivityScreenState();
}

class _ParentActivityScreenState extends State<ParentActivityScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedActivityChildId;
  int _selectedBarIndex = 6;
  Timer? _refreshTimer;
  bool _showAllApps = false;
  late AnimationController _pulseController;

  Future<Map<String, dynamic>>? _weeklyDataFuture;
  String? _lastFetchedChildId;

  static const _primaryGreen = Color(0xFF6B9080);
  static const _accentGreen = Color(0xFF10B981);

  static const _avatarColors = [
    Color(0xFF6B9080),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6C5CE7),
    Color(0xFFA8E6CF),
    Color(0xFFFF8A5C),
    Color(0xFF3D5A80),
    Color(0xFFE07A5F),
    Color(0xFF81B29A),
    Color(0xFFF4845F),
    Color(0xFF7209B7),
  ];

  static const _systemPackagePrefixes = [
    'com.android.',
    'com.google.android.inputmethod',
    'com.google.android.permissioncontroller',
    'com.google.android.gms',
    'com.google.android.gsf',
    'com.google.android.ext.',
    'com.google.android.providers.',
    'com.oppo.launcher',
    'com.oppo.',
    'com.coloros.',
    'com.samsung.android.lool',
    'com.samsung.android.app.routines',
    'com.samsung.android.incallui',
    'com.sec.android.',
    'com.miui.',
    'com.xiaomi.',
    'com.huawei.',
    'com.oplus.',
    'com.heytap.',
    'com.seniorproject.kid_guard',
  ];

  bool _isSystemApp(String packageName) {
    for (final prefix in _systemPackagePrefixes) {
      if (packageName.startsWith(prefix)) return true;
    }
    return false;
  }

  Widget _buildAppAvatar(String name, String packageName, double size) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colorIndex = packageName.hashCode.abs() % _avatarColors.length;
    final color = _avatarColors[colorIndex];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.45,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (authProvider.userModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authProvider.userModel!.uid)
              .collection('children')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final childrenDocs = snapshot.data!.docs;
            if (childrenDocs.isEmpty) return _buildEmptyChildren();

            final children = childrenDocs
                .map(
                  (doc) => ChildModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

            if (_selectedActivityChildId == null ||
                !children.any((c) => c.id == _selectedActivityChildId)) {
              _selectedActivityChildId = children.first.id;
            }

            final selectedChild = children.firstWhere(
              (c) => c.id == _selectedActivityChildId,
            );

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _weeklyDataFuture = null;
                  _lastFetchedChildId = null;
                });
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: _primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.of(context).wp(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: ResponsiveHelper.of(context).hp(16)),
                      const ActivityHeaderWidget(),
                      SizedBox(height: ResponsiveHelper.of(context).hp(20)),
                      ActivityChildSelector(
                        children: children,
                        selectedChildId: _selectedActivityChildId,
                        onChildSelected: (id) => setState(() {
                          _selectedActivityChildId = id;
                          _showAllApps = false;
                        }),
                      ),
                      SizedBox(height: ResponsiveHelper.of(context).hp(20)),
                      OnlineStatusCard(
                        child: selectedChild,
                        pulseAnimation: _pulseController,
                        onUnlockTap: () => _requestUnlock(selectedChild),
                      ),
                      SizedBox(height: ResponsiveHelper.of(context).hp(16)),
                      StatsRowWidget(
                        child: selectedChild,
                        parentUid: authProvider.userModel!.uid,
                      ),
                      SizedBox(height: ResponsiveHelper.of(context).hp(20)),
                      Builder(
                        builder: (context) {
                          final parentUid = authProvider.userModel!.uid;
                          final childId = _selectedActivityChildId!;
                          if (_weeklyDataFuture == null ||
                              _lastFetchedChildId != childId) {
                            _weeklyDataFuture = _fetchWeeklyData(
                              parentUid,
                              childId,
                            );
                            _lastFetchedChildId = childId;
                          }
                          return _buildChartSection(parentUid, childId);
                        },
                      ),
                      SizedBox(height: ResponsiveHelper.of(context).hp(100)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────
  Widget _buildEmptyChildren() {
    final r = ResponsiveHelper.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(r.wp(24)),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.child_care_rounded,
              size: r.iconSize(56),
              color: _primaryGreen.withOpacity(0.5),
            ),
          ),
          SizedBox(height: r.hp(20)),
          Text(
            'No children added yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: r.sp(16),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: r.hp(8)),
          Text(
            'Add a child to see activity data',
            style: TextStyle(color: Colors.grey[400], fontSize: r.sp(13)),
          ),
        ],
      ),
    );
  }

  // ─── Chart + App Usage Section ──────────────────────────
  Widget _buildChartSection(String parentUid, String childId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weeklyDataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                const SizedBox(height: 8),
                Text(
                  'Error loading data',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: _primaryGreen),
            ),
          );
        }

        final screenTimeMap = Map<String, double>.from(
          snapshot.data!['screenTimeMap'] as Map,
        );
        final appsDataMap = Map<String, dynamic>.from(
          snapshot.data!['appsDataMap'] as Map,
        );

        return WeeklyChartWidget(
          screenTimeMap: screenTimeMap,
          appsDataMap: appsDataMap,
          selectedBarIndex: _selectedBarIndex,
          showAllApps: _showAllApps,
          onBarSelected: (index) => setState(() {
            _selectedBarIndex = index;
            _showAllApps = false;
          }),
          onToggleShowAll: () => setState(() => _showAllApps = !_showAllApps),
          buildAppAvatar: _buildAppAvatar,
          isSystemApp: _isSystemApp,
        );
      },
    );
  }

  // ─── Data Fetching ────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchWeeklyData(
    String parentUid,
    String childId,
  ) async {
    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId);

    Map<String, double> screenTimeMap = {};
    Map<String, Map<String, dynamic>> appsDataMap = {};

    final futures = <Future<DocumentSnapshot>>[];
    final dateStrs = <String>[];

    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dateStrs.add(dateStr);
      futures.add(docRef.collection('daily_stats').doc(dateStr).get());
    }

    final results = await Future.wait(futures);

    for (int i = 0; i < results.length; i++) {
      final doc = results[i];
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final seconds = data['screenTime'] as int? ?? 0;
        screenTimeMap[dateStrs[i]] = seconds / 3600.0;

        if (data.containsKey('apps') && data['apps'] is Map) {
          appsDataMap[dateStrs[i]] = Map<String, dynamic>.from(
            data['apps'] as Map,
          );
        } else {
          final Map<String, Map<String, dynamic>> extractedApps = {};
          data.forEach((key, value) {
            if (key.startsWith('apps.')) {
              final withoutPrefix = key.substring(5);
              final dotIndex = withoutPrefix.indexOf('.');
              if (dotIndex > 0) {
                final appKey = withoutPrefix.substring(0, dotIndex);
                final field = withoutPrefix.substring(dotIndex + 1);
                extractedApps.putIfAbsent(appKey, () => {});
                extractedApps[appKey]![field] = value;
              }
            }
          });
          if (extractedApps.isNotEmpty) {
            appsDataMap[dateStrs[i]] = extractedApps.cast<String, dynamic>();
          }
        }
      }
    }

    return {'screenTimeMap': screenTimeMap, 'appsDataMap': appsDataMap};
  }

  // ─── Unlock Request ───────────────────────────────────────
  void _requestUnlock(ChildModel child) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parentUid = authProvider.userModel?.uid;
    if (parentUid == null) return;

    try {
      final now = DateTime.now();
      final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(child.id)
          .update({
            'unlockRequested': true,
            'timeLimitDisabledUntil': Timestamp.fromDate(tomorrowMidnight),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Unlock request sent'),
              ],
            ),
            backgroundColor: _accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send unlock request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
