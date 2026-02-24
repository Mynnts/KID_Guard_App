import 'package:flutter/material.dart';
import 'package:kidguard/core/utils/responsive_helper.dart';
import 'package:kidguard/data/models/child_model.dart';
import 'package:kidguard/data/models/notification_model.dart';
import 'package:kidguard/data/services/notification_service.dart';
import 'package:kidguard/presentation/parent/account_profile_screen.dart';
import 'notifications_sheet.dart';

/// Header widget — greeting, notification bell, profile avatar
class HomeHeaderWidget extends StatelessWidget {
  final String userName;
  final String greeting;
  final ColorScheme colorScheme;
  final List<ChildModel> children;
  final String userId;

  const HomeHeaderWidget({
    super.key,
    required this.userName,
    required this.greeting,
    required this.colorScheme,
    required this.children,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final notificationService = NotificationService();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: r.sp(15),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: r.hp(6)),
              Text(
                userName,
                style: TextStyle(
                  fontSize: r.sp(26),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        // Notification Bell
        StreamBuilder<List<NotificationModel>>(
          stream: notificationService.getNotifications(userId),
          builder: (context, snapshot) {
            final hasUnread = snapshot.data?.any((n) => !n.isRead) ?? false;

            return GestureDetector(
              onTap: () => showNotificationsSheet(context, userId),
              child: Container(
                padding: EdgeInsets.all(r.wp(12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(r.radius(16)),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.grey.shade600,
                      size: r.iconSize(24),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: r.wp(8),
                          height: r.wp(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(width: r.wp(12)),
        // Profile Avatar
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountProfileScreen()),
          ),
          child: Container(
            width: r.wp(48),
            height: r.wp(48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r.radius(16)),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.8),
                  colorScheme.tertiary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: r.sp(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
