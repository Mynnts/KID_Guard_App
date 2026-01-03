import 'dart:ui';
import 'package:flutter/material.dart';
import 'widgets/sleepy_bear_widget.dart';
import 'widgets/floating_elements.dart';

/// Ultra Cute Friendly Lock Screen for kids
/// Features dreamy pastel colors, sleeping bear on cloud, floating hearts
class FriendlyLockScreen extends StatefulWidget {
  final String? reason;

  const FriendlyLockScreen({super.key, this.reason});

  @override
  State<FriendlyLockScreen> createState() => _FriendlyLockScreenState();
}

class _FriendlyLockScreenState extends State<FriendlyLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

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

    // Gentle pulse for message card
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Soft glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Helper to get theme
  _LockTheme _getTheme() {
    if (widget.reason != null) {
      if (widget.reason!.contains('นอน') || widget.reason!.contains('🌙')) {
        return _LockTheme.sleep;
      } else if (widget.reason!.contains('พัก') ||
          widget.reason!.contains('🔕')) {
        return _LockTheme.quiet;
      } else if (widget.reason!.contains('หมดเวลา') ||
          widget.reason!.contains('⏰')) {
        return _LockTheme.timeLimit;
      }
    }
    return _LockTheme.timeLimit;
  }

  // Cute titles with emojis
  String _getTitle() {
    switch (_getTheme()) {
      case _LockTheme.sleep:
        return 'ฝันดีนะตัวน้อย 🌙';
      case _LockTheme.quiet:
        return 'พักผ่อนกันเถอะ 🌸';
      case _LockTheme.timeLimit:
        return 'เก่งมากวันนี้! ⭐';
    }
  }

  // Friendly subtitles
  String _getSubtitle() {
    switch (_getTheme()) {
      case _LockTheme.sleep:
        return 'พรุ่งนี้เจอกันใหม่นะ ✨';
      case _LockTheme.quiet:
        return 'ไปทำกิจกรรมสนุกๆ กันเถอะ';
      case _LockTheme.timeLimit:
        return 'พักสายตาสักครู่นะ 💕';
    }
  }

  // Soft pastel gradients
  List<Color> _getGradientColors() {
    switch (_getTheme()) {
      case _LockTheme.sleep:
        return [
          const Color(0xFF1E1B4B),
          const Color(0xFF312E81),
          const Color(0xFF3730A3),
          const Color(0xFF1E1B4B),
        ];
      case _LockTheme.quiet:
        return [
          const Color(0xFF164E63),
          const Color(0xFF155E75),
          const Color(0xFF0E7490),
          const Color(0xFF164E63),
        ];
      case _LockTheme.timeLimit:
        return [
          const Color(0xFF4C1D95),
          const Color(0xFF5B21B6),
          const Color(0xFF6D28D9),
          const Color(0xFF4C1D95),
        ];
    }
  }

  // Soft accent colors
  Color _getAccentColor() {
    switch (_getTheme()) {
      case _LockTheme.sleep:
        return const Color(0xFFC4B5FD);
      case _LockTheme.quiet:
        return const Color(0xFF67E8F9);
      case _LockTheme.timeLimit:
        return const Color(0xFFFBCFE8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;

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
              // Floating elements (stars, moon, clouds, hearts)
              const FloatingElements(),

              // Main content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 60 : 24,
                        vertical: isTablet ? 50 : 30,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 550 : double.infinity,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Cute Sleepy Bear on Cloud
                            SleepyBearWidget(
                              isSleeping: true,
                              size: isTablet ? 220 : 180,
                            ),

                            SizedBox(height: isTablet ? 35 : 25),

                            // Glassmorphism message card with glow
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _pulseAnimation,
                                _glowAnimation,
                              ]),
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: _buildMessageCard(
                                    accentColor,
                                    isTablet,
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: isTablet ? 30 : 22),

                            // Cute unlock request button
                            _buildUnlockButton(accentColor, isTablet),

                            SizedBox(height: isTablet ? 20 : 14),

                            // Friendly hint text
                            Text(
                              'ขอให้พ่อแม่ปลดล็อคได้นะ 🙏',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildMessageCard(Color accentColor, bool isTablet) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 32 : 26),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(_glowAnimation.value * 0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isTablet ? 32 : 26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 28,
                  vertical: isTablet ? 32 : 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 32 : 26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Title with emoji
                    Text(
                      _getTitle(),
                      style: TextStyle(
                        fontSize: isTablet ? 28 : 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isTablet ? 12 : 10),

                    // Subtitle
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        fontSize: isTablet ? 17 : 15,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnlockButton(Color accentColor, bool isTablet) {
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
            backgroundColor: accentColor.withOpacity(0.9),
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
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 40 : 32,
          vertical: isTablet ? 18 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accentColor, accentColor.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: isTablet ? 22 : 20,
            ),
            const SizedBox(width: 10),
            Text(
              'ขอเวลาเพิ่มหน่อยนะ',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 17 : 15,
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
