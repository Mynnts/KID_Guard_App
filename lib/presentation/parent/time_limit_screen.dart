import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';

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
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFF6366F1),
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

class _ChildListItem extends StatelessWidget {
  final ChildModel child;
  final String parentId;

  const _ChildListItem({required this.child, required this.parentId});

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'Unlimited';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  Color _getStatusColor(int usedTime, int limit) {
    if (limit == 0) return const Color(0xFF3B82F6);
    final progress = usedTime / limit;
    if (progress >= 1) return const Color(0xFFEF4444);
    if (progress >= 0.8) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final usedTime = child.screenTime;
    final limit = child.dailyTimeLimit;
    final progress = limit > 0 ? (usedTime / limit).clamp(0.0, 1.0) : 0.0;
    final statusColor = _getStatusColor(usedTime, limit);

    return GestureDetector(
      onTap: () => _showTimePicker(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                backgroundImage: child.avatar != null
                    ? AssetImage(child.avatar!)
                    : null,
                child: child.avatar == null
                    ? Text(
                        child.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF6366F1),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(usedTime),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        ' / ${_formatDuration(limit)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  if (limit > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
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
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimePickerModal(child: child, parentId: parentId),
    );
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
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                        color: Color(0xFF6366F1),
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
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.08),
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
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
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
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
