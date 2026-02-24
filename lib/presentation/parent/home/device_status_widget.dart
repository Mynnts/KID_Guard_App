import 'package:flutter/material.dart';
import 'package:kidguard/data/models/child_model.dart';

/// Device online/offline status card with pulse animation
class DeviceStatusWidget extends StatelessWidget {
  final ChildModel? child;
  final ColorScheme colorScheme;
  final Animation<double> pulseAnimation;

  const DeviceStatusWidget({
    super.key,
    required this.child,
    required this.colorScheme,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox();

    final isOnline =
        child!.isChildModeActive &&
        child!.lastActive != null &&
        DateTime.now().difference(child!.lastActive!).inMinutes < 2;
    final lastActiveText = child!.lastActive != null
        ? _formatLastActive(child!.lastActive!)
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
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
                animation: pulseAnimation,
                builder: (context, _) {
                  return Container(
                    width: isOnline ? 16 + (pulseAnimation.value * 4) : 16,
                    height: isOnline ? 16 + (pulseAnimation.value * 4) : 16,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.4 - pulseAnimation.value * 0.2),
                                blurRadius: 12,
                                spreadRadius: pulseAnimation.value * 4,
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
}
