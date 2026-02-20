import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Ultra cute floating elements for dreamy lock screen
/// Features: soft twinkling stars, glowing moon, pastel clouds, floating hearts
class FloatingElements extends StatefulWidget {
  const FloatingElements({super.key});

  @override
  State<FloatingElements> createState() => _FloatingElementsState();
}

class _FloatingElementsState extends State<FloatingElements>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _cloudController;
  late AnimationController _heartController;
  late AnimationController _auroraController;
  late List<_Star> _stars;
  late List<_Cloud> _clouds;
  late List<_FloatingHeart> _hearts;

  @override
  void initState() {
    super.initState();

    // Star twinkling animation
    _starController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Cloud floating animation
    _cloudController = AnimationController(
      duration: const Duration(seconds: 50),
      vsync: this,
    )..repeat();

    // Heart floating animation
    _heartController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    // Aurora wave animation
    _auroraController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Generate soft stars (more for dreamy effect)
    _stars = List.generate(25, (index) => _Star.random());

    // Generate floating hearts
    _hearts = List.generate(6, (index) => _FloatingHeart.random());

    // Generate soft fluffy clouds
    _clouds = [
      _Cloud(x: 0.0, y: 0.08, size: 50, speed: 0.15, opacity: 0.4),
      _Cloud(x: 0.6, y: 0.15, size: 35, speed: 0.25, opacity: 0.3),
      _Cloud(x: 0.3, y: 0.05, size: 45, speed: 0.2, opacity: 0.35),
      _Cloud(x: 0.8, y: 0.2, size: 38, speed: 0.18, opacity: 0.25),
    ];
  }

  @override
  void dispose() {
    _starController.dispose();
    _cloudController.dispose();
    _heartController.dispose();
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Soft aurora background effect
        _buildAuroraEffect(),

        // Moon with soft glow
        Positioned(top: 45, right: 30, child: _buildMoon()),

        // Soft twinkling stars
        ..._stars.map((star) => _buildStar(star)),

        // Floating hearts
        ..._hearts.map((heart) => _buildFloatingHeart(heart)),

        // Soft fluffy clouds
        ..._clouds.map((cloud) => _buildCloud(cloud)),
      ],
    );
  }

  Widget _buildAuroraEffect() {
    return AnimatedBuilder(
      animation: _auroraController,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: _AuroraPainter(progress: _auroraController.value),
          ),
        );
      },
    );
  }

  Widget _buildMoon() {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) {
        final glow = 0.5 + (sin(_starController.value * 2 * pi) * 0.2);

        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFFFF9E6), Color(0xFFFFECB3), Color(0xFFFFE082)],
              stops: [0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFE082).withOpacity(glow),
                blurRadius: 35,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: const Color(0xFFFFF9E6).withOpacity(glow * 0.8),
                blurRadius: 50,
                spreadRadius: 15,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Moon face - sleeping
              Positioned(
                left: 18,
                top: 22,
                child: Container(
                  width: 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0A030).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 22,
                child: Container(
                  width: 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0A030).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Tiny blush
              Positioned(
                left: 12,
                top: 32,
                child: Container(
                  width: 10,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB6C1).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 32,
                child: Container(
                  width: 10,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB6C1).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloud(_Cloud cloud) {
    return AnimatedBuilder(
      animation: _cloudController,
      builder: (context, child) {
        final xOffset =
            ((_cloudController.value * cloud.speed + cloud.x) % 1.3) - 0.15;

        return Positioned(
          left: xOffset * MediaQuery.of(context).size.width,
          top: cloud.y * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: cloud.opacity,
            child: _SoftCloud(size: cloud.size),
          ),
        );
      },
    );
  }

  Widget _buildStar(_Star star) {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) {
        final twinkle = sin((_starController.value + star.delay) * 2 * pi);
        final opacity = 0.4 + (twinkle * 0.4 + 0.2);
        final scale = 0.7 + (twinkle * 0.3 + 0.3);

        return Positioned(
          left: star.x * MediaQuery.of(context).size.width,
          top: star.y * MediaQuery.of(context).size.height * 0.55,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.2, 0.95),
              child: Container(
                width: star.size,
                height: star.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: star.isBig ? const Color(0xFFFFF9E6) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: star.isBig
                          ? const Color(0xFFFFE082).withOpacity(0.8)
                          : Colors.white.withOpacity(0.6),
                      blurRadius: star.isBig ? 12 : 6,
                      spreadRadius: star.isBig ? 3 : 1,
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

  Widget _buildFloatingHeart(_FloatingHeart heart) {
    return AnimatedBuilder(
      animation: _heartController,
      builder: (context, child) {
        final progress = ((_heartController.value + heart.delay) % 1.0);
        final yOffset = heart.y - (progress * 0.15);
        final opacity = progress < 0.3
            ? progress / 0.3
            : progress > 0.7
            ? (1.0 - progress) / 0.3
            : 1.0;
        final scale = 0.8 + (sin(progress * pi * 2) * 0.2);

        return Positioned(
          left: heart.x * MediaQuery.of(context).size.width,
          top: yOffset * MediaQuery.of(context).size.height,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: (opacity * heart.opacity).clamp(0.0, 0.7),
              child: Icon(
                Icons.favorite,
                size: heart.size,
                color: heart.color,
                shadows: [
                  Shadow(color: heart.color.withOpacity(0.5), blurRadius: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Soft fluffy cloud widget
class _SoftCloud extends StatelessWidget {
  final double size;

  const _SoftCloud({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          width: size * 2.2,
          height: size,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.9,
                  height: size * 0.65,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
              Positioned(
                left: size * 0.4,
                bottom: size * 0.15,
                child: Container(
                  width: size * 1.1,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.8,
                  height: size * 0.55,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Aurora effect painter for dreamy background
class _AuroraPainter extends CustomPainter {
  final double progress;

  _AuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Soft aurora wave 1 (purple-pink)
    final path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    for (var i = 0; i <= size.width; i += 10) {
      final y =
          size.height * 0.2 +
          sin((i / size.width * 2 * pi) + (progress * 2 * pi)) * 30 +
          sin((i / size.width * 4 * pi) + (progress * 4 * pi)) * 15;
      path1.lineTo(i.toDouble(), y);
    }
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE8B4F8).withOpacity(0.15),
        const Color(0xFFB388EB).withOpacity(0.08),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.3));

    canvas.drawPath(path1, paint);

    // Soft aurora wave 2 (blue-purple)
    final path2 = Path();
    path2.moveTo(0, size.height * 0.35);
    for (var i = 0; i <= size.width; i += 10) {
      final y =
          size.height * 0.35 +
          sin((i / size.width * 3 * pi) + (progress * 2 * pi) + pi / 2) * 25 +
          cos((i / size.width * 2 * pi) + (progress * 3 * pi)) * 20;
      path2.lineTo(i.toDouble(), y);
    }
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF88C8F8).withOpacity(0.12),
        const Color(0xFFB8A0E8).withOpacity(0.06),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4));

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Star model
class _Star {
  final double x;
  final double y;
  final double size;
  final double delay;
  final bool isBig;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.isBig,
  });

  factory _Star.random() {
    final random = Random();
    return _Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 4 + 2,
      delay: random.nextDouble(),
      isBig: random.nextDouble() > 0.75,
    );
  }
}

// Cloud model
class _Cloud {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Cloud({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Floating heart model
class _FloatingHeart {
  final double x;
  final double y;
  final double size;
  final double delay;
  final double opacity;
  final Color color;

  _FloatingHeart({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.opacity,
    required this.color,
  });

  factory _FloatingHeart.random() {
    final random = Random();
    final colors = [
      const Color(0xFFFFB6C1), // Light pink
      const Color(0xFFFF8FAB), // Pink
      const Color(0xFFE8B4F8), // Light purple
      const Color(0xFFF8BBD0), // Pastel pink
    ];
    return _FloatingHeart(
      x: random.nextDouble() * 0.9 + 0.05,
      y: random.nextDouble() * 0.4 + 0.2,
      size: random.nextDouble() * 14 + 10,
      delay: random.nextDouble(),
      opacity: random.nextDouble() * 0.4 + 0.3,
      color: colors[random.nextInt(colors.length)],
    );
  }
}
