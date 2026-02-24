// ==================== Schedule Period Model ====================
/// โมเดลสำหรับช่วงเวลาตาราง (เวลานอน / เวลาพัก)

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
