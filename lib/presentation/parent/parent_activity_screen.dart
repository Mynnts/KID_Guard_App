import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';

/// Parent Activity Screen - displays screen time activity charts and app usage
class ParentActivityScreen extends StatefulWidget {
  const ParentActivityScreen({super.key});

  @override
  State<ParentActivityScreen> createState() => _ParentActivityScreenState();
}

class _ParentActivityScreenState extends State<ParentActivityScreen> {
  String? _selectedActivityChildId;
  int _selectedBarIndex = 6;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Timer to refresh online duration every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.userModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No children added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
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

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activity',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Screen time insights',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'This Week',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Child Chips
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: children.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final child = children[index];
                        final isSelected = child.id == _selectedActivityChildId;
                        return GestureDetector(
                          onTap: () => setState(
                            () => _selectedActivityChildId = child.id,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF667EEA,
                                        ).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                  child: Text(
                                    child.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  child.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Realtime Online Status Card
                  _buildOnlineStatusCard(selectedChild),

                  const SizedBox(height: 20),

                  // Stats Summary Cards
                  _buildActivityStatsCards(selectedChild),

                  const SizedBox(height: 24),

                  // Chart Section
                  _buildEnhancedActivityChart(
                    authProvider.userModel!.uid,
                    _selectedActivityChildId!,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOnlineStatusCard(ChildModel child) {
    // Calculate online status from lastActive (within 2 minutes)
    final isOnline =
        child.lastActive != null &&
        DateTime.now().difference(child.lastActive!).inMinutes < 2;

    // Calculate online duration from sessionStartTime
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF10B981).withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Status Indicator
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Online Now' : 'Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline && onlineDuration.isNotEmpty
                      ? 'Active for $onlineDuration'
                      : child.lastActive != null
                      ? 'Last seen ${_formatLastActive(child.lastActive!)}'
                      : 'Never connected',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Live Badge
          if (isOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    size: 8,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          // Unlock Button (when time limit reached or locked)
          if (!isOnline || child.isLocked)
            GestureDetector(
              onTap: () => _requestUnlock(child),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_open_rounded,
                      size: 16,
                      color: Color(0xFF667EEA),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667EEA),
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

  void _requestUnlock(ChildModel child) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parentUid = authProvider.userModel?.uid;

    if (parentUid == null) return;

    try {
      // Calculate tomorrow midnight for auto-reset
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
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Unlock request sent'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
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

  Widget _buildActivityStatsCards(ChildModel child) {
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
              child: _buildActivityStatCard(
                icon: Icons.access_time_rounded,
                label: 'Today',
                value: '${hours}h ${minutes}m',
                color: const Color(0xFF667EEA),
                gradient: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityStatCard(
                icon: Icons.trending_up_rounded,
                label: 'Average',
                value: avgValue,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityStatCard(
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

  Future<Map<String, dynamic>> _calculateWeeklyStats(
    String parentUid,
    String childId,
  ) async {
    // Fetch last 7 days of daily_stats
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
          final screenTime = doc.get('totalScreenTime') ?? 0;
          totalSeconds += screenTime as int;
          daysWithData++;

          // Get hourly breakdown if available
          final appUsage = doc.data()?['appUsage'] as Map<String, dynamic>?;
          if (appUsage != null) {
            // Assume peak usage based on total for now
            // In real implementation, you'd track hourly data
          }
        }
      } catch (e) {
        // Ignore errors for missing days
      }
    }

    // Calculate average
    final avgSeconds = daysWithData > 0 ? totalSeconds ~/ daysWithData : 0;

    // Estimate peak time (afternoon is common for kids)
    // In a full implementation, this would come from hourly tracking
    String peakTime = daysWithData > 0 ? '3-5 PM' : '--';

    return {'averageSeconds': avgSeconds, 'peakTime': peakTime};
  }

  Widget _buildWeeklyComparisonBadge(Map<String, double> screenTimeMap) {
    // Calculate this week's total vs compare with available data
    double thisWeekTotal = 0;
    int daysWithData = 0;

    screenTimeMap.forEach((dateStr, hours) {
      thisWeekTotal += hours;
      if (hours > 0) daysWithData++;
    });

    // Calculate estimated comparison (vs average)
    if (daysWithData < 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Not enough data',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Calculate trend (compare latest day vs average)
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
      icon = Icons.trending_down;
      color = const Color(0xFF10B981);
      text = '$percentage% less';
    } else if (diff > 0.1) {
      icon = Icons.trending_up;
      color = const Color(0xFFEF4444);
      text = '$percentage% more';
    } else {
      icon = Icons.remove;
      color = Colors.grey;
      text = 'Same as avg';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool gradient = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient
            ? const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradient ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient
                ? const Color(0xFF667EEA).withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: gradient ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gradient ? Colors.white70 : color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: gradient ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: gradient ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActivityChart(String parentUid, String childId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .collection('daily_stats')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        Map<String, double> screenTimeMap = {};
        Map<String, Map<String, dynamic>> appsDataMap = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final seconds = data['screenTime'] as int? ?? 0;
          screenTimeMap[doc.id] = seconds / 3600.0;
          if (data.containsKey('apps')) {
            appsDataMap[doc.id] = data['apps'] as Map<String, dynamic>;
          }
        }

        List<BarChartGroupData> barGroups = [];
        List<String> dayLabels = [];
        final now = DateTime.now();

        final selectedDate = now.subtract(
          Duration(days: 6 - _selectedBarIndex),
        );
        final selectedDateStr = selectedDate.toIso8601String().split('T')[0];

        for (int i = 6; i >= 0; i--) {
          final d = now.subtract(Duration(days: i));
          final dateStr = d.toIso8601String().split('T')[0];
          final hours = screenTimeMap[dateStr] ?? 0.0;
          final xIndex = 6 - i;
          final isSelected = xIndex == _selectedBarIndex;

          barGroups.add(
            BarChartGroupData(
              x: xIndex,
              barRods: [
                BarChartRodData(
                  toY: hours > 0 ? hours : 0.2,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        )
                      : LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade200],
                        ),
                  width: 32,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          );

          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          dayLabels.add(days[d.weekday - 1]);
        }

        List<Map<String, dynamic>> appList = [];
        final appsForDay = appsDataMap[selectedDateStr];
        if (appsForDay != null) {
          appsForDay.forEach((key, value) {
            if (value is Map) {
              appList.add({
                'name': value['name'] ?? 'Unknown',
                'duration': value['duration'] ?? 0,
                'package': value['packageName'],
              });
            }
          });
          appList.sort(
            (a, b) => (b['duration'] as int).compareTo(a['duration'] as int),
          );
        }

        // Calculate max duration for progress bar
        final maxDuration = appList.isNotEmpty
            ? appList
                  .map((a) => a['duration'] as int)
                  .reduce((a, b) => a > b ? a : b)
            : 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Weekly Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _buildWeeklyComparisonBadge(screenTimeMap),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        barTouchData: BarTouchData(
                          touchCallback:
                              (FlTouchEvent event, barTouchResponse) {
                                if (!event.isInterestedForInteractions ||
                                    barTouchResponse == null ||
                                    barTouchResponse.spot == null)
                                  return;
                                final spotIndex =
                                    barTouchResponse.spot!.touchedBarGroupIndex;
                                if (_selectedBarIndex != spotIndex) {
                                  setState(() => _selectedBarIndex = spotIndex);
                                }
                              },
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => const Color(0xFF667EEA),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toStringAsFixed(1)}h',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade100,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 4,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}h',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
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
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < dayLabels.length) {
                                  final isSelected =
                                      value.toInt() == _selectedBarIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      dayLabels[value.toInt()],
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF667EEA)
                                            : Colors.grey,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 12,
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
                        maxY: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Apps List Section
            Row(
              children: [
                Text(
                  _getDateLabel(selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (appList.isNotEmpty)
                  Text(
                    '${appList.length} apps',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            if (appList.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No usage data',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...appList.take(5).map((app) {
                final duration = Duration(seconds: app['duration'] as int);
                final hours = duration.inHours;
                final minutes = duration.inMinutes.remainder(60);
                final progress = (app['duration'] as int) / maxDuration;

                String timeStr = '';
                if (hours > 0) timeStr += '${hours}h ';
                timeStr += '${minutes}m';
                if (hours == 0 && minutes == 0) timeStr = '< 1m';

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.android,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Progress bar
                              Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress.clamp(0.05, 1.0),
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF667EEA),
                                            Color(0xFF764BA2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
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
