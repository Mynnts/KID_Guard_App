import 'package:flutter/material.dart';

/// WHO Screen Time Recommendation data class
class WHORecommendation {
  final String ageGroup;
  final String recommendation;
  final String details;
  final int maxMinutes;
  final bool showWarning;

  const WHORecommendation({
    required this.ageGroup,
    required this.recommendation,
    required this.details,
    required this.maxMinutes,
    this.showWarning = false,
  });
}

/// Utility class for WHO Screen Time Guidelines
class WHOGuidelines {
  /// Get WHO recommendation based on child's age
  static WHORecommendation getRecommendation(int age) {
    if (age < 1) {
      return const WHORecommendation(
        ageGroup: 'ทารก (0-1 ปี)',
        recommendation: 'ไม่ควรมีเวลาหน้าจอ',
        details: 'ควรให้ทารกเล่นบนพื้นและมีปฏิสัมพันธ์กับผู้ดูแล',
        maxMinutes: 0,
        showWarning: true,
      );
    } else if (age <= 2) {
      return const WHORecommendation(
        ageGroup: '1-2 ปี',
        recommendation: 'ไม่เกิน 1 ชั่วโมง',
        details: 'ยิ่งน้อยยิ่งดี ควรเป็นเนื้อหาที่เหมาะสม',
        maxMinutes: 60,
        showWarning: true,
      );
    } else if (age <= 4) {
      return const WHORecommendation(
        ageGroup: '3-4 ปี',
        recommendation: 'ไม่เกิน 1 ชั่วโมง',
        details: 'ยิ่งน้อยยิ่งดีต่อพัฒนาการ',
        maxMinutes: 60,
        showWarning: false,
      );
    } else if (age <= 12) {
      return const WHORecommendation(
        ageGroup: '5-12 ปี',
        recommendation: 'ไม่เกิน 2 ชั่วโมง',
        details: 'ควรมีกิจกรรมอื่นที่หลากหลาย',
        maxMinutes: 120,
        showWarning: false,
      );
    } else {
      return const WHORecommendation(
        ageGroup: '13+ ปี',
        recommendation: 'ควบคุมอย่างเหมาะสม',
        details: 'สร้างสมดุลระหว่างหน้าจอและกิจกรรมอื่น',
        maxMinutes: 120,
        showWarning: false,
      );
    }
  }

  /// Get icon based on age group
  static IconData getIcon(int age) {
    if (age < 1) return Icons.warning_rounded;
    if (age <= 2) return Icons.child_care_rounded;
    if (age <= 4) return Icons.face_rounded;
    if (age <= 12) return Icons.school_rounded;
    return Icons.person_rounded;
  }

  /// Get color based on max time recommendation
  static Color getColor(int age) {
    if (age < 1) return const Color(0xFFEF4444); // Red - no screen time
    if (age <= 2) return const Color(0xFFF59E0B); // Orange - limited
    if (age <= 4) return const Color(0xFFF59E0B); // Orange - limited
    return const Color(0xFF3B82F6); // Blue - moderate
  }

  /// Get gradient colors for the card
  static List<Color> getGradientColors(int age) {
    if (age < 1) {
      return [
        const Color(0xFFEF4444).withValues(alpha: 0.15),
        const Color(0xFFF87171).withValues(alpha: 0.08),
      ];
    } else if (age <= 4) {
      return [
        const Color(0xFFF59E0B).withValues(alpha: 0.15),
        const Color(0xFFFBBF24).withValues(alpha: 0.08),
      ];
    } else {
      return [
        const Color(0xFF3B82F6).withValues(alpha: 0.12),
        const Color(0xFF60A5FA).withValues(alpha: 0.06),
      ];
    }
  }

  /// Check if the set time exceeds WHO recommendation
  static bool isExceedingRecommendation(int age, int setMinutes) {
    final recommendation = getRecommendation(age);
    if (recommendation.maxMinutes == 0 && setMinutes > 0) return true;
    if (setMinutes > recommendation.maxMinutes) return true;
    return false;
  }
}
