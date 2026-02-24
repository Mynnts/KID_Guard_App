import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguard/data/models/child_model.dart';
import 'package:kidguard/logic/providers/auth_provider.dart';

/// Screen time stats card with progress ring and yesterday comparison
class StatsCardWidget extends StatelessWidget {
  final ChildModel? selectedChild;
  final int totalSeconds;
  final ColorScheme colorScheme;

  const StatsCardWidget({
    super.key,
    required this.selectedChild,
    required this.totalSeconds,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    final dailyLimit = selectedChild?.dailyTimeLimit ?? 0;
    double progress = 0.0;
    if (dailyLimit > 0) {
      progress = (totalSeconds / dailyLimit).clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B9080), Color(0xFF84A98C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B9080).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: const Color(0xFF6B9080).withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Screen Time Today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: hours),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Text(
                              '$value',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                letterSpacing: -2,
                              ),
                            );
                          },
                        ),
                        const Text(
                          'h',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: minutes),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Text(
                              '$value',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                letterSpacing: -2,
                              ),
                            );
                          },
                        ),
                        const Text(
                          'm',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Mini Chart
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CustomPaint(
                            painter: MiniProgressPainter(progress: value),
                          ),
                        ),
                        Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _YesterdayComparison(
            child: selectedChild,
            todaySeconds: totalSeconds,
          ),
        ],
      ),
    );
  }
}

/// Yesterday vs today comparison row
class _YesterdayComparison extends StatelessWidget {
  final ChildModel? child;
  final int todaySeconds;

  const _YesterdayComparison({required this.child, required this.todaySeconds});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox();

    final parentUid = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).userModel?.uid;
    if (parentUid == null) return const SizedBox();

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(child!.id)
          .collection('daily_stats')
          .doc(yesterdayStr)
          .get(),
      builder: (context, snapshot) {
        int yesterdaySeconds = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          yesterdaySeconds = data?['screenTime'] ?? 0;
        }

        String comparisonText;
        IconData icon;
        Color iconBgColor;

        if (yesterdaySeconds == 0) {
          comparisonText = 'No data from yesterday';
          icon = Icons.info_outline_rounded;
          iconBgColor = Colors.white.withOpacity(0.2);
        } else {
          final diff = todaySeconds - yesterdaySeconds;
          final percentage = ((diff.abs() / yesterdaySeconds) * 100).toInt();

          if (diff < 0) {
            comparisonText = '$percentage% less than yesterday';
            icon = Icons.trending_down_rounded;
            iconBgColor = const Color(0xFF10B981).withOpacity(0.3);
          } else if (diff > 0) {
            comparisonText = '$percentage% more than yesterday';
            icon = Icons.trending_up_rounded;
            iconBgColor = const Color(0xFFEF4444).withOpacity(0.3);
          } else {
            comparisonText = 'Same as yesterday';
            icon = Icons.remove_rounded;
            iconBgColor = Colors.white.withOpacity(0.2);
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  comparisonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mini circular progress ring painter
class MiniProgressPainter extends CustomPainter {
  final double progress;

  MiniProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MiniProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
