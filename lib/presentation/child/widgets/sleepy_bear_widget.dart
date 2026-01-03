import 'dart:math';
import 'package:flutter/material.dart';

/// Ultra Cute Sleepy Bear Widget - Adorable bear mascot for kids lock screen
/// Features: sleeping on cloud, night cap, heart pillow, rosy cheeks
class SleepyBearWidget extends StatefulWidget {
  final bool isSleeping;
  final double size;

  const SleepyBearWidget({super.key, this.isSleeping = true, this.size = 180});

  @override
  State<SleepyBearWidget> createState() => _SleepyBearWidgetState();
}

class _SleepyBearWidgetState extends State<SleepyBearWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _floatController;
  late AnimationController _zzzController;
  late AnimationController _heartController;
  late Animation<double> _breathAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();

    // Gentle breathing animation
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Floating on cloud animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Heart pulse animation
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    // ZZZ floating animation
    _zzzController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _floatController.dispose();
    _zzzController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.4,
      height: widget.size * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floating heart decorations
          ..._buildFloatingHearts(),

          // Main bear with cloud
          AnimatedBuilder(
            animation: Listenable.merge([_breathAnimation, _floatAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: Transform.scale(
                  scale: _breathAnimation.value,
                  child: _buildBearOnCloud(),
                ),
              );
            },
          ),

          // ZZZ bubbles
          if (widget.isSleeping) ..._buildZzzBubbles(),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingHearts() {
    return [
      _buildFloatingHeart(-widget.size * 0.5, -widget.size * 0.3, 0.0, 12),
      _buildFloatingHeart(widget.size * 0.45, -widget.size * 0.2, 0.3, 10),
      _buildFloatingHeart(-widget.size * 0.4, widget.size * 0.3, 0.6, 8),
      _buildFloatingHeart(widget.size * 0.5, widget.size * 0.2, 0.9, 11),
    ];
  }

  Widget _buildFloatingHeart(double x, double y, double delay, double size) {
    return AnimatedBuilder(
      animation: _heartController,
      builder: (context, child) {
        final progress = ((_heartController.value + delay) % 1.0);
        final opacity = 0.3 + (sin(progress * 3.14159 * 2) * 0.3);
        final scale = 0.8 + (sin(progress * 3.14159 * 2) * 0.2);

        return Positioned(
          left: widget.size * 0.7 + x,
          top: widget.size * 0.5 + y,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.2, 0.7),
              child: Icon(
                Icons.favorite,
                size: size,
                color: const Color(0xFFFFB6C1),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBearOnCloud() {
    final size = widget.size;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Cloud pillow (behind bear)
        Positioned(bottom: 0, child: _buildCloud(size)),

        // Bear sleeping on cloud
        Positioned(bottom: size * 0.12, child: _buildCuteBear(size)),

        // Heart pillow
        Positioned(
          bottom: size * 0.18,
          left: size * 0.15,
          child: AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _heartAnimation.value,
                child: _buildHeartPillow(size * 0.22),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCloud(double size) {
    return Container(
      width: size * 1.3,
      height: size * 0.45,
      child: Stack(
        children: [
          // Main cloud body
          Positioned(
            left: size * 0.15,
            bottom: 0,
            child: Container(
              width: size * 1.0,
              height: size * 0.35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    const Color(0xFFF0F4FF).withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(size * 0.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8E0FF).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          // Cloud bumps (left)
          Positioned(
            left: 0,
            bottom: size * 0.08,
            child: Container(
              width: size * 0.35,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Cloud bumps (right)
          Positioned(
            right: 0,
            bottom: size * 0.06,
            child: Container(
              width: size * 0.32,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Cloud bump (center top)
          Positioned(
            left: size * 0.45,
            bottom: size * 0.2,
            child: Container(
              width: size * 0.4,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuteBear(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Bear body (laying down)
        Container(
          width: size * 0.55,
          height: size * 0.4,
          margin: EdgeInsets.only(top: size * 0.2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8C99B), Color(0xFFD4A574)],
            ),
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A574).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),

        // Bear belly spot
        Container(
          width: size * 0.32,
          height: size * 0.25,
          margin: EdgeInsets.only(top: size * 0.22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5E6),
            borderRadius: BorderRadius.circular(size * 0.15),
          ),
        ),

        // Bear head
        Container(
          width: size * 0.52,
          height: size * 0.48,
          margin: EdgeInsets.only(bottom: size * 0.25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0D9B5), Color(0xFFE8C99B)],
            ),
            borderRadius: BorderRadius.circular(size * 0.26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A574).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Left ear
              Positioned(
                left: -size * 0.02,
                top: -size * 0.04,
                child: _buildEar(size * 0.16),
              ),
              // Right ear
              Positioned(
                right: -size * 0.02,
                top: -size * 0.04,
                child: _buildEar(size * 0.16),
              ),
              // Night cap
              Positioned(
                right: -size * 0.08,
                top: -size * 0.1,
                child: _buildNightCap(size * 0.28),
              ),
              // Face
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size * 0.06),
                  // Closed eyes (sleeping)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSleepingEye(size * 0.1),
                      SizedBox(width: size * 0.1),
                      _buildSleepingEye(size * 0.1),
                    ],
                  ),
                  SizedBox(height: size * 0.04),
                  // Cute muzzle with nose
                  _buildMuzzle(size),
                ],
              ),
              // Rosy cheeks
              Positioned(
                left: size * 0.04,
                top: size * 0.24,
                child: _buildBlush(size * 0.1),
              ),
              Positioned(
                right: size * 0.04,
                top: size * 0.24,
                child: _buildBlush(size * 0.1),
              ),
            ],
          ),
        ),

        // Tiny paw reaching forward
        Positioned(
          left: size * 0.05,
          bottom: size * 0.35,
          child: _buildPaw(size * 0.12),
        ),
      ],
    );
  }

  Widget _buildEar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0D9B5), Color(0xFFE8C99B)],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD4A574).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD4D8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildNightCap(double size) {
    return Transform.rotate(
      angle: 0.4,
      child: Stack(
        children: [
          // Cap body
          CustomPaint(
            size: Size(size, size * 1.2),
            painter: _NightCapPainter(),
          ),
          // Pom pom
          Positioned(
            right: 0,
            top: size * 0.1,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8E0FF).withOpacity(0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepingEye(double size) {
    return SizedBox(
      width: size,
      height: size * 0.5,
      child: CustomPaint(painter: _CurvyEyePainter()),
    );
  }

  Widget _buildMuzzle(double size) {
    return Container(
      width: size * 0.22,
      height: size * 0.14,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.05),
          topRight: Radius.circular(size * 0.05),
          bottomLeft: Radius.circular(size * 0.1),
          bottomRight: Radius.circular(size * 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cute tiny nose
          Container(
            width: size * 0.06,
            height: size * 0.04,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B4F3C), Color(0xFF4A3728)],
              ),
              borderRadius: BorderRadius.circular(size * 0.02),
            ),
          ),
          SizedBox(height: size * 0.01),
          // Tiny smile
          Container(
            width: size * 0.04,
            height: size * 0.015,
            decoration: BoxDecoration(
              color: const Color(0xFF6B4F3C).withOpacity(0.5),
              borderRadius: BorderRadius.circular(size * 0.01),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlush(double size) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFB6C1).withOpacity(0.6),
            const Color(0xFFFFB6C1).withOpacity(0.0),
          ],
        ),
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }

  Widget _buildHeartPillow(double size) {
    return Container(
      width: size,
      height: size * 0.9,
      child: Icon(
        Icons.favorite,
        size: size,
        color: const Color(0xFFFF8FAB),
        shadows: [
          Shadow(
            color: const Color(0xFFFF6B8A).withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildPaw(double size) {
    return Container(
      width: size,
      height: size * 1.2,
      decoration: BoxDecoration(
        color: const Color(0xFFE8C99B),
        borderRadius: BorderRadius.circular(size * 0.4),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: size * 0.7,
          height: size * 0.5,
          margin: EdgeInsets.only(bottom: size * 0.1),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5E6),
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildZzzBubbles() {
    return [
      _buildZzz(widget.size * 0.35, -widget.size * 0.1, 0.0, 14, 0.9),
      _buildZzz(widget.size * 0.45, -widget.size * 0.25, 0.35, 18, 0.85),
      _buildZzz(widget.size * 0.55, -widget.size * 0.42, 0.7, 24, 0.8),
    ];
  }

  Widget _buildZzz(
    double offsetX,
    double offsetY,
    double delay,
    double fontSize,
    double maxOpacity,
  ) {
    return AnimatedBuilder(
      animation: _zzzController,
      builder: (context, child) {
        final progress = ((_zzzController.value + delay) % 1.0);
        final opacity = progress < 0.4
            ? (progress / 0.4) * maxOpacity
            : progress < 0.7
            ? maxOpacity
            : ((1.0 - progress) / 0.3) * maxOpacity;
        final yOffset = offsetY - (progress * 35);
        final xSway = sin(progress * 3.14159 * 2) * 4;

        return Positioned(
          right: widget.size * 0.2 + offsetX + xSway,
          top: widget.size * 0.3 + yOffset,
          child: Opacity(
            opacity: opacity.clamp(0.0, maxOpacity),
            child: Transform.scale(
              scale: 0.85 + (progress * 0.3),
              child: Text(
                'z',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE8E0FF),
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFB8A0E8).withOpacity(0.8),
                      blurRadius: 8,
                    ),
                    Shadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 15,
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
}

// Night cap painter
class _NightCapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFB8A0E8), const Color(0xFF9B7ED8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(size.width * 0.7, 0, size.width, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.6,
      size.width * 0.2,
      size.height,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Stripes on cap
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 3; i++) {
      final stripePath = Path();
      stripePath.moveTo(size.width * 0.1, size.height * (0.7 - i * 0.15));
      stripePath.quadraticBezierTo(
        size.width * 0.4,
        size.height * (0.6 - i * 0.15),
        size.width * 0.7,
        size.height * (0.35 - i * 0.1),
      );
      canvas.drawPath(stripePath, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Curvy sleeping eye painter
class _CurvyEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height * 0.3,
    );

    canvas.drawPath(path, paint);

    // Small eyelashes
    final lashPaint = Paint()
      ..color = const Color(0xFF5D4037).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left lash
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.5),
      Offset(size.width * 0.1, size.height * 0.8),
      lashPaint,
    );
    // Middle lash
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 1.0),
      lashPaint,
    );
    // Right lash
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.8),
      lashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
