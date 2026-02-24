import 'package:flutter/material.dart';
import 'package:kidguard/core/utils/responsive_helper.dart';

/// Activity screen header with title and "This Week" pill
class ActivityHeaderWidget extends StatelessWidget {
  static const _primaryGreen = Color(0xFF6B9080);
  static const _cardColor = Colors.white;

  const ActivityHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFF1A1A2E),
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
            color: _cardColor,
            borderRadius: BorderRadius.circular(r.radius(14)),
            border: Border.all(color: Colors.grey.shade200),
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
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
