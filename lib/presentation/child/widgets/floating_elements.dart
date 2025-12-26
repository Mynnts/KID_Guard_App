import 'dart:math';
import 'package:flutter/material.dart';

/// Floating elements for the lock screen (stars, moon, clouds)
class FloatingElements extends StatefulWidget {
  final String theme; // 'sleep', 'timelimit', 'quiet'

  const FloatingElements({super.key, this.theme = 'sleep'});

  @override
  State<FloatingElements> createState() => _FloatingElementsState();
}

class _FloatingElementsState extends State<FloatingElements>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _cloudController;
  late List<_Star> _stars;
  late List<_Cloud> _clouds;

  @override
  void initState() {
    super.initState();

    // Star twinkling animation
    _starController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Cloud floating animation
    _cloudController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Generate random stars
    _stars = List.generate(15, (index) => _Star.random());

    // Generate clouds
    _clouds = [
      _Cloud(x: 0.1, y: 0.15, size: 60, speed: 0.3),
      _Cloud(x: 0.7, y: 0.25, size: 45, speed: 0.5),
      _Cloud(x: 0.4, y: 0.1, size: 50, speed: 0.4),
    ];
  }

  @override
  void dispose() {
    _starController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Moon
        Positioned(top: 60, right: 40, child: _buildMoon()),

        // Stars
        ..._stars.map((star) => _buildStar(star)),

        // Clouds
        ..._clouds.map((cloud) => _buildCloud(cloud)),
      ],
    );
  }

  Widget _buildMoon() {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) {
        final glow = 0.3 + (sin(_starController.value * 2 * pi) * 0.1);
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFF9C4),
                const Color(0xFFFFEB3B).withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFF176).withOpacity(glow),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFFFFEB3B).withOpacity(glow * 0.5),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Moon crater 1
              Positioned(
                top: 15,
                left: 20,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE082).withOpacity(0.5),
                  ),
                ),
              ),
              // Moon crater 2
              Positioned(
                bottom: 20,
                right: 15,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE082).withOpacity(0.4),
                  ),
                ),
              ),
            ],
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
        final opacity = 0.3 + (twinkle * 0.4 + 0.4);
        final scale = 0.8 + (twinkle * 0.2 + 0.2);

        return Positioned(
          left: star.x * MediaQuery.of(context).size.width,
          top: star.y * MediaQuery.of(context).size.height * 0.6,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.1, 1.0),
              child: Icon(
                star.isBig ? Icons.star_rounded : Icons.star_outline_rounded,
                size: star.size,
                color: star.isBig
                    ? const Color(0xFFFFF9C4)
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCloud(_Cloud cloud) {
    return AnimatedBuilder(
      animation: _cloudController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final offset = (_cloudController.value * cloud.speed) % 1.2;
        final xPos = (cloud.x + offset) * screenWidth;
        final adjustedX = xPos > screenWidth + cloud.size
            ? xPos - screenWidth - cloud.size * 2
            : xPos;

        return Positioned(
          left: adjustedX,
          top: cloud.y * MediaQuery.of(context).size.height,
          child: Opacity(opacity: 0.6, child: _CloudShape(size: cloud.size)),
        );
      },
    );
  }
}

class _CloudShape extends StatelessWidget {
  final double size;

  const _CloudShape({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: size * 0.8,
              height: size * 0.6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Positioned(
            left: size * 0.3,
            bottom: size * 0.2,
            child: Container(
              width: size,
              height: size * 0.8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.7,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ],
      ),
    );
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
      size: random.nextDouble() * 12 + 8,
      delay: random.nextDouble(),
      isBig: random.nextBool(),
    );
  }
}

// Cloud model
class _Cloud {
  final double x;
  final double y;
  final double size;
  final double speed;

  _Cloud({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}
