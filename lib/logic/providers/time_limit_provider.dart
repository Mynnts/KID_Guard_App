// ==================== Time Limit Provider ====================
/// จัดการ logic ของการจำกัดเวลาหน้าจอ: save limit, reset usage
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeLimitProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// บันทึกระยะเวลาจำกัดรายวัน (หน่วย: วินาที)
  /// Returns true ถ้าสำเร็จ
  Future<bool> saveTimeLimit({
    required String parentId,
    required String childId,
    required int totalSeconds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .update({'dailyTimeLimit': totalSeconds});

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// รีเซ็ตเวลาใช้งานเป็น 0
  /// Returns true ถ้าสำเร็จ
  Future<bool> resetScreenTime({
    required String parentId,
    required String childId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .update({'limitUsedTime': 0});

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
