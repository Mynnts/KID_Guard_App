import 'dart:ui';
import 'package:flutter/material.dart';
import 'widgets/sleepy_bear_widget.dart';
import 'widgets/floating_elements.dart';

/// Friendly Lock Screen - Child-friendly lock screen with sleepy bear mascot
class FriendlyLockScreen extends StatefulWidget {
  final String? reason;

  const FriendlyLockScreen({super.key, this.reason});

  @override
  State<FriendlyLockScreen> createState() => _FriendlyLockScreenState();
}

class _FriendlyLockScreenState extends State<FriendlyLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Get theme based on reason
  _LockTheme _getTheme() {
    if (widget.reason != null) {
      if (widget.reason!.contains('นอน') || widget.reason!.contains('🌙')) {
        return _LockTheme.sleep;
      } else if (widget.reason!.contains('พัก') ||
          widget.reason!.contains('🔕')) {
        return _LockTheme.quiet;
      }
    }
    return _LockTheme.timeLimit;
  }

  // Get title based on reason
  String _getTitle() {
    final theme = _getTheme();
    switch (theme) {
      case _LockTheme.sleep:
        return 'ถึงเวลานอนแล้วจ้า 🌙';
      case _LockTheme.quiet:
        return 'ช่วงเวลาพักผ่อน 🌸';
      case _LockTheme.timeLimit:
        return 'เก่งมากวันนี้! ⭐';
    }
  }

  // Get subtitle based on reason
  String _getSubtitle() {
    final theme = _getTheme();
    switch (theme) {
      case _LockTheme.sleep:
        return 'ราตรีสวัสดิ์ พรุ่งนี้เจอกันนะ';
      case _LockTheme.quiet:
        return 'ไปทำกิจกรรมอื่นกันเถอะ';
      case _LockTheme.timeLimit:
        return 'พักผ่อนสักหน่อยนะ';
    }
  }

  // Get gradient colors based on theme
  List<Color> _getGradientColors() {
    final theme = _getTheme();
    switch (theme) {
      case _LockTheme.sleep:
        return [
          const Color(0xFF1A1B3D),
          const Color(0xFF2D1F5E),
          const Color(0xFF1A1B3D),
        ];
      case _LockTheme.quiet:
        return [
          const Color(0xFF2D3A4A),
          const Color(0xFF3D5A6A),
          const Color(0xFF2D3A4A),
        ];
      case _LockTheme.timeLimit:
        return [
          const Color(0xFF2D2A4A),
          const Color(0xFF4A3D6A),
          const Color(0xFF2D2A4A),
        ];
    }
  }

  // Get accent color
  Color _getAccentColor() {
    final theme = _getTheme();
    switch (theme) {
      case _LockTheme.sleep:
        return const Color(0xFF9C88FF);
      case _LockTheme.quiet:
        return const Color(0xFF4DD0E1);
      case _LockTheme.timeLimit:
        return const Color(0xFFF48FB1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();

    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getGradientColors(),
            ),
          ),
          child: Stack(
            children: [
              // Floating elements (stars, moon, clouds)
              const FloatingElements(),

              // Main content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Sleepy Bear
                          const SleepyBearWidget(isSleeping: true, size: 200),

                          const SizedBox(height: 40),

                          // Glassmorphism card with message
                          _buildMessageCard(accentColor),

                          const SizedBox(height: 32),

                          // Unlock request button
                          _buildUnlockButton(accentColor),

                          const SizedBox(height: 20),

                          // Small hint text
                          Text(
                            'ขอให้ผู้ปกครองปลดล็อคได้นะ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Title
              Text(
                _getTitle(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                _getSubtitle(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockButton(Color accentColor) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'ส่งคำขอไปหาพ่อแม่แล้วนะ 💝',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Text(
              'ขอเวลาเพิ่ม',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LockTheme { sleep, quiet, timeLimit }
