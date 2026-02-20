import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../core/utils/responsive_helper.dart';

/// Unified Schedule Screen - combines Sleep Schedule and Quiet Time
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final r = ResponsiveHelper.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(r.wp(8)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(r.radius(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_rounded, size: r.iconSize(16)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ตารางเวลา',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.sp(20)),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('children')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final childrenDocs = snapshot.data!.docs;
          if (childrenDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.child_care,
                    size: r.iconSize(64),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: r.hp(16)),
                  Text(
                    'ยังไม่มีโปรไฟล์เด็ก',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
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
          return ListView.builder(
            padding: EdgeInsets.all(r.wp(20)),
            itemCount: children.length,
            itemBuilder: (context, index) =>
                _ScheduleCard(child: children[index], parentId: user.uid),
          );
        },
      ),
    );
  }
}

class _ScheduleCard extends StatefulWidget {
  final ChildModel child;
  final String parentId;

  const _ScheduleCard({required this.child, required this.parentId});

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  List<SchedulePeriod> _periods = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        List<SchedulePeriod> loadedPeriods = [];

        // Load Sleep Schedule
        if (data['sleepSchedule'] != null) {
          final sleep = data['sleepSchedule'] as Map<String, dynamic>;
          loadedPeriods.add(
            SchedulePeriod(
              name: 'เวลานอน',
              type: ScheduleType.sleep,
              startHour: sleep['bedtimeHour'] ?? 21,
              startMinute: sleep['bedtimeMinute'] ?? 0,
              endHour: sleep['wakeHour'] ?? 6,
              endMinute: sleep['wakeMinute'] ?? 0,
              enabled: sleep['enabled'] ?? false,
            ),
          );
        }

        // Load Quiet Times
        if (data['quietTimes'] != null) {
          final list = data['quietTimes'] as List<dynamic>;
          for (var item in list) {
            loadedPeriods.add(
              SchedulePeriod(
                name: item['name'] ?? 'เวลาพัก',
                type: ScheduleType.quietTime,
                startHour: item['startHour'] ?? 12,
                startMinute: item['startMinute'] ?? 0,
                endHour: item['endHour'] ?? 13,
                endMinute: item['endMinute'] ?? 0,
                enabled: item['enabled'] ?? true,
              ),
            );
          }
        }

        // If no sleep schedule exists, add default
        if (!loadedPeriods.any((p) => p.type == ScheduleType.sleep)) {
          loadedPeriods.insert(
            0,
            SchedulePeriod(
              name: 'เวลานอน',
              type: ScheduleType.sleep,
              startHour: 21,
              startMinute: 0,
              endHour: 6,
              endMinute: 0,
              enabled: false,
            ),
          );
        }

        setState(() {
          _periods = loadedPeriods;
        });
      }
    }
  }

  void _saveSchedules() {
    // Separate sleep and quiet times
    final sleepPeriod = _periods.firstWhere(
      (p) => p.type == ScheduleType.sleep,
      orElse: () => SchedulePeriod(
        name: 'เวลานอน',
        type: ScheduleType.sleep,
        startHour: 21,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
        enabled: false,
      ),
    );

    final quietTimes = _periods
        .where((p) => p.type == ScheduleType.quietTime)
        .map((p) => p.toQuietTimeMap())
        .toList();

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .update({
          'sleepSchedule': {
            'enabled': sleepPeriod.enabled,
            'bedtimeHour': sleepPeriod.startHour,
            'bedtimeMinute': sleepPeriod.startMinute,
            'wakeHour': sleepPeriod.endHour,
            'wakeMinute': sleepPeriod.endMinute,
          },
          'quietTimes': quietTimes,
        });
  }

  void _addQuietTime() {
    setState(() {
      _periods.add(
        SchedulePeriod(
          name:
              'เวลาพัก ${_periods.where((p) => p.type == ScheduleType.quietTime).length + 1}',
          type: ScheduleType.quietTime,
          startHour: 12,
          startMinute: 0,
          endHour: 13,
          endMinute: 0,
          enabled: true,
        ),
      );
    });
    _saveSchedules();
  }

  void _removePeriod(int index) {
    if (_periods[index].type == ScheduleType.sleep) {
      // Don't remove sleep, just disable
      setState(() {
        _periods[index] = _periods[index].copyWith(enabled: false);
      });
    } else {
      setState(() {
        _periods.removeAt(index);
      });
    }
    _saveSchedules();
  }

  void _togglePeriod(int index, bool enabled) {
    setState(() {
      _periods[index] = _periods[index].copyWith(enabled: enabled);
    });
    _saveSchedules();
  }

  Future<void> _editPeriod(int index) async {
    final period = _periods[index];

    final result = await showDialog<SchedulePeriod>(
      context: context,
      builder: (context) => _EditScheduleDialog(period: period),
    );

    if (result != null) {
      setState(() {
        _periods[index] = result;
      });
      _saveSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final enabledCount = _periods.where((p) => p.enabled).length;

    return Container(
      margin: EdgeInsets.only(bottom: r.hp(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(r.wp(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: r.wp(24),
                  backgroundColor: const Color(0xFF6B9080).withOpacity(0.1),
                  backgroundImage: widget.child.avatar != null
                      ? AssetImage(widget.child.avatar!)
                      : null,
                  child: widget.child.avatar == null
                      ? Text(
                          widget.child.name[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B9080),
                            fontSize: r.sp(18),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: r.wp(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.child.name,
                        style: TextStyle(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$enabledCount ช่วงเวลาที่เปิดใช้งาน',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: r.sp(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: r.hp(20)),
            ...List.generate(_periods.length, (index) {
              final period = _periods[index];
              final isSleep = period.type == ScheduleType.sleep;
              return Container(
                margin: EdgeInsets.only(bottom: r.hp(12)),
                padding: EdgeInsets.all(r.wp(16)),
                decoration: BoxDecoration(
                  color: period.enabled
                      ? (isSleep
                            ? const Color(0xFF6B9080).withOpacity(0.05)
                            : const Color(0xFF10B981).withOpacity(0.05))
                      : const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(r.radius(16)),
                  border: Border.all(
                    color: period.enabled
                        ? (isSleep
                              ? const Color(0xFF6B9080).withOpacity(0.2)
                              : const Color(0xFF10B981).withOpacity(0.2))
                        : const Color(0xFFE5E5EA),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(r.wp(10)),
                      decoration: BoxDecoration(
                        color: period.enabled
                            ? (isSleep
                                  ? const Color(0xFF6B9080).withOpacity(0.1)
                                  : const Color(0xFF10B981).withOpacity(0.1))
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(r.radius(12)),
                      ),
                      child: Icon(
                        isSleep
                            ? Icons.bedtime_rounded
                            : _getIconForName(period.name),
                        color: period.enabled
                            ? (isSleep
                                  ? const Color(0xFF6B9080)
                                  : const Color(0xFF10B981))
                            : Colors.grey,
                        size: r.iconSize(20),
                      ),
                    ),
                    SizedBox(width: r.wp(16)),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _editPeriod(index),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  period.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: period.enabled
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                                if (isSleep) ...[
                                  SizedBox(width: r.wp(8)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: r.wp(8),
                                      vertical: r.hp(2),
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6B9080,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        r.radius(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Sleep',
                                      style: TextStyle(
                                        fontSize: r.sp(10),
                                        color: const Color(0xFF6B9080),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: r.hp(2)),
                            Text(
                              '${period.formatStart()} - ${period.formatEnd()}',
                              style: TextStyle(
                                fontSize: r.sp(13),
                                color: period.enabled
                                    ? (isSleep
                                          ? const Color(0xFF6B9080)
                                          : const Color(0xFF10B981))
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Switch(
                      value: period.enabled,
                      onChanged: (value) => _togglePeriod(index, value),
                      activeColor: isSleep
                          ? const Color(0xFF6B9080)
                          : const Color(0xFF10B981),
                    ),
                    if (!isSleep)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: r.iconSize(20)),
                        color: Colors.grey[400],
                        onPressed: () => _removePeriod(index),
                      ),
                  ],
                ),
              );
            }),
            SizedBox(height: r.hp(16)),
            GestureDetector(
              onTap: _addQuietTime,
              child: Container(
                padding: EdgeInsets.all(r.wp(16)),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B9080).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(r.radius(16)),
                  border: Border.all(
                    color: const Color(0xFF6B9080).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(r.wp(6)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B9080).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(r.radius(8)),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: const Color(0xFF6B9080),
                        size: r.iconSize(18),
                      ),
                    ),
                    SizedBox(width: r.wp(12)),
                    Text(
                      'เพิ่มช่วงเวลา',
                      style: TextStyle(
                        color: const Color(0xFF6B9080),
                        fontWeight: FontWeight.w600,
                        fontSize: r.sp(14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForName(String name) {
    if (name.contains('เที่ยง') ||
        name.contains('อาหาร') ||
        name.contains('ทาน')) {
      return Icons.restaurant_outlined;
    } else if (name.contains('งีบ') || name.contains('พัก')) {
      return Icons.airline_seat_individual_suite_outlined;
    } else if (name.contains('บ้าน') ||
        name.contains('เรียน') ||
        name.contains('การบ้าน')) {
      return Icons.menu_book_outlined;
    } else if (name.contains('อาบ')) {
      return Icons.bathtub_outlined;
    }
    return Icons.schedule_outlined;
  }
}

// Schedule Period Model
enum ScheduleType { sleep, quietTime }

class SchedulePeriod {
  final String name;
  final ScheduleType type;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool enabled;

  SchedulePeriod({
    required this.name,
    required this.type,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.enabled,
  });

  SchedulePeriod copyWith({
    String? name,
    ScheduleType? type,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? enabled,
  }) {
    return SchedulePeriod(
      name: name ?? this.name,
      type: type ?? this.type,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      enabled: enabled ?? this.enabled,
    );
  }

  String formatStart() {
    return '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  }

  String formatEnd() {
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toQuietTimeMap() {
    return {
      'name': name,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'enabled': enabled,
    };
  }
}

// Edit Dialog
class _EditScheduleDialog extends StatefulWidget {
  final SchedulePeriod period;

  const _EditScheduleDialog({required this.period});

  @override
  State<_EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<_EditScheduleDialog> {
  late TextEditingController _nameController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.period.name);
    _startTime = TimeOfDay(
      hour: widget.period.startHour,
      minute: widget.period.startMinute,
    );
    _endTime = TimeOfDay(
      hour: widget.period.endHour,
      minute: widget.period.endMinute,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final isSleep = widget.period.type == ScheduleType.sleep;
    final primaryColor = isSleep
        ? const Color(0xFF6B9080)
        : const Color(0xFF6B9080);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.radius(20)),
      ),
      title: Row(
        children: [
          Icon(
            isSleep ? Icons.bedtime_rounded : Icons.schedule_rounded,
            color: primaryColor,
            size: r.iconSize(24),
          ),
          SizedBox(width: r.wp(12)),
          Text(
            isSleep ? 'ตั้งเวลานอน' : 'แก้ไขช่วงเวลา',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.sp(18)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSleep)
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
              ),
            ),
          if (!isSleep) SizedBox(height: r.hp(20)),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectStartTime,
                  child: Container(
                    padding: EdgeInsets.all(r.wp(16)),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(r.radius(12)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isSleep ? 'เข้านอน' : 'เริ่ม',
                          style: TextStyle(
                            fontSize: r.sp(12),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: r.hp(4)),
                        Text(
                          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: r.sp(24),
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.wp(12)),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.grey[400],
                  size: r.iconSize(24),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _selectEndTime,
                  child: Container(
                    padding: EdgeInsets.all(r.wp(16)),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(r.radius(12)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isSleep ? 'ตื่นนอน' : 'สิ้นสุด',
                          style: TextStyle(
                            fontSize: r.sp(12),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: r.hp(4)),
                        Text(
                          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: r.sp(24),
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('ยกเลิก', style: TextStyle(fontSize: r.sp(14))),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              widget.period.copyWith(
                name: isSleep ? widget.period.name : _nameController.text,
                startHour: _startTime.hour,
                startMinute: _startTime.minute,
                endHour: _endTime.hour,
                endMinute: _endTime.minute,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.radius(12)),
            ),
          ),
          child: Text(
            'บันทึก',
            style: TextStyle(color: Colors.white, fontSize: r.sp(14)),
          ),
        ),
      ],
    );
  }
}
