import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../core/utils/responsive_helper.dart';

/// Parent Activity Screen - displays screen time activity charts and app usage
/// หน้าจอแสดงสถิติการใช้งานหน้าจอ และแอพที่เด็กใช้ ฝั่งผู้ปกครอง
class ParentActivityScreen extends StatefulWidget {
  const ParentActivityScreen({super.key});

  @override
  State<ParentActivityScreen> createState() => _ParentActivityScreenState();
}

class _ParentActivityScreenState extends State<ParentActivityScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedActivityChildId;
  int _selectedBarIndex = 6; // Default to today (last bar)
  Timer? _refreshTimer;
  bool _showAllApps = false;
  late AnimationController _pulseController;

  // Cache สำหรับ FutureBuilder เพื่อไม่ให้ดึงข้อมูลซ้ำทุกครั้งที่ setState
  Future<Map<String, dynamic>>? _weeklyDataFuture;
  String? _lastFetchedChildId;

  // Color constants - will be replaced by theme in most places
  static const _primaryGreen = Color(0xFF6B9080);
  static const _secondaryGreen = Color(0xFF84A98C);
  static const _accentGreen = Color(0xFF10B981);
  static const _cardColor = Colors.white;

  // สีสำหรับ letter avatar — กำหนดตาม hash ของ package name
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

  // Package prefixes ของแอพระบบที่ไม่ต้องแสดง
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

  // ตรวจสอบว่าเป็นแอพระบบหรือไม่
  bool _isSystemApp(String packageName) {
    for (final prefix in _systemPackagePrefixes) {
      if (packageName.startsWith(prefix)) return true;
    }
    return false;
  }

  // สร้าง letter avatar widget
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
            if (childrenDocs.isEmpty) {
              return _buildEmptyChildren();
            }

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
                      _buildHeader(),
                      SizedBox(height: ResponsiveHelper.of(context).hp(20)),
                      _buildChildSelector(children),
                      SizedBox(height: ResponsiveHelper.of(context).hp(20)),
                      _buildOnlineStatusCard(selectedChild),
                      SizedBox(height: ResponsiveHelper.of(context).hp(16)),
                      _buildStatsRow(selectedChild),
                      SizedBox(height: ResponsiveHelper.of(context).hp(20)),
                      Builder(
                        builder: (context) {
                          final parentUid = authProvider.userModel!.uid;
                          final childId = _selectedActivityChildId!;
                          // สร้าง future ใหม่เมื่อเปลี่ยนเด็ก หรือยังไม่เคยดึง
                          if (_weeklyDataFuture == null ||
                              _lastFetchedChildId != childId) {
                            _weeklyDataFuture = _fetchWeeklyData(
                              parentUid,
                              childId,
                            );
                            _lastFetchedChildId = childId;
                          }
                          return _buildChartAndApps(parentUid, childId);
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

  // ─── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    final r = ResponsiveHelper.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity',
                style: TextStyle(
                  fontSize: r.sp(28),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              SizedBox(height: r.hp(2)),
              Text(
                'Screen time & app usage insights',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: r.wp(14),
            vertical: r.hp(10),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(r.radius(14)),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: r.iconSize(15),
                color: _primaryGreen,
              ),
              SizedBox(width: r.wp(6)),
              Text(
                'This Week',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: r.sp(13),
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Child Selector ───────────────────────────────────────
  Widget _buildChildSelector(List<ChildModel> children) {
    final r = ResponsiveHelper.of(context);
    return SizedBox(
      height: r.hp(48),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(width: r.wp(10)),
        itemBuilder: (context, index) {
          final child = children[index];
          final isSelected = child.id == _selectedActivityChildId;
          final isOnline =
              child.lastActive != null &&
              DateTime.now().difference(child.lastActive!).inMinutes < 2;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedActivityChildId = child.id;
              _showAllApps = false;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: r.wp(16)),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_primaryGreen, _secondaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : _cardColor,
                borderRadius: BorderRadius.circular(r.radius(24)),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey.shade200),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: r.wp(15),
                        backgroundColor: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : _primaryGreen.withOpacity(0.1),
                        child: Text(
                          child.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : _primaryGreen,
                          ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: r.wp(10),
                            height: r.wp(10),
                            decoration: BoxDecoration(
                              color: _accentGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? _primaryGreen : _cardColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: r.wp(8)),
                  Text(
                    child.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(14),
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Online Status Card ───────────────────────────────────
  Widget _buildOnlineStatusCard(ChildModel child) {
    final r = ResponsiveHelper.of(context);
    final isOnline =
        child.lastActive != null &&
        DateTime.now().difference(child.lastActive!).inMinutes < 2;

    String onlineDuration = '';
    if (isOnline && child.sessionStartTime != null) {
      final diff = DateTime.now().difference(child.sessionStartTime!);
      if (diff.inHours > 0) {
        onlineDuration = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
      } else if (diff.inMinutes > 0) {
        onlineDuration = '${diff.inMinutes} min';
      } else {
        onlineDuration = 'Just now';
      }
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(r.wp(16)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(r.radius(20)),
        border: Border.all(
          color: isOnline
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulse indicator
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: r.wp(44),
                height: r.wp(44),
                decoration: BoxDecoration(
                  color: isOnline
                      ? _accentGreen.withOpacity(
                          0.08 + _pulseController.value * 0.05,
                        )
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(r.radius(14)),
                ),
                child: Center(
                  child: Container(
                    width: isOnline
                        ? r.wp(14) + (_pulseController.value * 2)
                        : r.wp(14),
                    height: isOnline
                        ? r.wp(14) + (_pulseController.value * 2)
                        : r.wp(14),
                    decoration: BoxDecoration(
                      color: isOnline ? _accentGreen : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: _accentGreen.withOpacity(
                                  0.4 - _pulseController.value * 0.2,
                                ),
                                blurRadius: 8,
                                spreadRadius: _pulseController.value * 3,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: r.wp(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Online Now' : 'Offline',
                  style: TextStyle(
                    fontSize: r.sp(15),
                    fontWeight: FontWeight.w700,
                    color: isOnline ? _accentGreen : Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: r.hp(2)),
                Text(
                  isOnline && onlineDuration.isNotEmpty
                      ? 'Active for $onlineDuration'
                      : child.lastActive != null
                      ? 'Last seen ${_formatLastActive(child.lastActive!)}'
                      : 'Never connected',
                  style: TextStyle(
                    fontSize: r.sp(12),
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (isOnline)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.wp(10),
                vertical: r.hp(5),
              ),
              decoration: BoxDecoration(
                color: _accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(r.radius(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: r.wp(6),
                    height: r.wp(6),
                    decoration: const BoxDecoration(
                      color: _accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: r.wp(4)),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: r.sp(10),
                      fontWeight: FontWeight.w800,
                      color: _accentGreen,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          if (!isOnline || child.isLocked)
            GestureDetector(
              onTap: () => _requestUnlock(child),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.wp(12),
                  vertical: r.hp(6),
                ),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_open_rounded,
                      size: r.iconSize(14),
                      color: _primaryGreen,
                    ),
                    SizedBox(width: r.wp(4)),
                    Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: r.sp(11),
                        fontWeight: FontWeight.w700,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────
  Widget _buildStatsRow(ChildModel child) {
    final r = ResponsiveHelper.of(context);
    final hours = child.screenTime ~/ 3600;
    final minutes = (child.screenTime % 3600) ~/ 60;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parentUid = authProvider.userModel?.uid ?? '';

    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateWeeklyStats(parentUid, child.id),
      builder: (context, snapshot) {
        String avgValue = '--';
        String peakValue = '--';

        if (snapshot.hasData) {
          final data = snapshot.data!;
          final avgSeconds = data['averageSeconds'] as int? ?? 0;
          final avgH = avgSeconds ~/ 3600;
          final avgM = (avgSeconds % 3600) ~/ 60;
          avgValue = '${avgH}h ${avgM}m';
          peakValue = data['peakTime'] as String? ?? '--';
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.access_time_rounded,
                label: 'Today',
                value: '${hours}h ${minutes}m',
                color: _primaryGreen,
                isPrimary: true,
              ),
            ),
            SizedBox(width: r.wp(10)),
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up_rounded,
                label: 'Average',
                value: avgValue,
                color: _accentGreen,
              ),
            ),
            SizedBox(width: r.wp(10)),
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule_rounded,
                label: 'Peak',
                value: peakValue,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isPrimary = false,
  }) {
    final r = ResponsiveHelper.of(context);
    return Container(
      padding: EdgeInsets.all(r.wp(14)),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [_primaryGreen, _secondaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPrimary ? null : _cardColor,
        borderRadius: BorderRadius.circular(r.radius(20)),
        border: isPrimary ? null : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? _primaryGreen.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: isPrimary ? 20 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(r.wp(6)),
            decoration: BoxDecoration(
              color: isPrimary
                  ? Colors.white.withOpacity(0.2)
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(r.radius(8)),
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: r.iconSize(16),
            ),
          ),
          SizedBox(height: r.hp(10)),
          Text(
            value,
            style: TextStyle(
              fontSize: r.sp(17),
              fontWeight: FontWeight.w800,
              color: isPrimary ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: r.hp(2)),
          Text(
            label,
            style: TextStyle(
              fontSize: r.sp(11),
              fontWeight: FontWeight.w500,
              color: isPrimary ? Colors.white60 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: แปลง DateTime เป็น YYYY-MM-DD string
  String _getDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─── Weekly Chart + Apps ──────────────────────────────────
  // ดึงข้อมูล daily_stats 7 วันย้อนหลังโดยใช้ document ID (YYYY-MM-DD) โดยตรง
  // แทนการใช้ orderBy('timestamp') ที่ต้องการ Firestore Index
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

    // ดึงข้อมูล 7 วันย้อนหลังพร้อมกัน
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

        // ลอง 2 รูปแบบ: nested map หรือ flat dot-notation keys
        if (data.containsKey('apps') && data['apps'] is Map) {
          // รูปแบบ 1: Nested map — data['apps'] = {'com_facebook_katana': {'name': 'Facebook', ...}}
          appsDataMap[dateStrs[i]] = Map<String, dynamic>.from(
            data['apps'] as Map,
          );
        } else {
          // รูปแบบ 2: Flat dot-notation keys — 'apps.com_facebook_katana.duration': 6
          final Map<String, Map<String, dynamic>> extractedApps = {};
          data.forEach((key, value) {
            if (key.startsWith('apps.')) {
              // key = 'apps.com_facebook_katana.duration'
              final withoutPrefix = key.substring(
                5,
              ); // 'com_facebook_katana.duration'
              final dotIndex = withoutPrefix.indexOf('.');
              if (dotIndex > 0) {
                final appKey = withoutPrefix.substring(
                  0,
                  dotIndex,
                ); // 'com_facebook_katana'
                final field = withoutPrefix.substring(
                  dotIndex + 1,
                ); // 'duration'
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

  Widget _buildChartAndApps(String parentUid, String childId) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<Map<String, dynamic>>(
      future: _weeklyDataFuture,
      builder: (context, snapshot) {
        // Error handling
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

        // Build bar groups
        List<BarChartGroupData> barGroups = [];
        List<String> dayLabels = [];
        final now = DateTime.now();

        // Auto-select วันล่าสุดที่มีข้อมูล ถ้าวันที่เลือกไม่มีข้อมูล
        final latestDataIndex = snapshot.data!['latestDataIndex'] as int? ?? 6;
        final currentDateStr = _getDateStr(
          now.subtract(Duration(days: 6 - _selectedBarIndex)),
        );
        if (!screenTimeMap.containsKey(currentDateStr) &&
            screenTimeMap.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedBarIndex != latestDataIndex) {
              setState(() => _selectedBarIndex = latestDataIndex);
            }
          });
        }

        final selectedDate = now.subtract(
          Duration(days: 6 - _selectedBarIndex),
        );
        final selectedDateStr = _getDateStr(selectedDate);

        // คำนวณ maxY แบบ dynamic จากข้อมูลจริง
        final maxHours = screenTimeMap.values.isNotEmpty
            ? screenTimeMap.values.reduce((a, b) => a > b ? a : b)
            : 0.0;
        final bool useMinutes =
            maxHours < 1.0; // ถ้าใช้ไม่ถึง 1 ชม. แสดงเป็นนาที
        double chartMaxY;
        double chartInterval;

        if (useMinutes) {
          final maxMinutes = maxHours * 60;
          if (maxMinutes <= 5) {
            chartMaxY = 5;
            chartInterval = 1;
          } else if (maxMinutes <= 15) {
            chartMaxY = 15;
            chartInterval = 5;
          } else if (maxMinutes <= 30) {
            chartMaxY = 30;
            chartInterval = 10;
          } else {
            chartMaxY = 60;
            chartInterval = 15;
          }
        } else {
          if (maxHours <= 2) {
            chartMaxY = 2;
            chartInterval = 0.5;
          } else if (maxHours <= 4) {
            chartMaxY = 4;
            chartInterval = 1;
          } else if (maxHours <= 8) {
            chartMaxY = 8;
            chartInterval = 2;
          } else {
            chartMaxY = 12;
            chartInterval = 4;
          }
        }

        for (int i = 6; i >= 0; i--) {
          final d = now.subtract(Duration(days: i));
          final dateStr =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final hours = screenTimeMap[dateStr] ?? 0.0;
          final barValue = useMinutes ? hours * 60 : hours;
          final xIndex = 6 - i;
          final isSelected = xIndex == _selectedBarIndex;
          final isToday = i == 0;

          barGroups.add(
            BarChartGroupData(
              x: xIndex,
              barRods: [
                BarChartRodData(
                  toY: barValue > 0 ? barValue : (chartMaxY * 0.02),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        )
                      : LinearGradient(
                          colors: [
                            colorScheme.outline.withOpacity(0.1),
                            colorScheme.outline.withOpacity(0.1),
                          ],
                        ),
                  width: 28,
                  borderRadius: BorderRadius.circular(10),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartMaxY,
                    color: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          );

          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          dayLabels.add(isToday ? 'Today' : days[d.weekday - 1]);
        }

        // Build app list for selected day
        List<Map<String, dynamic>> appList = [];
        final appsForDay = appsDataMap[selectedDateStr];
        if (appsForDay != null && appsForDay is Map) {
          (appsForDay).forEach((key, value) {
            if (value is Map) {
              final pkg = (value['packageName'] ?? key).toString();
              // กรองแอพระบบออก
              if (!_isSystemApp(pkg)) {
                appList.add({
                  'name': value['name'] ?? 'Unknown',
                  'duration': value['duration'] ?? 0,
                  'package': pkg,
                });
              }
            }
          });
          appList.sort(
            (a, b) => (b['duration'] as int).compareTo(a['duration'] as int),
          );
        }

        final maxDuration = appList.isNotEmpty
            ? appList
                  .map((a) => a['duration'] as int)
                  .reduce((a, b) => a > b ? a : b)
            : 1;

        final totalDurationSec = appList.fold<int>(
          0,
          (sum, app) => sum + (app['duration'] as int),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Card
            _buildChartCard(
              barGroups,
              dayLabels,
              screenTimeMap,
              chartMaxY,
              chartInterval,
              useMinutes,
            ),
            const SizedBox(height: 20),
            // App Usage Section
            _buildAppUsageSection(
              appList,
              maxDuration,
              totalDurationSec,
              selectedDate,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartCard(
    List<BarChartGroupData> barGroups,
    List<String> dayLabels,
    Map<String, double> screenTimeMap,
    double maxY,
    double interval,
    bool useMinutes,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Weekly Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _buildWeeklyComparisonBadge(screenTimeMap),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null)
                      return;
                    final spotIndex =
                        barTouchResponse.spot!.touchedBarGroupIndex;
                    if (_selectedBarIndex != spotIndex) {
                      setState(() {
                        _selectedBarIndex = spotIndex;
                        _showAllApps = false;
                      });
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.primary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      // แสดง tooltip ตามหน่วยที่ใช้
                      String tip;
                      if (useMinutes) {
                        final mins = rod.toY;
                        if (mins < 1) {
                          tip = '${(mins * 60).toInt()}s';
                        } else {
                          tip = '${mins.toStringAsFixed(1)}m';
                        }
                      } else {
                        tip = '${rod.toY.toStringAsFixed(1)}h';
                      }
                      return BarTooltipItem(
                        tip,
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        // ไม่แสดง label ที่ 0
                        if (value == 0) return const SizedBox();
                        String label;
                        if (useMinutes) {
                          label = '${value.toInt()}m';
                        } else {
                          label = value == value.toInt()
                              ? '${value.toInt()}h'
                              : '${value.toStringAsFixed(1)}h';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dayLabels.length) {
                          final isSelected = value.toInt() == _selectedBarIndex;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              dayLabels[value.toInt()],
                              style: TextStyle(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.grey[400],
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Usage Section ────────────────────────────────────
  Widget _buildAppUsageSection(
    List<Map<String, dynamic>> appList,
    int maxDuration,
    int totalDurationSec,
    DateTime selectedDate,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.apps_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDateLabel(selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (appList.isNotEmpty)
                    Text(
                      '${appList.length} app${appList.length > 1 ? 's' : ''} used',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (appList.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTotalTime(totalDurationSec),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // App list or empty state
        if (appList.isEmpty)
          _buildEmptyAppUsage()
        else
          _buildAppList(appList, maxDuration, totalDurationSec),
      ],
    );
  }

  Widget _buildEmptyAppUsage() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_android_rounded,
              size: 36,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No app usage data',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'App usage will appear after the child\nuses their device on this day',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList(
    List<Map<String, dynamic>> appList,
    int maxDuration,
    int totalDurationSec,
  ) {
    final showCount = _showAllApps
        ? appList.length
        : math.min(5, appList.length);
    final visibleApps = appList.take(showCount).toList();

    // App icon colors based on index
    final iconColors = [
      _primaryGreen,
      _accentGreen,
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF14B8A6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFFD97706),
    ];

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Most Used App badge (first item)
          if (visibleApps.isNotEmpty)
            _buildTopAppItem(visibleApps[0], iconColors[0], totalDurationSec),

          // Remaining apps
          ...List.generate(
            visibleApps.length > 1 ? visibleApps.length - 1 : 0,
            (i) {
              final app = visibleApps[i + 1];
              final colorIndex = (i + 1) % iconColors.length;
              return _buildAppItem(
                app,
                iconColors[colorIndex],
                maxDuration,
                totalDurationSec,
                i + 1 == visibleApps.length - 1,
              );
            },
          ),

          // Show more / less button
          if (appList.length > 5)
            InkWell(
              onTap: () => setState(() => _showAllApps = !_showAllApps),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAllApps
                          ? 'Show less'
                          : 'Show ${appList.length - 5} more',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAllApps
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopAppItem(
    Map<String, dynamic> app,
    Color color,
    int totalDuration,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = Duration(seconds: app['duration'] as int);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final percentage = totalDuration > 0
        ? ((app['duration'] as int) / totalDuration * 100).toInt()
        : 0;

    String timeStr = '';
    if (hours > 0) {
      timeStr = '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      timeStr = '${minutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      timeStr = '${duration.inSeconds}s';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // App icon — letter avatar
          _buildAppAvatar(app['name'] ?? '', app['package'] ?? '', 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        app['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Most Used',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: percentage / 100),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: colorScheme.outline.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem(
    Map<String, dynamic> app,
    Color color,
    int maxDuration,
    int totalDuration,
    bool isLast,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = Duration(seconds: app['duration'] as int);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final progress = (app['duration'] as int) / maxDuration;
    final percentage = totalDuration > 0
        ? ((app['duration'] as int) / totalDuration * 100).toInt()
        : 0;

    String timeStr = '';
    if (hours > 0) {
      timeStr = '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      timeStr = '${minutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      timeStr = '${duration.inSeconds}s';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
              ),
      ),
      child: Row(
        children: [
          // App icon — letter avatar
          _buildAppAvatar(app['name'] ?? '', app['package'] ?? '', 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0.02, 1.0)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: colorScheme.outline.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          color.withOpacity(0.7),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Weekly Comparison Badge ──────────────────────────────
  Widget _buildWeeklyComparisonBadge(Map<String, double> screenTimeMap) {
    double thisWeekTotal = 0;
    int daysWithData = 0;

    screenTimeMap.forEach((dateStr, hours) {
      thisWeekTotal += hours;
      if (hours > 0) daysWithData++;
    });

    if (daysWithData < 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Not enough data',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    final avgHours = thisWeekTotal / daysWithData;
    final todayHours = screenTimeMap.values.isNotEmpty
        ? screenTimeMap.values.last
        : 0.0;

    final diff = todayHours - avgHours;
    final percentage = avgHours > 0
        ? ((diff.abs() / avgHours) * 100).toInt()
        : 0;

    IconData icon;
    Color color;
    String text;

    if (diff < -0.1) {
      icon = Icons.trending_down_rounded;
      color = _accentGreen;
      text = '$percentage% less';
    } else if (diff > 0.1) {
      icon = Icons.trending_up_rounded;
      color = const Color(0xFFEF4444);
      text = '$percentage% more';
    } else {
      icon = Icons.remove_rounded;
      color = Colors.grey;
      text = 'Same as avg';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper Methods ───────────────────────────────────────

  Future<Map<String, dynamic>> _calculateWeeklyStats(
    String parentUid,
    String childId,
  ) async {
    final now = DateTime.now();
    int totalSeconds = 0;
    int daysWithData = 0;

    for (int i = 1; i <= 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(parentUid)
            .collection('children')
            .doc(childId)
            .collection('daily_stats')
            .doc(dateStr)
            .get();

        if (doc.exists) {
          final screenTime = doc.get('screenTime') ?? 0;
          totalSeconds += screenTime as int;
          daysWithData++;
        }
      } catch (e) {
        // Ignore errors for missing days
      }
    }

    final avgSeconds = daysWithData > 0 ? totalSeconds ~/ daysWithData : 0;
    String peakTime = daysWithData > 0 ? '3-5 PM' : '--';

    return {'averageSeconds': avgSeconds, 'peakTime': peakTime};
  }

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

  String _formatLastActive(DateTime lastActive) {
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _formatTotalTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m total';
    if (m > 0) return '${m}m ${s}s total';
    return '${s}s total';
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return "Today's Activity";
    if (d == today.subtract(const Duration(days: 1))) {
      return "Yesterday's Activity";
    }

    final weekDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return "${weekDays[date.weekday - 1]}'s Activity";
  }
}
