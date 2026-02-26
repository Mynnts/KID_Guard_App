import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguard/data/models/child_model.dart';

/// Shows the instant pause bottom sheet for a single selected child
void showInstantPauseSheet(
  BuildContext context, {
  required String parentUid,
  required ChildModel child,
}) {
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
            'หยุดอุปกรณ์ของ ${child.name}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _PauseOption(
                ctx: ctx,
                parentContext: context,
                parentUid: parentUid,
                child: child,
                minutes: 5,
              ),
              const SizedBox(width: 12),
              _PauseOption(
                ctx: ctx,
                parentContext: context,
                parentUid: parentUid,
                child: child,
                minutes: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PauseOption(
                ctx: ctx,
                parentContext: context,
                parentUid: parentUid,
                child: child,
                minutes: 15,
              ),
              const SizedBox(width: 12),
              _PauseOption(
                ctx: ctx,
                parentContext: context,
                parentUid: parentUid,
                child: child,
                minutes: 30,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _PauseOption extends StatelessWidget {
  final BuildContext ctx;
  final BuildContext parentContext;
  final String parentUid;
  final ChildModel child;
  final int minutes;

  const _PauseOption({
    required this.ctx,
    required this.parentContext,
    required this.parentUid,
    required this.child,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final pauseUntil = DateTime.now().add(Duration(minutes: minutes));
          await FirebaseFirestore.instance
              .collection('users')
              .doc(parentUid)
              .collection('children')
              .doc(child.id)
              .update({
                'pauseUntil': pauseUntil.toIso8601String(),
                'isLocked': true,
              });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.pause_circle_filled, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'หยุดอุปกรณ์ของ ${child.name} แล้ว $minutes นาที',
                    ),
                  ),
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
}
