import 'package:flutter/material.dart';

/// Responsive sizing utility สำหรับปรับขนาด UI ตามหน้าจอของอุปกรณ์
/// อ้างอิงจากขนาดหน้าจอมาตรฐาน 393 × 852 logical pixels (~6" Android)
class ResponsiveHelper {
  final double screenWidth;
  final double screenHeight;

  // Reference design dimensions (standard ~6" Android phone)
  static const double _designWidth = 393.0;
  static const double _designHeight = 852.0;

  // Scale factors with clamping to prevent extreme scaling
  late final double _widthScale;
  late final double _heightScale;

  ResponsiveHelper._({required this.screenWidth, required this.screenHeight}) {
    _widthScale = (screenWidth / _designWidth).clamp(0.85, 1.3);
    _heightScale = (screenHeight / _designHeight).clamp(0.85, 1.3);
  }

  /// สร้าง instance จาก BuildContext
  factory ResponsiveHelper.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ResponsiveHelper._(
      screenWidth: size.width,
      screenHeight: size.height,
    );
  }

  /// ปรับขนาดตัวอักษร (scale proportionally)
  double sp(double size) => size * _widthScale;

  /// ปรับค่าแนวนอน (padding, width, margin)
  double wp(double size) => size * _widthScale;

  /// ปรับค่าแนวตั้ง (height, vertical spacing)
  double hp(double size) => size * _heightScale;

  /// ปรับขนาดไอคอน
  double iconSize(double size) => size * _widthScale;

  /// ปรับ border radius
  double radius(double size) => size * _widthScale;

  /// จำนวนคอลัมน์ Grid ตามความกว้างหน้าจอ
  int get gridCrossAxisCount {
    if (screenWidth >= 900) return 4;
    if (screenWidth >= 600) return 3;
    return 2;
  }

  /// Horizontal padding หลักของหน้าจอ
  double get horizontalPadding {
    if (screenWidth >= 600) return 32.0;
    if (screenWidth >= 360) return 20.0;
    return 16.0;
  }

  /// Child aspect ratio สำหรับ Quick Actions grid
  double get quickActionAspectRatio {
    if (screenWidth >= 600) return 1.8;
    return 1.5;
  }
}
