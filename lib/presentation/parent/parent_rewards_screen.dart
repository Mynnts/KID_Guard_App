import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../data/models/child_model.dart';
import '../../logic/providers/auth_provider.dart';

class ParentRewardsScreen extends StatefulWidget {
  final ChildModel child;

  const ParentRewardsScreen({super.key, required this.child});

  @override
  State<ParentRewardsScreen> createState() => _ParentRewardsScreenState();
}

class _ParentRewardsScreenState extends State<ParentRewardsScreen> {
  int _currentPoints = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _quickReasons = [
    {'emoji': '📚', 'label': 'Homework', 'points': 10},
    {'emoji': '🧹', 'label': 'Chores', 'points': 15},
    {'emoji': '🌟', 'label': 'Good Behavior', 'points': 20},
    {'emoji': '🏃', 'label': 'Exercise', 'points': 10},
  ];

  final List<Map<String, dynamic>> _rewards = [
    {'emoji': '🍦', 'name': 'Ice Cream', 'cost': 50},
    {'emoji': '🎮', 'name': 'Game Time', 'cost': 100},
    {'emoji': '🎬', 'name': 'Movie', 'cost': 150},
    {'emoji': '🧸', 'name': 'New Toy', 'cost': 300},
    {'emoji': '🌙', 'name': 'Stay Up', 'cost': 80},
    {'emoji': '🏞️', 'name': 'Park Trip', 'cost': 200},
  ];

  @override
  void initState() {
    super.initState();
    _currentPoints = widget.child.points;
    _selectedDay = _focusedDay;
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('children')
        .doc(widget.child.id)
        .collection('point_history')
        .orderBy('date', descending: true)
        .limit(100)
        .get();

    final Map<DateTime, List<dynamic>> newEvents = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final dayKey = DateTime(date.year, date.month, date.day);
      newEvents[dayKey] = [
        ...(newEvents[dayKey] ?? []),
        {...data, 'id': doc.id},
      ];
    }

    if (mounted) setState(() => _events = newEvents);
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _addPoints(int amount, String reason) async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    try {
      final newPoints = _currentPoints + amount;
      final entryDate = _selectedDay ?? DateTime.now();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(widget.child.id)
          .update({'points': newPoints});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(widget.child.id)
          .collection('point_history')
          .add({
            'amount': amount,
            'reason': reason,
            'type': 'earn',
            'date': Timestamp.fromDate(entryDate),
          });

      setState(() {
        _currentPoints = newPoints;
        _isLoading = false;
      });
      await _fetchHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$amount แต้ม สำหรับ $reason'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    if (_currentPoints < reward['cost']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ต้องการอีก ${reward['cost'] - _currentPoints} แต้ม'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(reward['emoji'], style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Text('แลก ${reward['name']}?'),
          ],
        ),
        content: Text('ใช้ ${reward['cost']} แต้ม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B9080),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('แลกเลย'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;
      if (user == null) return;

      final newPoints = _currentPoints - (reward['cost'] as int);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(widget.child.id)
          .update({'points': newPoints});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(widget.child.id)
          .collection('point_history')
          .add({
            'amount': reward['cost'],
            'reason': 'แลก: ${reward['name']}',
            'type': 'redeem',
            'date': Timestamp.now(),
          });

      setState(() {
        _currentPoints = newPoints;
        _isLoading = false;
      });
      await _fetchHistory();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reward['emoji'], style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  '🎉 สำเร็จ!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('${widget.child.name} ได้รับ ${reward['name']}'),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ปิด'),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF4),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar with Points
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF6B9080),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6B9080), Color(0xFF84A98C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Child Avatar
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: widget.child.avatar != null
                                ? AssetImage(widget.child.avatar!)
                                : null,
                            child: widget.child.avatar == null
                                ? Text(
                                    widget.child.name[0],
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.child.name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Points Display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              TweenAnimationBuilder<int>(
                                tween: IntTween(begin: 0, end: _currentPoints),
                                duration: const Duration(milliseconds: 600),
                                builder: (context, value, child) {
                                  return Text(
                                    '$value',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'แต้ม',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Quick Add Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เพิ่มแต้มด่วน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth =
                              (constraints.maxWidth - 36) /
                              4; // 4 cards with 12px gaps
                          return SizedBox(
                            height: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _quickReasons.map((item) {
                                return GestureDetector(
                                  onTap: () =>
                                      _addPoints(item['points'], item['label']),
                                  child: Container(
                                    width: cardWidth.clamp(70.0, 90.0),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item['emoji'],
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '+${item['points']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item['label'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Rewards Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'แลกของรางวัล',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('ดูทั้งหมด'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _rewards.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final reward = _rewards[index];
                            final canAfford =
                                _currentPoints >= (reward['cost'] as int);
                            return GestureDetector(
                              onTap: () => _redeemReward(reward),
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: canAfford
                                      ? Colors.white
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: canAfford
                                        ? const Color(
                                            0xFF6B9080,
                                          ).withOpacity(0.3)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      reward['emoji'],
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: canAfford ? null : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      reward['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: canAfford
                                            ? Colors.black87
                                            : Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: canAfford
                                            ? const Color(
                                                0xFF6B9080,
                                              ).withOpacity(0.1)
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${reward['cost']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: canAfford
                                              ? const Color(0xFF6B9080)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Calendar Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ประวัติแต้ม',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: CalendarFormat.week,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          eventLoader: _getEventsForDay,
                          calendarStyle: CalendarStyle(
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF6B9080),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFF6B9080).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            markerSize: 6,
                            markersMaxCount: 1,
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            leftChevronIcon: Icon(Icons.chevron_left, size: 20),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              size: 20,
                            ),
                          ),
                          daysOfWeekHeight: 32,
                          rowHeight: 48,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Activity List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildActivityList(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6B9080)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    final events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.event_note_rounded, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'ไม่มีกิจกรรมในวันนี้',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: events.map((event) {
        final isEarn = event['type'] == 'earn';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEarn
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEarn ? Icons.add_rounded : Icons.remove_rounded,
                  color: isEarn ? const Color(0xFF10B981) : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  event['reason'] ?? 'ไม่ระบุ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${isEarn ? '+' : '-'}${event['amount']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isEarn ? const Color(0xFF10B981) : Colors.orange,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
