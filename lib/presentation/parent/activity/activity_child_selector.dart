import 'package:flutter/material.dart';
import 'package:kidguard/core/utils/responsive_helper.dart';
import 'package:kidguard/data/models/child_model.dart';

/// Horizontal child picker pills for activity screen
class ActivityChildSelector extends StatelessWidget {
  static const _primaryGreen = Color(0xFF6B9080);
  static const _secondaryGreen = Color(0xFF84A98C);
  static const _accentGreen = Color(0xFF10B981);
  static const _cardColor = Colors.white;

  final List<ChildModel> children;
  final String? selectedChildId;
  final ValueChanged<String> onChildSelected;

  const ActivityChildSelector({
    super.key,
    required this.children,
    required this.selectedChildId,
    required this.onChildSelected,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    return SizedBox(
      height: r.hp(48),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(width: r.wp(10)),
        itemBuilder: (context, index) {
          final child = children[index];
          final isSelected = child.id == selectedChildId;
          final isOnline =
              child.lastActive != null &&
              DateTime.now().difference(child.lastActive!).inMinutes < 2;

          return GestureDetector(
            onTap: () => onChildSelected(child.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: r.wp(16)),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_primaryGreen, _secondaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : _cardColor,
                borderRadius: BorderRadius.circular(r.radius(24)),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey.shade200),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: r.wp(15),
                        backgroundColor: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : _primaryGreen.withOpacity(0.1),
                        child: Text(
                          child.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : _primaryGreen,
                          ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: r.wp(10),
                            height: r.wp(10),
                            decoration: BoxDecoration(
                              color: _accentGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? _primaryGreen : _cardColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: r.wp(8)),
                  Text(
                    child.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(14),
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
