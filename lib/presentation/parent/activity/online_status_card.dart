import 'package:flutter/material.dart';
import 'package:kidguard/core/utils/responsive_helper.dart';
import 'package:kidguard/data/models/child_model.dart';

/// Online status card with pulse indicator and unlock button
class OnlineStatusCard extends StatelessWidget {
  static const _primaryGreen = Color(0xFF6B9080);
  static const _accentGreen = Color(0xFF10B981);
  static const _cardColor = Colors.white;

  final ChildModel child;
  final Animation<double> pulseAnimation;
  final VoidCallback onUnlockTap;

  const OnlineStatusCard({
    super.key,
    required this.child,
    required this.pulseAnimation,
    required this.onUnlockTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final isOnline =
        child.lastActive != null &&
        DateTime.now().difference(child.lastActive!).inMinutes < 2;

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
      padding: EdgeInsets.all(r.wp(16)),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(r.radius(20)),
        border: Border.all(
          color: isOnline
              ? _accentGreen.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? _accentGreen.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPulseIndicator(r, isOnline),
          SizedBox(width: r.wp(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Online Now' : 'Offline',
                  style: TextStyle(
                    fontSize: r.sp(15),
                    fontWeight: FontWeight.w700,
                    color: isOnline ? _accentGreen : Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: r.hp(2)),
                Text(
                  isOnline && onlineDuration.isNotEmpty
                      ? 'Active for $onlineDuration'
                      : child.lastActive != null
                      ? 'Last seen ${_formatLastActive(child.lastActive!)}'
                      : 'Never connected',
                  style: TextStyle(
                    fontSize: r.sp(12),
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (isOnline) _buildLiveBadge(r),
          if (!isOnline || child.isLocked) _buildUnlockButton(r),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator(ResponsiveHelper r, bool isOnline) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        return Container(
          width: r.wp(44),
          height: r.wp(44),
          decoration: BoxDecoration(
            color: isOnline
                ? _accentGreen.withOpacity(0.08 + pulseAnimation.value * 0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(r.radius(14)),
          ),
          child: Center(
            child: Container(
              width: isOnline
                  ? r.wp(14) + (pulseAnimation.value * 2)
                  : r.wp(14),
              height: isOnline
                  ? r.wp(14) + (pulseAnimation.value * 2)
                  : r.wp(14),
              decoration: BoxDecoration(
                color: isOnline ? _accentGreen : Colors.grey.shade400,
                shape: BoxShape.circle,
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: _accentGreen.withOpacity(
                            0.4 - pulseAnimation.value * 0.2,
                          ),
                          blurRadius: 8,
                          spreadRadius: pulseAnimation.value * 3,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveBadge(ResponsiveHelper r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.wp(10), vertical: r.hp(5)),
      decoration: BoxDecoration(
        color: _accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(r.radius(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: r.wp(6),
            height: r.wp(6),
            decoration: const BoxDecoration(
              color: _accentGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: r.wp(4)),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: r.sp(10),
              fontWeight: FontWeight.w800,
              color: _accentGreen,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockButton(ResponsiveHelper r) {
    return GestureDetector(
      onTap: onUnlockTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.wp(12), vertical: r.hp(6)),
        decoration: BoxDecoration(
          color: _primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(r.radius(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_open_rounded,
              size: r.iconSize(14),
              color: _primaryGreen,
            ),
            SizedBox(width: r.wp(4)),
            Text(
              'Unlock',
              style: TextStyle(
                fontSize: r.sp(11),
                fontWeight: FontWeight.w700,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
