import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import 'child_setup_screen.dart';
import 'time_limit_screen.dart';
import 'child_location_screen.dart';
import 'sleep_schedule_screen.dart';
import 'quiet_time_screen.dart';

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final colorScheme = Theme.of(context).colorScheme;
    final userName = user?.displayName ?? 'Parent';

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

        // Set default selected child
        if (_selectedChildIndex == null && children.isNotEmpty) {
          _selectedChildIndex = 0;
        }

        final selectedChild = children.isNotEmpty && _selectedChildIndex != null
            ? children[_selectedChildIndex!]
            : null;

        // Calculate total screen time
        int totalSeconds = 0;
        for (var child in children) {
          totalSeconds += child.screenTime;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Enhanced Header
                    _buildEnhancedHeader(userName, colorScheme),

                    const SizedBox(height: 28),

                    // Children Carousel
                    if (children.isNotEmpty) ...[
                      _buildSectionHeader('My Children', onSeeAll: () {}),
                      const SizedBox(height: 16),
                      _buildChildrenCarousel(children, colorScheme),
                      const SizedBox(height: 28),
                    ],

                    // Stats Overview
                    _buildEnhancedStatsCard(
                      selectedChild,
                      totalSeconds,
                      colorScheme,
                    ),

                    const SizedBox(height: 28),

                    // Device Status Card
                    _buildDeviceStatusCard(selectedChild, colorScheme),

                    const SizedBox(height: 28),

                    // Quick Actions
                    _buildSectionHeader('Quick Actions'),
                    const SizedBox(height: 16),
                    _buildEnhancedQuickActions(context, children, colorScheme),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(String userName, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        // Notification Bell
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Stack(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: Colors.grey.shade600,
                size: 24,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
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
        const SizedBox(width: 12),
        // Profile Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: Color(0xFF1F2937),
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
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
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == children.length) {
            // Add New Button
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChildSetupScreen()),
              ),
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add Child',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
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
              child.lastActive != null &&
              DateTime.now().difference(child.lastActive!).inMinutes < 2;

          final screenHours = child.screenTime ~/ 3600;
          final screenMins = (child.screenTime % 3600) ~/ 60;

          return GestureDetector(
            onTap: () => setState(() => _selectedChildIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [colorScheme.primary, colorScheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 20 : 10,
                    offset: const Offset(0, 8),
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
                            radius: 24,
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
                                      fontSize: 18,
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
                                width: 14,
                                height: 14,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOnline ? 'Active' : 'Offline',
                          style: TextStyle(
                            fontSize: 10,
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
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${screenHours}h ${screenMins}m today',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : Colors.grey[600],
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            blurRadius: 20,
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 0.65),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _MiniProgressPainter(progress: value),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
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
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '15% less than yesterday',
                    style: TextStyle(
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
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(ChildModel? child, ColorScheme colorScheme) {
    if (child == null) return const SizedBox();

    final isOnline =
        child.lastActive != null &&
        DateTime.now().difference(child.lastActive!).inMinutes < 2;
    final lastActiveText = child.lastActive != null
        ? _formatLastActive(child.lastActive!)
        : 'Never';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
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
    bool isAnyLocked = children.any((c) => c.isLocked);

    final actions = [
      _QuickAction(
        icon: Icons.apps_rounded,
        label: 'App Control',
        subtitle: 'Manage apps',
        color: const Color(0xFF4F46E5),
        onTap: () => Navigator.pushNamed(context, '/parent/app_control'),
      ),
      _QuickAction(
        icon: Icons.timer_rounded,
        label: 'Time Limits',
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
        icon: isAnyLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
        label: isAnyLocked ? 'Unlock' : 'Lock',
        subtitle: 'Device control',
        color: isAnyLocked ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        onTap: () => _toggleLock(context, children, isAnyLocked),
      ),
      _QuickAction(
        icon: Icons.bedtime_rounded,
        label: 'Sleep',
        subtitle: 'เวลานอน',
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SleepScheduleScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.do_not_disturb_on_rounded,
        label: 'Quiet Time',
        subtitle: 'เวลาพัก',
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuietTimeScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
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

    if (children.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChildLocationScreen(
            childId: children.first.id,
            parentUid: user.uid,
            childName: children.first.name,
          ),
        ),
      );
    } else {
      _showChildSelector(context, children, (child) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChildLocationScreen(
              childId: child.id,
              parentUid: user.uid,
              childName: child.name,
            ),
          ),
        );
      });
    }
  }

  void _toggleLock(
    BuildContext context,
    List<ChildModel> children,
    bool isLocked,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user != null) {
      for (var child in children) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('children')
            .doc(child.id)
            .update({'isLocked': !isLocked});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLocked ? 'Device Unlocked' : 'Device Locked'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showChildSelector(
    BuildContext context,
    List<ChildModel> children,
    Function(ChildModel) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
            const Text(
              'Select Child',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children.map(
              (child) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: child.avatar != null
                      ? AssetImage(child.avatar!)
                      : null,
                  child: child.avatar == null ? Text(child.name[0]) : null,
                ),
                title: Text(
                  child.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(child);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.action.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.action.icon,
                  color: widget.action.color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  widget.action.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  widget.action.subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
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
    final radius = size.width / 2 - 8;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toInt()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
