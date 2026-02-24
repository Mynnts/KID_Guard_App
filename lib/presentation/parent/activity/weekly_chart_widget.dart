import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'weekly_comparison_badge.dart';

/// Weekly bar chart card with app usage list below
class WeeklyChartWidget extends StatelessWidget {
  static const _primaryGreen = Color(0xFF6B9080);
  static const _secondaryGreen = Color(0xFF84A98C);
  static const _accentGreen = Color(0xFF10B981);
  static const _cardColor = Colors.white;

  final Map<String, double> screenTimeMap;
  final Map<String, dynamic> appsDataMap;
  final int selectedBarIndex;
  final bool showAllApps;
  final ValueChanged<int> onBarSelected;
  final VoidCallback onToggleShowAll;
  final Widget Function(String name, String packageName, double size)
  buildAppAvatar;
  final bool Function(String packageName) isSystemApp;

  const WeeklyChartWidget({
    super.key,
    required this.screenTimeMap,
    required this.appsDataMap,
    required this.selectedBarIndex,
    required this.showAllApps,
    required this.onBarSelected,
    required this.onToggleShowAll,
    required this.buildAppAvatar,
    required this.isSystemApp,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Build bar groups
    List<BarChartGroupData> barGroups = [];
    List<String> dayLabels = [];

    // Calculate maxY dynamically
    final maxHours = screenTimeMap.values.isNotEmpty
        ? screenTimeMap.values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final bool useMinutes = maxHours < 1.0;
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
      final dateStr = _getDateStr(d);
      final hours = screenTimeMap[dateStr] ?? 0.0;
      final barValue = useMinutes ? hours * 60 : hours;
      final xIndex = 6 - i;
      final isSelected = xIndex == selectedBarIndex;
      final isToday = i == 0;

      barGroups.add(
        BarChartGroupData(
          x: xIndex,
          barRods: [
            BarChartRodData(
              toY: barValue > 0 ? barValue : (chartMaxY * 0.02),
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [_primaryGreen, _secondaryGreen],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade200, Colors.grey.shade200],
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
    final selectedDate = now.subtract(Duration(days: 6 - selectedBarIndex));
    final selectedDateStr = _getDateStr(selectedDate);

    List<Map<String, dynamic>> appList = [];
    final appsForDay = appsDataMap[selectedDateStr];
    if (appsForDay != null && appsForDay is Map) {
      (appsForDay).forEach((key, value) {
        if (value is Map) {
          final pkg = (value['packageName'] ?? key).toString();
          if (!isSystemApp(pkg)) {
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
        _buildChartCard(
          barGroups,
          dayLabels,
          chartMaxY,
          chartInterval,
          useMinutes,
        ),
        const SizedBox(height: 20),
        _buildAppUsageSection(
          appList,
          maxDuration,
          totalDurationSec,
          selectedDate,
        ),
      ],
    );
  }

  Widget _buildChartCard(
    List<BarChartGroupData> barGroups,
    List<String> dayLabels,
    double maxY,
    double interval,
    bool useMinutes,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
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
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Weekly Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              WeeklyComparisonBadge(screenTimeMap: screenTimeMap),
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
                    if (selectedBarIndex != spotIndex) {
                      onBarSelected(spotIndex);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _primaryGreen,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
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
                          final isSelected = value.toInt() == selectedBarIndex;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              dayLabels[value.toInt()],
                              style: TextStyle(
                                color: isSelected
                                    ? _primaryGreen
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.apps_rounded,
                size: 18,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDateLabel(selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
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
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTotalTime(totalDurationSec),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryGreen,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (appList.isEmpty)
          _buildEmptyAppUsage()
        else
          _buildAppList(appList, maxDuration, totalDurationSec),
      ],
    );
  }

  Widget _buildEmptyAppUsage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
    final showCount = showAllApps
        ? appList.length
        : math.min(5, appList.length);
    final visibleApps = appList.take(showCount).toList();

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

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
          if (visibleApps.isNotEmpty)
            _buildTopAppItem(visibleApps[0], iconColors[0], totalDurationSec),
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
          if (appList.length > 5)
            InkWell(
              onTap: onToggleShowAll,
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
                      showAllApps
                          ? 'Show less'
                          : 'Show ${appList.length - 5} more',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      showAllApps
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: _primaryGreen,
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
          colors: [_primaryGreen.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          buildAppAvatar(app['name'] ?? '', app['package'] ?? '', 48),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
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
                        color: _accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Most Used',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
                        backgroundColor: Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _primaryGreen,
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
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _primaryGreen,
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
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          buildAppAvatar(app['name'] ?? '', app['package'] ?? '', 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1A1A2E),
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
                        backgroundColor: Colors.grey.shade100,
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

  // ─── Helpers ────────────────────────────────────────────
  String _getDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
