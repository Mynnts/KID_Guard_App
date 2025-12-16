import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';

class QuietTimeScreen extends StatelessWidget {
  const QuietTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_rounded, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เวลาพักผ่อน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final childrenDocs = snapshot.data!.docs;
          if (childrenDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(20),
            itemCount: children.length,
            itemBuilder: (context, index) {
              return _QuietTimeCard(child: children[index], parentId: user.uid);
            },
          );
        },
      ),
    );
  }
}

class _QuietTimeCard extends StatefulWidget {
  final ChildModel child;
  final String parentId;

  const _QuietTimeCard({required this.child, required this.parentId});

  @override
  State<_QuietTimeCard> createState() => _QuietTimeCardState();
}

class _QuietTimeCardState extends State<_QuietTimeCard> {
  List<QuietTimePeriod> _periods = [];

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  void _loadPeriods() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['quietTimes'] != null) {
        final list = data['quietTimes'] as List<dynamic>;
        setState(() {
          _periods = list.map((item) => QuietTimePeriod.fromMap(item)).toList();
        });
      }
    }
  }

  void _savePeriods() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .update({'quietTimes': _periods.map((p) => p.toMap()).toList()});
  }

  void _addPeriod() {
    setState(() {
      _periods.add(
        QuietTimePeriod(
          name: 'เวลาพัก ${_periods.length + 1}',
          startHour: 12,
          startMinute: 0,
          endHour: 13,
          endMinute: 0,
          enabled: true,
        ),
      );
    });
    _savePeriods();
  }

  void _removePeriod(int index) {
    setState(() {
      _periods.removeAt(index);
    });
    _savePeriods();
  }

  void _togglePeriod(int index, bool enabled) {
    setState(() {
      _periods[index] = _periods[index].copyWith(enabled: enabled);
    });
    _savePeriods();
  }

  Future<void> _editPeriod(int index) async {
    final period = _periods[index];

    final result = await showDialog<QuietTimePeriod>(
      context: context,
      builder: (context) => _EditPeriodDialog(period: period),
    );

    if (result != null) {
      setState(() {
        _periods[index] = result;
      });
      _savePeriods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE67E22).withOpacity(0.1),
                  backgroundImage: widget.child.avatar != null
                      ? AssetImage(widget.child.avatar!)
                      : null,
                  child: widget.child.avatar == null
                      ? Text(
                          widget.child.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE67E22),
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.child.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_periods.where((p) => p.enabled).length} ช่วงเวลาที่เปิดใช้งาน',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Periods List
            if (_periods.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ยังไม่มีช่วงเวลาพัก',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_periods.length, (index) {
                final period = _periods[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: period.enabled
                        ? const Color(0xFF10B981).withOpacity(0.05)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: period.enabled
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: period.enabled
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForPeriod(period.name),
                          color: period.enabled
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editPeriod(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 2),
                              Text(
                                '${period.formatStart()} - ${period.formatEnd()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: period.enabled
                                      ? const Color(0xFF10B981)
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
                        activeColor: const Color(0xFF10B981),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.grey[400],
                        onPressed: () => _removePeriod(index),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Add Button
            GestureDetector(
              onTap: _addPeriod,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withOpacity(0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'เพิ่มช่วงเวลาพัก',
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600,
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

  IconData _getIconForPeriod(String name) {
    if (name.contains('เที่ยง') || name.contains('อาหาร')) {
      return Icons.restaurant_outlined;
    } else if (name.contains('งีบ') || name.contains('พัก')) {
      return Icons.airline_seat_individual_suite_outlined;
    } else if (name.contains('บ้าน') || name.contains('เรียน')) {
      return Icons.menu_book_outlined;
    }
    return Icons.schedule_outlined;
  }
}

class QuietTimePeriod {
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool enabled;

  QuietTimePeriod({
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.enabled,
  });

  factory QuietTimePeriod.fromMap(Map<String, dynamic> map) {
    return QuietTimePeriod(
      name: map['name'] ?? 'เวลาพัก',
      startHour: map['startHour'] ?? 12,
      startMinute: map['startMinute'] ?? 0,
      endHour: map['endHour'] ?? 13,
      endMinute: map['endMinute'] ?? 0,
      enabled: map['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'enabled': enabled,
    };
  }

  QuietTimePeriod copyWith({
    String? name,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? enabled,
  }) {
    return QuietTimePeriod(
      name: name ?? this.name,
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
}

class _EditPeriodDialog extends StatefulWidget {
  final QuietTimePeriod period;

  const _EditPeriodDialog({required this.period});

  @override
  State<_EditPeriodDialog> createState() => _EditPeriodDialogState();
}

class _EditPeriodDialogState extends State<_EditPeriodDialog> {
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'แก้ไขช่วงเวลา',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'ชื่อ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectStartTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('เริ่ม', style: TextStyle(fontSize: 12)),
                        Text(
                          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('-'),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _selectEndTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('สิ้นสุด', style: TextStyle(fontSize: 12)),
                        Text(
                          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              widget.period.copyWith(
                name: _nameController.text,
                startHour: _startTime.hour,
                startMinute: _startTime.minute,
                endHour: _endTime.hour,
                endMinute: _endTime.minute,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
