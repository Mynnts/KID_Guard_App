import 'package:flutter/material.dart';

/// Weekly comparison badge showing today vs average
class WeeklyComparisonBadge extends StatelessWidget {
  static const _accentGreen = Color(0xFF10B981);

  final Map<String, double> screenTimeMap;

  const WeeklyComparisonBadge({super.key, required this.screenTimeMap});

  @override
  Widget build(BuildContext context) {
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
}
