import 'package:flutter/material.dart';
import 'package:kidguard/core/utils/responsive_helper.dart';
import 'package:kidguard/data/models/child_model.dart';
import 'package:kidguard/presentation/parent/child_setup_screen.dart';

/// Horizontal children carousel with status indicators
class ChildrenCarouselWidget extends StatelessWidget {
  final List<ChildModel> children;
  final ColorScheme colorScheme;
  final int? selectedChildIndex;
  final ValueChanged<int> onChildSelected;

  const ChildrenCarouselWidget({
    super.key,
    required this.children,
    required this.colorScheme,
    required this.selectedChildIndex,
    required this.onChildSelected,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    return SizedBox(
      height: r.hp(160),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: r.wp(16)),
        itemBuilder: (context, index) {
          if (index == children.length) {
            return _buildAddButton(context, r);
          }
          return _buildChildCard(context, index, r);
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ResponsiveHelper r) {
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

  Widget _buildChildCard(BuildContext context, int index, ResponsiveHelper r) {
    final child = children[index];
    final isSelected = selectedChildIndex == index;
    final isOnline =
        child.isChildModeActive &&
        child.lastActive != null &&
        DateTime.now().difference(child.lastActive!).inMinutes < 2;

    final screenHours = child.screenTime ~/ 3600;
    final screenMins = (child.screenTime % 3600) ~/ 60;

    return GestureDetector(
      onTap: () => onChildSelected(index),
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
              : Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
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
                      color: isSelected ? Colors.white70 : Colors.grey[600],
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
  }
}
