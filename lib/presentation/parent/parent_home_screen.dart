import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../core/utils/responsive_helper.dart';
import 'time_limit_screen.dart';
import 'child_location_screen.dart';
import 'schedule_screen.dart';
import 'parent_rewards_screen.dart';
import 'all_children_screen.dart';
import 'apps/parent_app_control_screen.dart';

import 'package:kidguard/l10n/app_localizations.dart';
import 'package:kidguard/data/services/notification_service.dart';
import 'package:kidguard/data/services/local_notification_service.dart';
import 'package:kidguard/data/models/notification_model.dart';

// Extracted widgets
import 'home/home_header_widget.dart';
import 'home/unlock_fab_widget.dart';
import 'home/children_carousel_widget.dart';
import 'home/stats_card_widget.dart';
import 'home/device_status_widget.dart';
import 'home/quick_actions_widget.dart';
import 'home/instant_pause_sheet.dart';
import 'home/shimmer_loading_widget.dart';

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
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  DateTime? _lastNotificationTime;
  final Set<String> _shownNotificationIds = {};
  bool _hasSeededNotifications = false;

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
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      _lastNotificationTime = DateTime.now();
      _notificationSubscription = _notificationService
          .getNotifications(user.uid)
          .listen((notifications) {
            if (notifications.isNotEmpty) {
              final latest = notifications.first;
              // Dedup: skip if already shown or if timestamp is not newer
              if (latest.timestamp.isAfter(_lastNotificationTime!) &&
                  !_shownNotificationIds.contains(latest.id)) {
                _lastNotificationTime = latest.timestamp;
                _shownNotificationIds.add(latest.id);
                // Keep dedup set bounded
                if (_shownNotificationIds.length > 100) {
                  _shownNotificationIds.clear();
                }
                LocalNotificationService.showNotification(
                  id: latest.id.hashCode,
                  title: latest.title,
                  body: latest.message,
                  category: latest.category,
                );
              }
            }
          });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _notificationSubscription?.cancel();
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
          return const ShimmerLoadingWidget();
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

        if (children.isNotEmpty) {
          _checkAndSeedNotifications(user.uid, children);
        }

        if (_selectedChildIndex == null && children.isNotEmpty) {
          _selectedChildIndex = 0;
        }

        final selectedChild = children.isNotEmpty && _selectedChildIndex != null
            ? children[_selectedChildIndex!]
            : null;

        int totalSeconds = 0;
        bool anyChildLocked = false;
        ChildModel? lockedChild;
        for (var child in children) {
          totalSeconds += child.screenTime;
          if (child.isLocked) {
            anyChildLocked = true;
            lockedChild = child;
          }
        }

        return Scaffold(
          backgroundColor: colorScheme.background,
          floatingActionButton: anyChildLocked && lockedChild != null
              ? UnlockFabWidget(
                  parentUid: user.uid,
                  lockedChild: lockedChild,
                  colorScheme: colorScheme,
                  pulseAnimation: _pulseController,
                )
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
                    HomeHeaderWidget(
                      userName: userName,
                      greeting: _getGreeting(context),
                      colorScheme: colorScheme,
                      children: children,
                      userId: user.uid,
                    ),
                    SizedBox(height: r.hp(28)),
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
                      ChildrenCarouselWidget(
                        children: children,
                        colorScheme: colorScheme,
                        selectedChildIndex: _selectedChildIndex,
                        onChildSelected: (index) =>
                            setState(() => _selectedChildIndex = index),
                      ),
                      SizedBox(height: r.hp(28)),
                    ],
                    StatsCardWidget(
                      selectedChild: selectedChild,
                      totalSeconds: totalSeconds,
                      colorScheme: colorScheme,
                    ),
                    SizedBox(height: r.hp(28)),
                    DeviceStatusWidget(
                      child: selectedChild,
                      colorScheme: colorScheme,
                      pulseAnimation: _pulseController,
                    ),
                    SizedBox(height: r.hp(28)),
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.quickActions,
                    ),
                    SizedBox(height: r.hp(16)),
                    QuickActionsWidget(
                      actions: _buildQuickActions(
                        context,
                        children,
                        colorScheme,
                        selectedChild,
                        user.uid,
                      ),
                    ),
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

  void _checkAndSeedNotifications(String uid, List<ChildModel> children) {
    if (_hasSeededNotifications) return;
    _hasSeededNotifications = true;
    _notificationService.seedInitialNotifications(uid, children);
    // Clean up any existing duplicates from previous bugs
    _notificationService.removeDuplicateNotifications(uid);
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    final r = ResponsiveHelper.of(context);
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: r.sp(20),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        if (onSeeAll != null)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onSeeAll,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.wp(12),
                    vertical: r.hp(6),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(r.radius(10)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.seeAll,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<QuickAction> _buildQuickActions(
    BuildContext context,
    List<ChildModel> children,
    ColorScheme colorScheme,
    ChildModel? selectedChild,
    String parentUid,
  ) {
    return [
      QuickAction(
        icon: Icons.access_time_rounded,
        label: 'Time Limit',
        subtitle: 'Set limits',
        color: colorScheme.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimeLimitScreen()),
        ),
      ),
      QuickAction(
        icon: Icons.apps_rounded,
        label: 'App Block',
        subtitle: 'Manage',
        color: const Color(0xFFEF4444),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentAppControlScreen(
              childId: selectedChild?.id,
              childName: selectedChild?.name,
            ),
          ),
        ),
      ),
      if (selectedChild != null)
        QuickAction(
          icon: Icons.location_on_rounded,
          label: 'Location',
          subtitle: 'Track',
          color: const Color(0xFF3B82F6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildLocationScreen(
                childId: selectedChild.id,
                parentUid: parentUid,
                childName: selectedChild.name,
              ),
            ),
          ),
        ),
      QuickAction(
        icon: Icons.calendar_today_rounded,
        label: 'Schedule',
        subtitle: 'Plan',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        ),
      ),
      if (selectedChild != null)
        QuickAction(
          icon: Icons.pause_circle_rounded,
          label: 'Instant Pause',
          subtitle: selectedChild.name,
          color: const Color(0xFFEF4444),
          onTap: () => showInstantPauseSheet(
            context,
            parentUid: parentUid,
            child: selectedChild,
          ),
        ),
      if (selectedChild != null)
        QuickAction(
          icon: Icons.emoji_events_rounded,
          label: 'Rewards',
          subtitle: 'Manage',
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ParentRewardsScreen(child: selectedChild),
            ),
          ),
        ),
    ];
  }
}
