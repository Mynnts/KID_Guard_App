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

  @override
  void initState() {
    super.initState();
    _currentPoints = widget.child.points;
  }

  void _updateLocalPoints(int newPoints) {
    setState(() {
      _currentPoints = newPoints;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Rewards & Points'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF4F46E5),
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Earn & Calendar'),
              Tab(text: 'Redeem Prizes'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_currentPoints',
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _EarnTab(
              child: widget.child,
              currentPoints: _currentPoints,
              onPointsUpdated: _updateLocalPoints,
            ),
            _RedeemTab(
              child: widget.child,
              currentPoints: _currentPoints,
              onPointsUpdated: _updateLocalPoints,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: EARN (Calendar View)
// -----------------------------------------------------------------------------
class _EarnTab extends StatefulWidget {
  final ChildModel child;
  final int currentPoints;
  final Function(int) onPointsUpdated;

  const _EarnTab({
    required this.child,
    required this.currentPoints,
    required this.onPointsUpdated,
  });

  @override
  State<_EarnTab> createState() => _EarnTabState();
}

class _EarnTabState extends State<_EarnTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    // Fetch history from subcollection
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('children')
        .doc(widget.child.id)
        .collection('point_history')
        .orderBy('date', descending: true)
        .get();

    final Map<DateTime, List<dynamic>> newEvents = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final dayKey = DateTime(date.year, date.month, date.day);

      if (newEvents[dayKey] == null) newEvents[dayKey] = [];
      newEvents[dayKey]!.add({...data, 'id': doc.id});
    }

    if (mounted) {
      setState(() {
        _events = newEvents;
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return _events[dayKey] ?? [];
  }

  Future<void> _addPoints(int amount, String reason) async {
    if (_selectedDay == null) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    try {
      final newPoints = widget.currentPoints + amount;

      // 1. Update Child Balance
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(widget.child.id)
          .update({'points': newPoints});

      // 2. Add History Entry
      final entryDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        DateTime.now().hour,
        DateTime.now().minute,
      );

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

      // Update Local State
      widget.onPointsUpdated(newPoints);
      await _fetchHistory(); // Refresh calendar dots

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $amount points for $reason'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddPointsDialog() {
    final reasonController = TextEditingController();
    int selectedAmount = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Points for ${_formatDate(_selectedDay!)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Amount',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [10, 20, 50, 100].map((amount) {
                  final isSelected = selectedAmount == amount;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedAmount = amount),
                    child: Container(
                      width: 70,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+$amount',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reason',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'e.g., Finished homework, Cleaned room',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (reasonController.text.isEmpty) {
                      reasonController.text = 'Good Behavior';
                    }
                    _addPoints(selectedAmount, reasonController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Add Points',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : [];

    return Stack(
      children: [
        Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDay != null
                        ? 'Activity for ${_formatDate(_selectedDay!)}'
                        : 'Select a date',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedDay != null)
                    TextButton.icon(
                      onPressed: _showAddPointsDialog,
                      icon: const Icon(Icons.add_circle, size: 20),
                      label: const Text('Add Points'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: selectedEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activity on this day',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: selectedEvents.length,
                      itemBuilder: (context, index) {
                        final event = selectedEvents[index];
                        final isEarn = event['type'] == 'earn';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isEarn
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isEarn ? Icons.add : Icons.remove,
                                color: isEarn ? Colors.green : Colors.orange,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              event['reason'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              '${isEarn ? '+' : '-'}${event['amount']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isEarn ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: REDEEM (Catalog View)
// -----------------------------------------------------------------------------
class _RedeemTab extends StatelessWidget {
  final ChildModel child;
  final int currentPoints;
  final Function(int) onPointsUpdated;

  _RedeemTab({
    required this.child,
    required this.currentPoints,
    required this.onPointsUpdated,
  });

  final List<Map<String, dynamic>> _prizes = [
    {
      'name': 'Ice Cream',
      'cost': 100,
      'icon': Icons.icecream_rounded,
      'color': Colors.pink,
    },
    {
      'name': '1 hr Game Time',
      'cost': 200,
      'icon': Icons.videogame_asset_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'Movie Night',
      'cost': 500,
      'icon': Icons.movie_creation_rounded,
      'color': Colors.purple,
    },
    {
      'name': 'New Toy',
      'cost': 1000,
      'icon': Icons.toys_rounded,
      'color': Colors.orange,
    },
    {
      'name': 'Park Trip',
      'cost': 300,
      'icon': Icons.park_rounded,
      'color': Colors.green,
    },
    {
      'name': 'Stay Up Late',
      'cost': 150,
      'icon': Icons.bedtime_rounded,
      'color': Colors.indigo,
    },
  ];

  Future<void> _redeemPrize(
    BuildContext context,
    Map<String, dynamic> prize,
  ) async {
    if (currentPoints < prize['cost']) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not enough points!')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${prize['name']}?'),
        content: Text('This will cost ${prize['cost']} points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;
      if (user == null) return;

      final newPoints = currentPoints - (prize['cost'] as int);

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .update({'points': newPoints});

      // Add History
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(child.id)
          .collection('point_history')
          .add({
            'amount': prize['cost'],
            'reason': 'Redeemed: ${prize['name']}',
            'type': 'redeem',
            'date': Timestamp.now(),
          });

      onPointsUpdated(newPoints);

      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
          title: const Text('Success!'),
          content: Text('You redeemed ${prize['name']}!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _prizes.length,
      itemBuilder: (context, index) {
        final prize = _prizes[index];
        final canAfford = currentPoints >= (prize['cost'] as int);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (prize['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  prize['icon'] as IconData,
                  color: prize['color'] as Color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                prize['name'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${prize['cost']} pts',
                style: TextStyle(
                  color: canAfford ? const Color(0xFF4F46E5) : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 100,
                height: 36,
                child: ElevatedButton(
                  onPressed: canAfford
                      ? () => _redeemPrize(context, prize)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(canAfford ? 'Redeem' : 'Need Points'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
