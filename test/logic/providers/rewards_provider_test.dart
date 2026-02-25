import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/logic/providers/rewards_provider.dart';
import '../../helpers/firebase_mock.dart';

void main() {
  setupFirebaseMocks();

  group('RewardsProvider - Pure Logic', () {
    late RewardsProvider provider;

    setUp(() {
      provider = RewardsProvider();
    });

    group('initializePoints', () {
      test('sets current points', () {
        provider.initializePoints(100);

        expect(provider.currentPoints, 100);
      });

      test('sets selectedDay to focusedDay', () {
        provider.initializePoints(50);

        expect(provider.selectedDay, isNotNull);
        expect(provider.selectedDay!.year, provider.focusedDay.year);
        expect(provider.selectedDay!.month, provider.focusedDay.month);
        expect(provider.selectedDay!.day, provider.focusedDay.day);
      });

      test('notifies listeners', () {
        int callCount = 0;
        provider.addListener(() => callCount++);

        provider.initializePoints(200);

        expect(callCount, 1);
      });

      test('handles zero points', () {
        provider.initializePoints(0);
        expect(provider.currentPoints, 0);
      });

      test('overwrites previous points', () {
        provider.initializePoints(100);
        provider.initializePoints(500);
        expect(provider.currentPoints, 500);
      });
    });

    group('selectDay', () {
      test('updates selected and focused day', () {
        final selected = DateTime(2026, 3, 15);
        final focused = DateTime(2026, 3, 1);

        provider.selectDay(selected, focused);

        expect(provider.selectedDay, selected);
        expect(provider.focusedDay, focused);
      });

      test('notifies listeners', () {
        int callCount = 0;
        provider.addListener(() => callCount++);

        provider.selectDay(DateTime(2026, 1, 1), DateTime(2026, 1, 1));

        expect(callCount, 1);
      });
    });

    group('getEventsForDay', () {
      test('returns empty list for day with no events', () {
        final events = provider.getEventsForDay(DateTime(2026, 5, 1));

        expect(events, isEmpty);
      });

      test('returns events for day that has events', () {
        final events = provider.getEventsForDay(DateTime.now());
        expect(events, isList);
      });
    });

    group('initial state', () {
      test('currentPoints starts at 0', () {
        expect(provider.currentPoints, 0);
      });

      test('focusedDay starts as today', () {
        final today = DateTime.now();
        expect(provider.focusedDay.year, today.year);
        expect(provider.focusedDay.month, today.month);
        expect(provider.focusedDay.day, today.day);
      });

      test('selectedDay starts as null', () {
        expect(provider.selectedDay, isNull);
      });

      test('events starts empty', () {
        expect(provider.events, isEmpty);
      });

      test('isLoading starts as false', () {
        expect(provider.isLoading, isFalse);
      });

      test('errorMessage starts as null', () {
        expect(provider.errorMessage, isNull);
      });
    });
  });
}
