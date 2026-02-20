import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../data/models/child_model.dart';
import '../../logic/providers/auth_provider.dart';
import 'package:kidguard/l10n/app_localizations.dart';
import '../../core/utils/responsive_helper.dart';

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

  // Helper method to get localized quick reasons
  List<Map<String, dynamic>> _getQuickReasons(BuildContext context) {
    return [
      {
        'emoji': '📚',
        'label': AppLocalizations.of(context)!.homework,
        'points': 10,
      },
      {
        'emoji': '🧹',
        'label': AppLocalizations.of(context)!.chores,
        'points': 15,
      },
      {
        'emoji': '🌟',
        'label': AppLocalizations.of(context)!.goodBehavior,
        'points': 20,
      },
      {
        'emoji': '🏃',
        'label': AppLocalizations.of(context)!.exercise,
        'points': 10,
      },
    ];
  }

  // Helper method to get localized rewards
  List<Map<String, dynamic>> _getRewards(BuildContext context) {
    return [
      {
        'emoji': '🍦',
        'name': AppLocalizations.of(context)!.iceCream,
        'cost': 50,
      },
      {
        'emoji': '🎮',
        'name': AppLocalizations.of(context)!.gameTime,
        'cost': 100,
      },
      {'emoji': '🎬', 'name': AppLocalizations.of(context)!.movie, 'cost': 150},
      {
        'emoji': '🧸',
        'name': AppLocalizations.of(context)!.newToy,
        'cost': 300,
      },
      {'emoji': '🌙', 'name': AppLocalizations.of(context)!.stayUp, 'cost': 80},
      {
        'emoji': '🏞️',
        'name': AppLocalizations.of(context)!.parkTrip,
        'cost': 200,
      },
    ];
  }

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
            content: Text(
              AppLocalizations.of(context)!.pointsEarned(amount, reason),
            ),
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
          content: Text(
            AppLocalizations.of(
              context,
            )!.needMorePoints(reward['cost'] - _currentPoints),
          ),
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
            Text(AppLocalizations.of(context)!.redeemConfirm(reward['name'])),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.redeemCost(reward['cost'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.redeemNow),
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
            'reason': AppLocalizations.of(context)!.redeemed(reward['name']),
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
                Text(
                  AppLocalizations.of(context)!.success,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.earnedReward(widget.child.name, reward['name']),
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.close),
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
    final r = ResponsiveHelper.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF4),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar with Points
              SliverAppBar(
                expandedHeight: r.hp(220),
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF6B9080),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: r.iconSize(24),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: r.wp(16)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: constraints.maxWidth - r.wp(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: r.hp(16)),
                                    // Child Avatar
                                    CircleAvatar(
                                      radius: r.wp(30),
                                      backgroundColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      backgroundImage:
                                          widget.child.avatar != null
                                          ? AssetImage(widget.child.avatar!)
                                          : null,
                                      child: widget.child.avatar == null
                                          ? Text(
                                              widget.child.name[0],
                                              style: TextStyle(
                                                fontSize: r.sp(24),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    SizedBox(height: r.hp(8)),
                                    Text(
                                      widget.child.name,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: r.sp(15),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: r.hp(4)),
                                    // Points Display
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: r.iconSize(28),
                                        ),
                                        SizedBox(width: r.wp(6)),
                                        TweenAnimationBuilder<int>(
                                          tween: IntTween(
                                            begin: 0,
                                            end: _currentPoints,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          builder: (context, value, child) {
                                            return Text(
                                              '$value',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.sp(42),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(width: r.wp(4)),
                                        Text(
                                          AppLocalizations.of(context)!.points,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: r.sp(16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: r.hp(8)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Quick Add Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.wp(20),
                    r.hp(24),
                    r.wp(20),
                    r.hp(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.quickAdd,
                        style: TextStyle(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: r.hp(12)),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth =
                              (constraints.maxWidth - 36) /
                              4; // 4 cards with 12px gaps
                          return IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _getQuickReasons(context).map((item) {
                                return GestureDetector(
                                  onTap: () =>
                                      _addPoints(item['points'], item['label']),
                                  child: Container(
                                    width: cardWidth.clamp(70.0, 90.0),
                                    padding: EdgeInsets.symmetric(
                                      vertical: r.hp(10),
                                      horizontal: r.wp(6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        r.radius(16),
                                      ),
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
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item['emoji'],
                                            style: TextStyle(
                                              fontSize: r.sp(22),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: r.hp(3)),
                                        Text(
                                          '+${item['points']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF10B981),
                                            fontSize: r.sp(13),
                                          ),
                                        ),
                                        SizedBox(height: r.hp(2)),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item['label'],
                                            style: TextStyle(
                                              fontSize: r.sp(10),
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
                  padding: EdgeInsets.fromLTRB(
                    r.wp(20),
                    r.hp(8),
                    r.wp(20),
                    r.hp(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.redeemRewards,
                            style: TextStyle(
                              fontSize: r.sp(18),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(AppLocalizations.of(context)!.seeAll),
                          ),
                        ],
                      ),
                      SizedBox(height: r.hp(8)),
                      SizedBox(
                        height: r.hp(140),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: _getRewards(context).length,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: r.wp(12)),
                          itemBuilder: (context, index) {
                            final reward = _getRewards(context)[index];
                            final canAfford =
                                _currentPoints >= (reward['cost'] as int);
                            return GestureDetector(
                              onTap: () => _redeemReward(reward),
                              child: Container(
                                width: r.wp(100),
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.wp(8),
                                  vertical: r.hp(8),
                                ),
                                decoration: BoxDecoration(
                                  color: canAfford
                                      ? Colors.white
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(
                                    r.radius(16),
                                  ),
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          reward['emoji'],
                                          style: TextStyle(
                                            fontSize: r.sp(28),
                                            color: canAfford
                                                ? null
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: r.hp(4)),
                                    Text(
                                      reward['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: r.sp(11),
                                        color: canAfford
                                            ? Colors.black87
                                            : Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: r.hp(3)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: r.wp(8),
                                        vertical: r.hp(2),
                                      ),
                                      decoration: BoxDecoration(
                                        color: canAfford
                                            ? const Color(
                                                0xFF6B9080,
                                              ).withOpacity(0.1)
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(
                                          r.radius(8),
                                        ),
                                      ),
                                      child: Text(
                                        '${reward['cost']}',
                                        style: TextStyle(
                                          fontSize: r.sp(11),
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
                  padding: EdgeInsets.fromLTRB(
                    r.wp(20),
                    r.hp(8),
                    r.wp(20),
                    r.hp(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.pointHistory,
                        style: TextStyle(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: r.hp(12)),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(r.radius(20)),
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
                            markerSize: r.wp(6),
                            markersMaxCount: 1,
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              size: r.iconSize(20),
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              size: r.iconSize(20),
                            ),
                          ),
                          daysOfWeekHeight: r.hp(32),
                          rowHeight: r.hp(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Activity List
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.wp(20)),
                  child: _buildActivityList(),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: r.hp(32))),
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
    final r = ResponsiveHelper.of(context);

    if (events.isEmpty) {
      return Container(
        padding: EdgeInsets.all(r.wp(24)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.radius(16)),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_note_rounded,
              size: r.iconSize(40),
              color: Colors.grey[300],
            ),
            SizedBox(height: r.hp(12)),
            Text(
              AppLocalizations.of(context)!.noActivity,
              style: TextStyle(color: Colors.grey[500], fontSize: r.sp(14)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: events.map((event) {
        final isEarn = event['type'] == 'earn';
        return Container(
          margin: EdgeInsets.only(bottom: r.hp(8)),
          padding: EdgeInsets.all(r.wp(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r.radius(14)),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(r.wp(10)),
                decoration: BoxDecoration(
                  color: isEarn
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Icon(
                  isEarn ? Icons.add_rounded : Icons.remove_rounded,
                  color: isEarn ? const Color(0xFF10B981) : Colors.orange,
                  size: r.iconSize(20),
                ),
              ),
              SizedBox(width: r.wp(14)),
              Expanded(
                child: Text(
                  event['reason'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: r.sp(14),
                  ),
                ),
              ),
              Text(
                '${isEarn ? '+' : '-'}${event['amount']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: r.sp(16),
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
