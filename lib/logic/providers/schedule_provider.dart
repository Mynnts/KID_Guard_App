// ==================== Schedule Provider ====================
/// จัดการ logic ของตารางเวลา: Sleep Schedule + Quiet Times
/// เก็บข้อมูลแยกตามเด็กแต่ละคน (per-child)
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/schedule_period_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // เก็บ periods แยกตาม childId
  final Map<String, List<SchedulePeriod>> _childPeriods = {};
  final Map<String, bool> _loadingState = {};

  // Getters — ดึงข้อมูลตาม childId
  List<SchedulePeriod> getPeriodsForChild(String childId) =>
      _childPeriods[childId] ?? [];

  bool isLoadingForChild(String childId) => _loadingState[childId] ?? false;

  /// โหลดตารางเวลาจาก Firestore สำหรับเด็กคนเดียว
  Future<void> loadSchedules(String parentId, String childId) async {
    _loadingState[childId] = true;
    notifyListeners();

    final doc = await _firestore
        .collection('users')
        .doc(parentId)
        .collection('children')
        .doc(childId)
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

        // ถ้าไม่มี sleep schedule → ใส่ค่าเริ่มต้น
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

        _childPeriods[childId] = loadedPeriods;
      }
    }

    _loadingState[childId] = false;
    notifyListeners();
  }

  /// บันทึกตารางเวลาลง Firestore
  Future<void> saveSchedules(String parentId, String childId) async {
    final periods = _childPeriods[childId] ?? [];

    final sleepPeriod = periods.firstWhere(
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

    final quietTimes = periods
        .where((p) => p.type == ScheduleType.quietTime)
        .map((p) => p.toQuietTimeMap())
        .toList();

    await _firestore
        .collection('users')
        .doc(parentId)
        .collection('children')
        .doc(childId)
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

  /// เพิ่ม Quiet Time ใหม่
  Future<void> addQuietTime(String parentId, String childId) async {
    final periods = _childPeriods[childId] ?? [];
    periods.add(
      SchedulePeriod(
        name:
            'เวลาพัก ${periods.where((p) => p.type == ScheduleType.quietTime).length + 1}',
        type: ScheduleType.quietTime,
        startHour: 12,
        startMinute: 0,
        endHour: 13,
        endMinute: 0,
        enabled: true,
      ),
    );
    _childPeriods[childId] = periods;
    notifyListeners();
    await saveSchedules(parentId, childId);
  }

  /// ลบช่วงเวลา (Sleep จะถูก disable แทนลบ)
  Future<void> removePeriod(int index, String parentId, String childId) async {
    final periods = _childPeriods[childId];
    if (periods == null || index >= periods.length) return;

    if (periods[index].type == ScheduleType.sleep) {
      periods[index] = periods[index].copyWith(enabled: false);
    } else {
      periods.removeAt(index);
    }
    notifyListeners();
    await saveSchedules(parentId, childId);
  }

  /// เปิด/ปิด ช่วงเวลา
  Future<void> togglePeriod(
    int index,
    bool enabled,
    String parentId,
    String childId,
  ) async {
    final periods = _childPeriods[childId];
    if (periods == null || index >= periods.length) return;

    periods[index] = periods[index].copyWith(enabled: enabled);
    notifyListeners();
    await saveSchedules(parentId, childId);
  }

  /// แก้ไขช่วงเวลา
  Future<void> updatePeriod(
    int index,
    SchedulePeriod period,
    String parentId,
    String childId,
  ) async {
    final periods = _childPeriods[childId];
    if (periods == null || index >= periods.length) return;

    periods[index] = period;
    notifyListeners();
    await saveSchedules(parentId, childId);
  }
}
