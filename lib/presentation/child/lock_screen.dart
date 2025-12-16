import 'package:flutter/material.dart';
import 'dart:ui';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  // Minimal Premium Colors
  static const _accentColor = Color(0xFFE67E22);
  static const _textPrimary = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async => false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_clock_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      'พักผ่อนหน่อยนะ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'ถึงเวลาพักแล้ว!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
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
                            backgroundColor: _accentColor,
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
}
