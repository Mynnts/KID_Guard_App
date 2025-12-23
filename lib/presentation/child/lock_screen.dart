import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class LockScreen extends StatefulWidget {
  final String? reason;

  const LockScreen({super.key, this.reason});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _glowAnimation;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // Icon glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Generate random particles
    _particles = List.generate(15, (index) => _Particle.random());
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  // Get icon based on reason
  IconData _getIcon() {
    if (widget.reason != null) {
      if (widget.reason!.contains('นอน') || widget.reason!.contains('🌙')) {
        return Icons.bedtime_rounded;
      } else if (widget.reason!.contains('พัก') ||
          widget.reason!.contains('🔕')) {
        return Icons.do_not_disturb_rounded;
      }
    }
    return Icons.lock_rounded;
  }

  // Get title based on reason
  String _getTitle() {
    if (widget.reason != null) {
      if (widget.reason!.contains('นอน') || widget.reason!.contains('🌙')) {
        return 'ถึงเวลานอนแล้ว';
      } else if (widget.reason!.contains('พัก') ||
          widget.reason!.contains('🔕')) {
        return 'เวลาพักผ่อน';
      }
    }
    return 'พักผ่อนหน่อยนะ';
  }

  // Get subtitle based on reason
  String _getSubtitle() {
    if (widget.reason != null) {
      if (widget.reason!.contains('นอน') || widget.reason!.contains('🌙')) {
        return 'ราตรีสวัสดิ์ พรุ่งนี้เจอกันใหม่นะ';
      } else if (widget.reason!.contains('พัก') ||
          widget.reason!.contains('🔕')) {
        return 'พักสายตาสักครู่นะ';
      } else if (widget.reason!.contains('หมดเวลา') ||
          widget.reason!.contains('⏰')) {
        return 'ใช้งานครบตามเวลาที่กำหนดแล้ว';
      }
    }
    return 'ถึงเวลาพักแล้ว';
  }

  // Get accent color based on reason
  Color _getAccentColor() {
    if (widget.reason != null) {
      if (widget.reason!.contains('นอน') || widget.reason!.contains('🌙')) {
        return const Color(0xFF7C4DFF); // Purple for sleep
      } else if (widget.reason!.contains('พัก') ||
          widget.reason!.contains('🔕')) {
        return const Color(0xFF448AFF); // Blue for quiet
      }
    }
    return const Color(0xFF6C63FF); // Default purple blue
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();

    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0A0F), Color(0xFF12101A), Color(0xFF1A1025)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated particles background
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                      accentColor: accentColor,
                    ),
                  );
                },
              ),

              // Gradient overlay for depth
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [accentColor.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Glassmorphism card
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 20,
                                      sigmaY: 20,
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _glowAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: 48,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              32,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: accentColor.withOpacity(
                                                  0.1 +
                                                      (_glowAnimation.value *
                                                          0.05),
                                                ),
                                                blurRadius: 40,
                                                spreadRadius: -5,
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Animated icon with glow
                                              _buildAnimatedIcon(accentColor),

                                              const SizedBox(height: 32),

                                              // Title
                                              Text(
                                                _getTitle(),
                                                style: TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white
                                                      .withOpacity(0.95),
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
                                                  fontSize: 15,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 0.2,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Modern glass button
                                _buildUnlockButton(accentColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(Color accentColor) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.3),
                accentColor.withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(
                  0.3 + (_glowAnimation.value * 0.2),
                ),
                blurRadius: 30 + (_glowAnimation.value * 15),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 60,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Icon(
            _getIcon(),
            size: 44,
            color: Colors.white.withOpacity(0.9),
          ),
        );
      },
    );
  }

  Widget _buildUnlockButton(Color accentColor) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'กรุณาติดต่อผู้ปกครองเพื่อปลดล็อค',
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'ขอปลดล็อค',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Particle model
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  factory _Particle.random() {
    final random = Random();
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 3 + 1,
      speed: random.nextDouble() * 0.5 + 0.2,
      opacity: random.nextDouble() * 0.4 + 0.1,
    );
  }
}

// Particle painter
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color accentColor;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final yOffset = (progress * particle.speed) % 1.0;
      final y = ((particle.y + yOffset) % 1.0) * size.height;
      final x = particle.x * size.width;

      final paint = Paint()
        ..color = accentColor.withOpacity(particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
