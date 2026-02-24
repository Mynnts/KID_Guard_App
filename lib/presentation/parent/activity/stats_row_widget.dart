import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguard/core/utils/responsive_helper.dart';
import 'package:kidguard/data/models/child_model.dart';

/// Stats row — today, average, peak
class StatsRowWidget extends StatelessWidget {
  static const _primaryGreen = Color(0xFF6B9080);
  static const _secondaryGreen = Color(0xFF84A98C);
  static const _accentGreen = Color(0xFF10B981);
  static const _cardColor = Colors.white;

  final ChildModel child;
  final String parentUid;

  const StatsRowWidget({
    super.key,
    required this.child,
    required this.parentUid,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final hours = child.screenTime ~/ 3600;
    final minutes = (child.screenTime % 3600) ~/ 60;

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
                r,
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
                r,
                icon: Icons.trending_up_rounded,
                label: 'Average',
                value: avgValue,
                color: _accentGreen,
              ),
            ),
            SizedBox(width: r.wp(10)),
            Expanded(
              child: _buildStatCard(
                r,
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

  Widget _buildStatCard(
    ResponsiveHelper r, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isPrimary = false,
  }) {
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
}
