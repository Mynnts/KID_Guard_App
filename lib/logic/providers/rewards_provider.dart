// ==================== Rewards Provider ====================
/// จัดการ logic ของระบบ Rewards: เพิ่มคะแนน, แลกรางวัล, ดึงประวัติ
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentPoints = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  int get currentPoints => _currentPoints;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  Map<DateTime, List<dynamic>> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// เริ่มต้นค่า points จากข้อมูล child
  void initializePoints(int points) {
    _currentPoints = points;
    _selectedDay = _focusedDay;
    notifyListeners();
  }

  /// เลือกวันใน calendar
  void selectDay(DateTime selected, DateTime focused) {
    _selectedDay = selected;
    _focusedDay = focused;
    notifyListeners();
  }

  /// ดึง events สำหรับวันที่ระบุ
  List<dynamic> getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  /// ดึงประวัติ points จาก Firestore
  Future<void> fetchHistory(String userId, String childId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
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

    _events = newEvents;
    notifyListeners();
  }

  /// เพิ่ม points ให้เด็ก
  /// Returns true ถ้าสำเร็จ, false ถ้าเกิด error
  Future<bool> addPoints({
    required String userId,
    required String childId,
    required int amount,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPoints = _currentPoints + amount;
      final entryDate = _selectedDay ?? DateTime.now();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .update({'points': newPoints});

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .collection('point_history')
          .add({
            'amount': amount,
            'reason': reason,
            'type': 'earn',
            'date': Timestamp.fromDate(entryDate),
          });

      _currentPoints = newPoints;
      _isLoading = false;
      notifyListeners();

      await fetchHistory(userId, childId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// แลกรางวัล (หัก points)
  /// Returns true ถ้าสำเร็จ, false ถ้าเกิด error
  Future<bool> redeemReward({
    required String userId,
    required String childId,
    required int cost,
    required String rewardName,
  }) async {
    if (_currentPoints < cost) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPoints = _currentPoints - cost;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .update({'points': newPoints});

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .collection('point_history')
          .add({
            'amount': cost,
            'reason': rewardName,
            'type': 'redeem',
            'date': Timestamp.now(),
          });

      _currentPoints = newPoints;
      _isLoading = false;
      notifyListeners();

      await fetchHistory(userId, childId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
