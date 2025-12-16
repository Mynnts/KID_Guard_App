import 'package:flutter/material.dart';

class LockScreen extends StatelessWidget {
  final String? reason;

  const LockScreen({super.key, this.reason});

  // Get icon based on reason
  IconData _getIcon() {
    if (reason != null) {
      if (reason!.contains('นอน') || reason!.contains('🌙')) {
        return Icons.bedtime_outlined;
      } else if (reason!.contains('พัก') || reason!.contains('🔕')) {
        return Icons.do_not_disturb_on_outlined;
      }
    }
    return Icons.lock_clock_outlined;
  }

  // Get title based on reason
  String _getTitle() {
    if (reason != null) {
      if (reason!.contains('นอน') || reason!.contains('🌙')) {
        return 'ถึงเวลานอนแล้ว 🌙';
      } else if (reason!.contains('พัก') || reason!.contains('🔕')) {
        return 'เวลาพักผ่อน 🔕';
      }
    }
    return 'พักผ่อนหน่อยนะ';
  }

  // Get subtitle based on reason
  String _getSubtitle() {
    if (reason != null) {
      if (reason!.contains('นอน') || reason!.contains('🌙')) {
        return 'ราตรีสวัสดิ์! พรุ่งนี้เจอกันใหม่นะ';
      } else if (reason!.contains('พัก') || reason!.contains('🔕')) {
        return 'พักสายตาสักครู่นะ';
      } else if (reason!.contains('หมดเวลา') || reason!.contains('⏰')) {
        return 'ใช้งานครบตามเวลาที่กำหนดแล้ว';
      }
    }
    return 'ถึงเวลาพักแล้ว!';
  }

  // Get gradient colors based on reason
  List<Color> _getGradientColors() {
    if (reason != null) {
      if (reason!.contains('นอน') || reason!.contains('🌙')) {
        return [const Color(0xFF1A1A2E), const Color(0xFF0F0E17)];
      } else if (reason!.contains('พัก') || reason!.contains('🔕')) {
        return [const Color(0xFF2D3A4F), const Color(0xFF1A1A2E)];
      }
    }
    return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
  }

  @override
  Widget build(BuildContext context) {
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
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stars decoration for sleep mode
                    if (reason != null &&
                        (reason!.contains('นอน') ||
                            reason!.contains('🌙'))) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStar(8, 0.5),
                          const SizedBox(width: 30),
                          _buildStar(12, 0.8),
                          const SizedBox(width: 20),
                          _buildStar(6, 0.4),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _getIcon(),
                        size: 56,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      _getTitle(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 64),

                    // Button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'กรุณาติดต่อผู้ปกครองเพื่อปลดล็อค',
                            ),
                            backgroundColor: const Color(0xFFE67E22),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.key_outlined,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ขอปลดล็อค',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStar(double size, double opacity) {
    return Icon(
      Icons.star,
      size: size,
      color: Colors.white.withOpacity(opacity),
    );
  }
}
