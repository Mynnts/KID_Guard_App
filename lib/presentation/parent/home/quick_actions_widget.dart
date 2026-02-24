import 'package:flutter/material.dart';
import 'package:kidguard/core/utils/responsive_helper.dart';

/// Quick action data model
class QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

/// Grid of quick action cards
class QuickActionsWidget extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsWidget({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
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
          child: EnhancedActionCard(action: action),
        );
      },
    );
  }
}

/// Enhanced action card with press animation
class EnhancedActionCard extends StatefulWidget {
  final QuickAction action;

  const EnhancedActionCard({super.key, required this.action});

  @override
  State<EnhancedActionCard> createState() => _EnhancedActionCardState();
}

class _EnhancedActionCardState extends State<EnhancedActionCard>
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
