import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../core/utils/who_guidelines.dart';

class TimeLimitScreen extends StatelessWidget {
  const TimeLimitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFFF8FAFC),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 60, bottom: 16),
              title: Text(
                'Time Limits',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // Header Description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B9080).withOpacity(0.1),
                      const Color(0xFF84A98C).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6B9080).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B9080).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFF6B9080),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Screen Time',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap on a child to set their daily limit',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Children List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('children')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final childrenDocs = snapshot.data!.docs;
              if (childrenDocs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.child_care_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No children added yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final children = childrenDocs
                  .map(
                    (doc) => ChildModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 80)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _ChildListItem(
                        child: children[index],
                        parentId: user.uid,
                      ),
                    );
                  }, childCount: children.length),
                ),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _ChildListItem extends StatefulWidget {
  final ChildModel child;
  final String parentId;

  const _ChildListItem({required this.child, required this.parentId});

  @override
  State<_ChildListItem> createState() => _ChildListItemState();
}

class _ChildListItemState extends State<_ChildListItem> {
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    if (minutes > 0) return '${minutes}m';
    return '0m';
  }

  String _formatLimit(int seconds) {
    if (seconds == 0) return 'ไม่จำกัด';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '$hours ชม. $minutes น.' : '$hours ชม.';
    }
    return '$minutes นาที';
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1) return const Color(0xFFEF4444);
    if (progress >= 0.8) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final totalUsage = widget.child.screenTime; // For statistics
    final limitUsed = widget.child.limitUsedTime; // For limit tracking
    final limit = widget.child.dailyTimeLimit;
    final progress = limit > 0 ? (limitUsed / limit).clamp(0.0, 1.0) : 0.0;
    final progressColor = limit > 0
        ? _getProgressColor(limitUsed / limit)
        : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Main Content - Tappable to set limit
          GestureDetector(
            onTap: () => _showTimePicker(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6B9080), Color(0xFF84A98C)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      backgroundImage: widget.child.avatar != null
                          ? AssetImage(widget.child.avatar!)
                          : null,
                      child: widget.child.avatar == null
                          ? Text(
                              widget.child.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF6B9080),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          widget.child.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Row 1: Total Usage Today (Statistics)
                        Row(
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ใช้งานวันนี้: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              _formatDuration(totalUsage),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Row 2: Limit Used (for time limit)
                        if (limit > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: progressColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Limit: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              Text(
                                '${_formatDuration(limitUsed)} / ${_formatLimit(limit)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: progressColor,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.all_inclusive_rounded,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ไม่ได้จำกัดเวลา',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Edit Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Progress Bar (only if limit is set)
          if (limit > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}% ใช้ไปแล้ว',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        'เหลือ ${_formatDuration(limit - limitUsed > 0 ? limit - limitUsed : 0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Divider
          Container(height: 1, color: Colors.grey.shade100),
          // Reset Button Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showResetConfirmation(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reset เวลา Limit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _TimePickerModal(child: widget.child, parentId: widget.parentId),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reset เวลา?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Reset เวลา Limit ของ ${widget.child.name} เป็น 0 ใช่หรือไม่?\n\nเวลาใช้งานทั้งหมด (สถิติ) จะยังคงเดิม',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScreenTime();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetScreenTime() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.child.id)
          .update({'limitUsedTime': 0});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text('Reset Limit ของ ${widget.child.name} แล้ว'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }
}

class _TimePickerModal extends StatefulWidget {
  final ChildModel child;
  final String parentId;

  const _TimePickerModal({required this.child, required this.parentId});

  @override
  State<_TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<_TimePickerModal> {
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  FixedExtentScrollController? _hoursController;
  FixedExtentScrollController? _minutesController;

  @override
  void initState() {
    super.initState();
    final totalSeconds = widget.child.dailyTimeLimit;
    _selectedHours = totalSeconds ~/ 3600;
    _selectedMinutes = (totalSeconds % 3600) ~/ 60;
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(
      initialItem: _selectedMinutes ~/ 5,
    );
  }

  @override
  void dispose() {
    _hoursController?.dispose();
    _minutesController?.dispose();
    super.dispose();
  }

  int get _totalSeconds => (_selectedHours * 3600) + (_selectedMinutes * 60);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B9080), Color(0xFF84A98C)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.child.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF6B9080),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.child.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set daily time limit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // WHO Guidelines Card
          _buildWHOGuidelinesCard(),

          const SizedBox(height: 16),

          // Time Picker
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Selection highlight
                Center(
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF6B9080).withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B9080).withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pickers
                Row(
                  children: [
                    const SizedBox(width: 20),
                    // Hours Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _hoursController,
                        itemExtent: 48,
                        diameterRatio: 1.5,
                        squeeze: 1.0,
                        selectionOverlay: const SizedBox(),
                        onSelectedItemChanged: (index) {
                          setState(() => _selectedHours = index);
                        },
                        children: List.generate(13, (index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    // Hours label
                    Text(
                      'hr',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Minutes Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _minutesController,
                        itemExtent: 48,
                        diameterRatio: 1.5,
                        squeeze: 1.0,
                        selectionOverlay: const SizedBox(),
                        onSelectedItemChanged: (index) {
                          setState(() => _selectedMinutes = index * 5);
                        },
                        children: List.generate(12, (index) {
                          return Center(
                            child: Text(
                              (index * 5).toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    // Minutes label
                    Text(
                      'min',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Presets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildPresetChip('30m', 0, 30),
                const SizedBox(width: 8),
                _buildPresetChip('1h', 1, 0),
                const SizedBox(width: 8),
                _buildPresetChip('2h', 2, 0),
                const SizedBox(width: 8),
                _buildPresetChip('∞', 0, 0),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                // Cancel Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save Button
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _saveAndClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B9080), Color(0xFF84A98C)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B9080).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Save Limit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int hours, int minutes) {
    final isSelected = _selectedHours == hours && _selectedMinutes == minutes;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedHours = hours;
            _selectedMinutes = minutes;
          });
          _hoursController?.animateToItem(
            hours,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
          _minutesController?.animateToItem(
            minutes ~/ 5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6B9080), Color(0xFF84A98C)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWHOGuidelinesCard() {
    final age = widget.child.age;
    final recommendation = WHOGuidelines.getRecommendation(age);
    final color = WHOGuidelines.getColor(age);
    final gradientColors = WHOGuidelines.getGradientColors(age);
    final currentMinutes = (_selectedHours * 60) + _selectedMinutes;
    final isExceeding =
        currentMinutes > 0 &&
        WHOGuidelines.isExceedingRecommendation(age, currentMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isExceeding
                ? [
                    const Color(0xFFF59E0B).withOpacity(0.18),
                    const Color(0xFFFBBF24).withOpacity(0.08),
                  ]
                : gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExceeding
                ? const Color(0xFFF59E0B).withOpacity(0.4)
                : color.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.public_rounded, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'คำแนะนำองค์การอนามัยโลก',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'สำหรับเด็กอายุ ${recommendation.ageGroup}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // WHO Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'WHO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Recommendation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    recommendation.maxMinutes == 0
                        ? Icons.block_rounded
                        : Icons.timer_outlined,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.recommendation,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recommendation.details,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Warning if exceeding
            if (isExceeding) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'เวลาที่ตั้งเกินคำแนะนำ WHO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveAndClose() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .update({'dailyTimeLimit': _totalSeconds});

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _totalSeconds == 0
                    ? '${widget.child.name} set to unlimited'
                    : '${widget.child.name}\'s limit saved',
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
