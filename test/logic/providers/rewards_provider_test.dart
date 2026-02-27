import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/logic/providers/rewards_provider.dart';
import 'package:kidguard/data/models/reward_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

      test('customRewards starts empty', () {
        expect(provider.customRewards, isEmpty);
      });
    });
  });

  group('RewardModel', () {
    test('fromMap creates model correctly', () {
      final now = DateTime.now();
      final map = {
        'name': 'Ice Cream',
        'emoji': '🍦',
        'cost': 50,
        'createdAt': Timestamp.fromDate(now),
      };

      final model = RewardModel.fromMap(map, 'test-id');

      expect(model.id, 'test-id');
      expect(model.name, 'Ice Cream');
      expect(model.emoji, '🍦');
      expect(model.cost, 50);
      expect(model.createdAt.year, now.year);
    });

    test('fromMap handles missing fields with defaults', () {
      final model = RewardModel.fromMap({}, 'empty-id');

      expect(model.id, 'empty-id');
      expect(model.name, '');
      expect(model.emoji, '⭐');
      expect(model.cost, 0);
    });

    test('toMap returns correct map', () {
      final model = RewardModel(
        id: 'test',
        name: 'Game Time',
        emoji: '🎮',
        cost: 100,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = model.toMap();

      expect(map['name'], 'Game Time');
      expect(map['emoji'], '🎮');
      expect(map['cost'], 100);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('copyWith creates copy with updated fields', () {
      final original = RewardModel(
        id: 'test',
        name: 'Old Name',
        emoji: '⭐',
        cost: 50,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(name: 'New Name', cost: 100);

      expect(updated.id, 'test');
      expect(updated.name, 'New Name');
      expect(updated.emoji, '⭐');
      expect(updated.cost, 100);
      expect(updated.createdAt, original.createdAt);
    });

    test('copyWith preserves all fields when nothing specified', () {
      final original = RewardModel(
        id: 'test',
        name: 'Original',
        emoji: '🎁',
        cost: 75,
        createdAt: DateTime(2026, 2, 15),
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.emoji, original.emoji);
      expect(copy.cost, original.cost);
      expect(copy.createdAt, original.createdAt);
    });
  });
}
