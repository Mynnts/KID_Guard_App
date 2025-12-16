import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';

class SleepScheduleScreen extends StatelessWidget {
  const SleepScheduleScreen({super.key});

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
          'ตั้งเวลานอน',
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
              return _SleepScheduleCard(
                child: children[index],
                parentId: user.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _SleepScheduleCard extends StatefulWidget {
  final ChildModel child;
  final String parentId;

  const _SleepScheduleCard({required this.child, required this.parentId});

  @override
  State<_SleepScheduleCard> createState() => _SleepScheduleCardState();
}

class _SleepScheduleCardState extends State<_SleepScheduleCard> {
  bool _isEnabled = false;
  TimeOfDay _bedtime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  void _loadSchedule() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['sleepSchedule'] != null) {
        final schedule = data['sleepSchedule'] as Map<String, dynamic>;
        setState(() {
          _isEnabled = schedule['enabled'] ?? false;
          _bedtime = TimeOfDay(
            hour: schedule['bedtimeHour'] ?? 20,
            minute: schedule['bedtimeMinute'] ?? 0,
          );
          _wakeTime = TimeOfDay(
            hour: schedule['wakeHour'] ?? 7,
            minute: schedule['wakeMinute'] ?? 0,
          );
        });
      }
    }
  }

  void _saveSchedule() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .update({
          'sleepSchedule': {
            'enabled': _isEnabled,
            'bedtimeHour': _bedtime.hour,
            'bedtimeMinute': _bedtime.minute,
            'wakeHour': _wakeTime.hour,
            'wakeMinute': _wakeTime.minute,
          },
        });
  }

  Future<void> _selectTime(bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _wakeTime = picked;
        }
      });
      _saveSchedule();
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
                        '${widget.child.age} ปี',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: (value) {
                    setState(() => _isEnabled = value);
                    _saveSchedule();
                  },
                  activeColor: const Color(0xFF4F46E5),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Time Settings
            AnimatedOpacity(
              opacity: _isEnabled ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  // Bedtime
                  _buildTimeRow(
                    icon: Icons.bedtime_outlined,
                    label: 'เวลาเข้านอน',
                    time: _bedtime,
                    color: const Color(0xFF6366F1),
                    onTap: _isEnabled ? () => _selectTime(true) : null,
                  ),

                  const SizedBox(height: 16),

                  // Wake time
                  _buildTimeRow(
                    icon: Icons.wb_sunny_outlined,
                    label: 'เวลาตื่นนอน',
                    time: _wakeTime,
                    color: const Color(0xFFF59E0B),
                    onTap: _isEnabled ? () => _selectTime(false) : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF3B82F6),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEnabled
                          ? 'อุปกรณ์จะล็อคอัตโนมัติตั้งแต่ ${_formatTime(_bedtime)} - ${_formatTime(_wakeTime)}'
                          : 'เปิดใช้งานเพื่อล็อคหน้าจอตามเวลานอน',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required TimeOfDay time,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
