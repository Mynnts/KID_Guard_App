import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../core/utils/responsive_helper.dart';
import 'account_profile_screen.dart';
import 'child_setup_screen.dart';
import 'time_limit_screen.dart';
import 'child_location_screen.dart';
import 'schedule_screen.dart';
import 'parent_rewards_screen.dart';
import 'all_children_screen.dart';
import 'apps/parent_app_control_screen.dart';

import 'package:kidguard/l10n/app_localizations.dart';
import 'package:kidguard/data/models/notification_model.dart';
import 'package:kidguard/data/services/notification_service.dart';

/// Parent Home Screen - displays children overview, stats, and quick actions
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with TickerProviderStateMixin {
  int? _selectedChildIndex;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.goodMorning;
    if (hour < 17) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final colorScheme = Theme.of(context).colorScheme;
    final userName = user?.displayName ?? 'Parent';
    final r = ResponsiveHelper.of(context);

    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildShimmerLoading();
        }

        final childrenDocs = snapshot.data!.docs;
        final children = childrenDocs
            .map(
              (doc) => ChildModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Ensure notifications are seeded for these children if needed
        if (children.isNotEmpty) {
          _checkAndSeedNotifications(user.uid, children);
        }

        // Set default selected child
        if (_selectedChildIndex == null && children.isNotEmpty) {
          _selectedChildIndex = 0;
        }

        final selectedChild = children.isNotEmpty && _selectedChildIndex != null
            ? children[_selectedChildIndex!]
            : null;

        // Calculate total screen time
        int totalSeconds = 0;
        bool anyChildLocked = false;
        ChildModel? lockedChild;
        for (var child in children) {
          totalSeconds += child.screenTime;
          // Check if any child's device is locked
          if (child.isLocked) {
            anyChildLocked = true;
            lockedChild = child;
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6FBF4),
          // Floating unlock button - appears only when child device is locked
          floatingActionButton: anyChildLocked && lockedChild != null
              ? _buildUnlockFAB(user.uid, lockedChild, colorScheme)
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: r.hp(16)),

                    // Enhanced Header
                    _buildEnhancedHeader(
                      context,
                      userName,
                      colorScheme,
                      children,
                      user.uid,
                    ),

                    SizedBox(height: r.hp(28)),

                    // Children Carousel
                    if (children.isNotEmpty) ...[
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.myChildren,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllChildrenScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: r.hp(16)),
                      _buildChildrenCarousel(children, colorScheme),
                      SizedBox(height: r.hp(28)),
                    ],

                    // Stats Overview
                    _buildEnhancedStatsCard(
                      selectedChild,
                      totalSeconds,
                      colorScheme,
                    ),

                    SizedBox(height: r.hp(28)),

                    // Device Status Card
                    _buildDeviceStatusCard(selectedChild, colorScheme),

                    SizedBox(height: r.hp(28)),

                    // Quick Actions
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.quickActions,
                    ),
                    SizedBox(height: r.hp(16)),
                    _buildEnhancedQuickActions(context, children, colorScheme),

                    SizedBox(height: r.hp(100)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Trigger initial notification check/seed once per session or on load
  void _checkAndSeedNotifications(String uid, List<ChildModel> children) {
    // Only verify if we have children and haven't checked recently,
    // or just let the service handle the "if empty" check efficiently.
    _notificationService.seedInitialNotifications(uid, children);
  }

  Widget _buildEnhancedHeader(
    BuildContext context,
    String userName,
    ColorScheme colorScheme,
    List<ChildModel> children,
    String userId,
  ) {
    final r = ResponsiveHelper.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(context),
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
          stream: _notificationService.getNotifications(userId),
          builder: (context, snapshot) {
            final hasUnread = snapshot.data?.any((n) => !n.isRead) ?? false;

            return GestureDetector(
              onTap: () => _showNotifications(context, userId),
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

  void _showNotifications(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.notifications,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<NotificationModel>>(
                stream: _notificationService.getNotifications(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Mark all as read when opened (optional, or specific items)
                  // For now, let's just show them.
                  // Could call _notificationService.markAllAsRead(userId);

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Dismissible(
                        key: Key(item.id), // Unique key for Dismissible
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _notificationService.deleteNotification(
                            userId,
                            item.id,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification dismissed'),
                            ),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade700,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: !item.isRead
                                ? const Color(0xFFF0FDF4)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: !item.isRead
                                  ? const Color(0xFF10B981).withOpacity(0.3)
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.icon,
                                  color: item.color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(item.timestamp),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Premium animated unlock FAB - appears when child device is locked
  Widget _buildUnlockFAB(
    String parentUid,
    ChildModel lockedChild,
    ColorScheme colorScheme,
  ) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        final glowOpacity = 0.3 + (_pulseController.value * 0.2);

        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                // Animated glow
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(glowOpacity),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                // Sharp shadow
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showUnlockConfirmDialog(parentUid, lockedChild),
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${lockedChild.name} Locked',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getLockReasonText(lockedChild.lockReason),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show confirmation dialog before unlocking
  void _showUnlockConfirmDialog(String parentUid, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unlock ${child.name}\'s Device?',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will allow your child to use their device again. The lock will be removed immediately.',
          style: TextStyle(color: Colors.grey, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unlockChildDevice(parentUid, child);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Unlock Now'),
          ),
        ],
      ),
    );
  }

  /// Unlock child device by updating Firestore
  void _unlockChildDevice(String parentUid, ChildModel child) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(child.id)
          .update({
            'isLocked': false,
            'unlockRequested': true,
            'limitUsedTime':
                0, // Reset time limit so device doesn't lock again immediately
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${child.name}\'s device has been unlocked! ✅'),
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
            content: Text('Failed to unlock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get user-friendly text for lock reason
  String _getLockReasonText(String lockReason) {
    switch (lockReason) {
      case 'blocked_app':
        return 'App Blocked • Tap to unlock';
      case 'time_limit':
        return 'Time Limit Reached • Tap to unlock';
      case 'sleep':
        return 'Sleep Time • Tap to unlock';
      case 'quiet':
        return 'Quiet Time • Tap to unlock';
      case 'screen_timeout':
        return 'Screen Timeout • Tap to unlock';
      case 'pause':
        return 'Device Paused • Tap to unlock';
      default:
        return 'Tap to unlock device';
    }
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    final r = ResponsiveHelper.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: r.sp(20),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: const Color(0xFF1F2937),
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: r.sp(14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChildrenCarousel(
    List<ChildModel> children,
    ColorScheme colorScheme,
  ) {
    final r = ResponsiveHelper.of(context);
    return SizedBox(
      height: r.hp(160),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: r.wp(16)),
        itemBuilder: (context, index) {
          if (index == children.length) {
            // Add New Button
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChildSetupScreen()),
              ),
              child: Container(
                width: r.wp(120),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(r.radius(20)),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(r.wp(12)),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: colorScheme.primary,
                        size: r.iconSize(28),
                      ),
                    ),
                    SizedBox(height: r.hp(12)),
                    Text(
                      'Add Child',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: r.sp(14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final child = children[index];
          final isSelected = _selectedChildIndex == index;
          final isOnline =
              child.isChildModeActive &&
              child.lastActive != null &&
              DateTime.now().difference(child.lastActive!).inMinutes < 2;

          final screenHours = child.screenTime ~/ 3600;
          final screenMins = (child.screenTime % 3600) ~/ 60;

          return GestureDetector(
            onTap: () => setState(() => _selectedChildIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: r.wp(140),
              padding: EdgeInsets.all(r.wp(16)),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [colorScheme.primary, colorScheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                borderRadius: BorderRadius.circular(r.radius(28)),
                border: isSelected
                    ? null
                    : Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.25)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: isSelected ? 30 : 20,
                    offset: const Offset(0, 12),
                    spreadRadius: isSelected ? 0 : -4,
                  ),
                  BoxShadow(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.15)
                        : Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: r.wp(24),
                            backgroundColor: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : colorScheme.primaryContainer,
                            backgroundImage: child.avatar != null
                                ? AssetImage(child.avatar!)
                                : null,
                            child: child.avatar == null
                                ? Text(
                                    child.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: r.sp(18),
                                      color: isSelected
                                          ? Colors.white
                                          : colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: r.wp(14),
                                height: r.wp(14),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.wp(8),
                          vertical: r.hp(4),
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(r.radius(8)),
                        ),
                        child: Text(
                          isOnline ? 'Active' : 'Offline',
                          style: TextStyle(
                            fontSize: r.sp(10),
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isOnline ? Colors.green : Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    child.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: r.sp(16),
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: r.hp(4)),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: r.iconSize(14),
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                      SizedBox(width: r.wp(4)),
                      Flexible(
                        child: Text(
                          '${screenHours}h ${screenMins}m today',
                          style: TextStyle(
                            fontSize: r.sp(12),
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedStatsCard(
    ChildModel? selectedChild,
    int totalSeconds,
    ColorScheme colorScheme,
  ) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    // Calculate progress based on daily time limit
    final dailyLimit = selectedChild?.dailyTimeLimit ?? 0;
    double progress = 0.0;
    if (dailyLimit > 0) {
      progress = (totalSeconds / dailyLimit).clamp(0.0, 1.0);
    } else {
      // No limit set - show 0%
      progress = 0.0;
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
          // Primary color-tinted shadow (far, soft)
          BoxShadow(
            color: const Color(0xFF6B9080).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -8,
          ),
          // Secondary shadow (near, crisp)
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
                            painter: _MiniProgressPainter(progress: value),
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
          _buildYesterdayComparison(selectedChild, totalSeconds),
        ],
      ),
    );
  }

  Widget _buildYesterdayComparison(ChildModel? child, int todaySeconds) {
    if (child == null) {
      return const SizedBox();
    }

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
          .doc(child.id)
          .collection('daily_stats')
          .doc(yesterdayStr)
          .get(),
      builder: (context, snapshot) {
        int yesterdaySeconds = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          yesterdaySeconds = data?['screenTime'] ?? 0;
        }

        // Calculate difference
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

  Widget _buildDeviceStatusCard(ChildModel? child, ColorScheme colorScheme) {
    if (child == null) return const SizedBox();

    final isOnline =
        child.isChildModeActive &&
        child.lastActive != null &&
        DateTime.now().difference(child.lastActive!).inMinutes < 2;
    final lastActiveText = child.lastActive != null
        ? _formatLastActive(child.lastActive!)
        : 'Never';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFCFDFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100.withOpacity(0.8)),
        boxShadow: [
          // Soft outer glow
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          // Subtle inner highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Indicator
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Container(
                    width: isOnline ? 16 + (_pulseController.value * 4) : 16,
                    height: isOnline ? 16 + (_pulseController.value * 4) : 16,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(
                                  0.4 - _pulseController.value * 0.2,
                                ),
                                blurRadius: 12,
                                spreadRadius: _pulseController.value * 4,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Device Online' : 'Device Offline',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline ? 'Active now' : 'Last seen $lastActiveText',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Action Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildEnhancedQuickActions(
    BuildContext context,
    List<ChildModel> children,
    ColorScheme colorScheme,
  ) {
    final actions = [
      _QuickAction(
        icon: Icons.pause_circle_filled_rounded,
        label: 'Pause',
        subtitle: 'Pause now',
        color: const Color(0xFFEF4444),
        onTap: () => _showInstantPauseDialog(context, children),
      ),
      _QuickAction(
        icon: Icons.apps_rounded,
        label: 'Apps',
        subtitle: 'Manage apps',
        color: const Color(0xFF6B9080),
        onTap: () {
          final selectedChild =
              children.isNotEmpty && _selectedChildIndex != null
              ? children[_selectedChildIndex!]
              : null;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ParentAppControlScreen(
                childId: selectedChild?.id,
                childName: selectedChild?.name,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.timer_rounded,
        label: 'Timer',
        subtitle: 'Set limits',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimeLimitScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.location_on_rounded,
        label: 'Location',
        subtitle: 'Track device',
        color: const Color(0xFF10B981),
        onTap: () => _navigateToLocation(context, children),
      ),
      _QuickAction(
        icon: Icons.calendar_month_rounded,
        label: 'Schedule',
        subtitle: 'Sleep & Break',
        color: const Color(0xFF6B9080),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.star_rounded,
        label: 'Rewards',
        subtitle: 'Points & Goals',
        color: const Color(0xFF84A98C),
        onTap: () => _navigateToRewards(context, children),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: ResponsiveHelper.of(context).wp(12),
        mainAxisSpacing: ResponsiveHelper.of(context).hp(12),
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 80)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: _EnhancedActionCard(action: action),
        );
      },
    );
  }

  void _navigateToLocation(BuildContext context, List<ChildModel> children) {
    if (children.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a child first')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    final selectedChild =
        (_selectedChildIndex != null && children.length > _selectedChildIndex!)
        ? children[_selectedChildIndex!]
        : children.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildLocationScreen(
          childId: selectedChild.id,
          parentUid: user.uid,
          childName: selectedChild.name,
        ),
      ),
    );
  }

  void _navigateToRewards(BuildContext context, List<ChildModel> children) {
    if (children.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a child first')));
      return;
    }

    final selectedChild =
        (_selectedChildIndex != null && children.length > _selectedChildIndex!)
        ? children[_selectedChildIndex!]
        : children.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentRewardsScreen(child: selectedChild),
      ),
    );
  }

  void _showInstantPauseDialog(
    BuildContext context,
    List<ChildModel> children,
  ) {
    if (children.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a child first')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pause_circle_filled_rounded,
                color: Color(0xFFEF4444),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instant Pause',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'หยุดอุปกรณ์ทั้งหมดทันที',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildPauseOption(ctx, user.uid, children, 5),
                const SizedBox(width: 12),
                _buildPauseOption(ctx, user.uid, children, 10),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPauseOption(ctx, user.uid, children, 15),
                const SizedBox(width: 12),
                _buildPauseOption(ctx, user.uid, children, 30),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOption(
    BuildContext ctx,
    String parentUid,
    List<ChildModel> children,
    int minutes,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final pauseUntil = DateTime.now().add(Duration(minutes: minutes));
          for (var child in children) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(parentUid)
                .collection('children')
                .doc(child.id)
                .update({
                  'pauseUntil': pauseUntil.toIso8601String(),
                  'isLocked': true,
                });
          }
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.pause_circle_filled, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('หยุดอุปกรณ์แล้ว $minutes นาที'),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '$minutes',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
              Text(
                'นาที',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(100, 14),
                        const SizedBox(height: 8),
                        _shimmerBox(150, 28),
                      ],
                    ),
                    Row(
                      children: [
                        _shimmerBox(48, 48, radius: 14),
                        const SizedBox(width: 12),
                        _shimmerCircle(48),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _shimmerBox(100, 20),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, __) => _shimmerBox(140, 160, radius: 20),
                  ),
                ),
                const SizedBox(height: 28),
                _shimmerBox(double.infinity, 180, radius: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
    );
  }

  Widget _shimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
    );
  }
}

// Quick Action Data Model
class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

// Enhanced Action Card Widget
class _EnhancedActionCard extends StatefulWidget {
  final _QuickAction action;

  const _EnhancedActionCard({required this.action});

  @override
  State<_EnhancedActionCard> createState() => _EnhancedActionCardState();
}

class _EnhancedActionCardState extends State<_EnhancedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      onTap: widget.action.onTap,
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_hoverController.value * 0.05),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFAFBFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.of(context).radius(22),
            ),
            border: Border.all(
              color: Colors.grey.shade100.withOpacity(0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.of(context).wp(14)),
                decoration: BoxDecoration(
                  color: widget.action.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.action.icon,
                  color: widget.action.color,
                  size: ResponsiveHelper.of(context).iconSize(26),
                ),
              ),
              SizedBox(height: ResponsiveHelper.of(context).hp(10)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.of(context).wp(6),
                ),
                child: Text(
                  widget.action.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.of(context).sp(11),
                    color: const Color(0xFF3F4E4F),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Mini Progress Ring Painter
class _MiniProgressPainter extends CustomPainter {
  final double progress;

  _MiniProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4; // Increased padding

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          6 // Thinner stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          6 // Thinner stroke
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
  bool shouldRepaint(covariant _MiniProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
