import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/data/models/schedule_period_model.dart';

void main() {
  group('SchedulePeriod', () {
    late SchedulePeriod sleepPeriod;
    late SchedulePeriod quietPeriod;

    setUp(() {
      sleepPeriod = SchedulePeriod(
        name: 'เวลานอน',
        type: ScheduleType.sleep,
        startHour: 21,
        startMinute: 0,
        endHour: 6,
        endMinute: 30,
        enabled: true,
      );

      quietPeriod = SchedulePeriod(
        name: 'เวลาพัก 1',
        type: ScheduleType.quietTime,
        startHour: 12,
        startMinute: 0,
        endHour: 13,
        endMinute: 0,
        enabled: false,
      );
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final copy = sleepPeriod.copyWith();

        expect(copy.name, sleepPeriod.name);
        expect(copy.type, sleepPeriod.type);
        expect(copy.startHour, sleepPeriod.startHour);
        expect(copy.startMinute, sleepPeriod.startMinute);
        expect(copy.endHour, sleepPeriod.endHour);
        expect(copy.endMinute, sleepPeriod.endMinute);
        expect(copy.enabled, sleepPeriod.enabled);
      });

      test('copies with partial override', () {
        final copy = sleepPeriod.copyWith(enabled: false, endHour: 7);

        expect(copy.enabled, isFalse);
        expect(copy.endHour, 7);
        // unchanged fields
        expect(copy.name, 'เวลานอน');
        expect(copy.type, ScheduleType.sleep);
        expect(copy.startHour, 21);
      });

      test('copies with full override', () {
        final copy = sleepPeriod.copyWith(
          name: 'New Name',
          type: ScheduleType.quietTime,
          startHour: 8,
          startMinute: 15,
          endHour: 9,
          endMinute: 45,
          enabled: false,
        );

        expect(copy.name, 'New Name');
        expect(copy.type, ScheduleType.quietTime);
        expect(copy.startHour, 8);
        expect(copy.startMinute, 15);
        expect(copy.endHour, 9);
        expect(copy.endMinute, 45);
        expect(copy.enabled, isFalse);
      });
    });

    group('formatStart', () {
      test('formats with zero-padding', () {
        expect(quietPeriod.formatStart(), '12:00');
      });

      test('pads single-digit hours', () {
        final period = sleepPeriod.copyWith(startHour: 6, startMinute: 5);
        expect(period.formatStart(), '06:05');
      });

      test('handles midnight', () {
        final period = sleepPeriod.copyWith(startHour: 0, startMinute: 0);
        expect(period.formatStart(), '00:00');
      });
    });

    group('formatEnd', () {
      test('formats correctly', () {
        expect(sleepPeriod.formatEnd(), '06:30');
      });

      test('handles 23:59', () {
        final period = sleepPeriod.copyWith(endHour: 23, endMinute: 59);
        expect(period.formatEnd(), '23:59');
      });
    });

    group('toQuietTimeMap', () {
      test('serializes correctly', () {
        final map = quietPeriod.toQuietTimeMap();

        expect(map['name'], 'เวลาพัก 1');
        expect(map['startHour'], 12);
        expect(map['startMinute'], 0);
        expect(map['endHour'], 13);
        expect(map['endMinute'], 0);
        expect(map['enabled'], isFalse);
      });

      test('does not include type field', () {
        final map = quietPeriod.toQuietTimeMap();
        expect(map.containsKey('type'), isFalse);
      });
    });

    group('ScheduleType enum', () {
      test('has sleep and quietTime values', () {
        expect(ScheduleType.values, hasLength(2));
        expect(ScheduleType.values, contains(ScheduleType.sleep));
        expect(ScheduleType.values, contains(ScheduleType.quietTime));
      });
    });
  });
}
