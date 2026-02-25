import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard/core/utils/who_guidelines.dart';

void main() {
  group('WHOGuidelines', () {
    group('getRecommendation', () {
      test('age 0 (infant) — no screen time', () {
        final rec = WHOGuidelines.getRecommendation(0);

        expect(rec.ageGroup, 'ทารก (0-1 ปี)');
        expect(rec.maxMinutes, 0);
        expect(rec.showWarning, isTrue);
      });

      test('age 1 — max 60 minutes with warning', () {
        final rec = WHOGuidelines.getRecommendation(1);

        expect(rec.ageGroup, '1-2 ปี');
        expect(rec.maxMinutes, 60);
        expect(rec.showWarning, isTrue);
      });

      test('age 2 — same as age 1 bracket', () {
        final rec = WHOGuidelines.getRecommendation(2);

        expect(rec.ageGroup, '1-2 ปี');
        expect(rec.maxMinutes, 60);
      });

      test('age 3-4 — max 60 minutes no warning', () {
        final rec3 = WHOGuidelines.getRecommendation(3);
        final rec4 = WHOGuidelines.getRecommendation(4);

        expect(rec3.ageGroup, '3-4 ปี');
        expect(rec3.maxMinutes, 60);
        expect(rec3.showWarning, isFalse);
        expect(rec4.ageGroup, '3-4 ปี');
      });

      test('age 5-12 — max 120 minutes', () {
        final rec5 = WHOGuidelines.getRecommendation(5);
        final rec12 = WHOGuidelines.getRecommendation(12);

        expect(rec5.ageGroup, '5-12 ปี');
        expect(rec5.maxMinutes, 120);
        expect(rec12.ageGroup, '5-12 ปี');
      });

      test('age 13+ — moderate control', () {
        final rec13 = WHOGuidelines.getRecommendation(13);
        final rec17 = WHOGuidelines.getRecommendation(17);

        expect(rec13.ageGroup, '13+ ปี');
        expect(rec13.maxMinutes, 120);
        expect(rec13.showWarning, isFalse);
        expect(rec17.ageGroup, '13+ ปี');
      });
    });

    group('getIcon', () {
      test('returns warning for age < 1', () {
        expect(WHOGuidelines.getIcon(0), Icons.warning_rounded);
      });

      test('returns child_care for age 1-2', () {
        expect(WHOGuidelines.getIcon(1), Icons.child_care_rounded);
        expect(WHOGuidelines.getIcon(2), Icons.child_care_rounded);
      });

      test('returns face for age 3-4', () {
        expect(WHOGuidelines.getIcon(3), Icons.face_rounded);
        expect(WHOGuidelines.getIcon(4), Icons.face_rounded);
      });

      test('returns school for age 5-12', () {
        expect(WHOGuidelines.getIcon(5), Icons.school_rounded);
        expect(WHOGuidelines.getIcon(12), Icons.school_rounded);
      });

      test('returns person for age 13+', () {
        expect(WHOGuidelines.getIcon(13), Icons.person_rounded);
        expect(WHOGuidelines.getIcon(18), Icons.person_rounded);
      });
    });

    group('getColor', () {
      test('returns red for age < 1', () {
        expect(WHOGuidelines.getColor(0), const Color(0xFFEF4444));
      });

      test('returns orange for age 1-4', () {
        expect(WHOGuidelines.getColor(1), const Color(0xFFF59E0B));
        expect(WHOGuidelines.getColor(2), const Color(0xFFF59E0B));
        expect(WHOGuidelines.getColor(3), const Color(0xFFF59E0B));
        expect(WHOGuidelines.getColor(4), const Color(0xFFF59E0B));
      });

      test('returns blue for age 5+', () {
        expect(WHOGuidelines.getColor(5), const Color(0xFF3B82F6));
        expect(WHOGuidelines.getColor(15), const Color(0xFF3B82F6));
      });
    });

    group('isExceedingRecommendation', () {
      test('infant with any screen time exceeds', () {
        expect(WHOGuidelines.isExceedingRecommendation(0, 1), isTrue);
        expect(WHOGuidelines.isExceedingRecommendation(0, 30), isTrue);
      });

      test('infant with 0 minutes does not exceed', () {
        expect(WHOGuidelines.isExceedingRecommendation(0, 0), isFalse);
      });

      test('toddler at limit does not exceed', () {
        expect(WHOGuidelines.isExceedingRecommendation(2, 60), isFalse);
      });

      test('toddler over limit exceeds', () {
        expect(WHOGuidelines.isExceedingRecommendation(2, 61), isTrue);
      });

      test('school age at limit does not exceed', () {
        expect(WHOGuidelines.isExceedingRecommendation(8, 120), isFalse);
      });

      test('school age over limit exceeds', () {
        expect(WHOGuidelines.isExceedingRecommendation(8, 121), isTrue);
      });

      test('teen under limit does not exceed', () {
        expect(WHOGuidelines.isExceedingRecommendation(15, 100), isFalse);
      });
    });
  });
}
