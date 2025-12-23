import 'package:flutter/material.dart';
import '../../logic/services/background_service.dart';
import '../../logic/services/overlay_service.dart';

class ChildModeActivationScreen extends StatefulWidget {
  const ChildModeActivationScreen({super.key});

  @override
  State<ChildModeActivationScreen> createState() =>
      _ChildModeActivationScreenState();
}

class _ChildModeActivationScreenState extends State<ChildModeActivationScreen> {
  late final BackgroundService _backgroundService;
  final OverlayService _overlayService = OverlayService();
  bool _isActive = false;

  // Minimal Premium Colors
  static const _accentColor = Color(0xFFE67E22);
  static const _bgColor = Color(0xFFFAFAFC);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E5EA);

  @override
  void initState() {
    super.initState();
    _backgroundService = BackgroundService(
      onBlockedAppDetected: (packageName) {
        print('Blocked app detected: $packageName');
        OverlayService().showBlockOverlay(packageName);
      },
      onTimeLimitReached: () {
        print('Time limit reached!');
        OverlayService().showBlockOverlay("Time Limit Reached");
      },
      onAppAllowed: () {
        OverlayService().hideOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _borderColor,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: _textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security_outlined,
                            size: 50,
                            color: Color(0xFF22C55E),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'ระบบป้องกัน',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'ระบบจะทำงานเบื้องหลังเพื่อติดตาม\nและปกป้องลูกของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                            height: 1.5,
                          ),
                        ),

                        const Spacer(),

                        // Activate Button
                        GestureDetector(
                          onTap: _isActive
                              ? null
                              : () async {
                                  bool overlayPerm = await _overlayService
                                      .checkPermission();
                                  if (!overlayPerm) {
                                    await _overlayService.requestPermission();
                                    return;
                                  }

                                  await _backgroundService.startMonitoring(
                                    'dummy_child',
                                    'dummy_parent',
                                  );
                                  setState(() {
                                    _isActive = true;
                                  });

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'เปิดใช้งานระบบป้องกันแล้ว!',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF22C55E,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _isActive
                                  ? _textSecondary
                                  : const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isActive
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF22C55E,
                                        ).withOpacity(0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                _isActive
                                    ? 'กำลังปกป้อง'
                                    : 'เปิดใช้งานการป้องกัน',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (_isActive) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              await _backgroundService.stopMonitoring();
                              setState(() {
                                _isActive = false;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _borderColor),
                              ),
                              child: const Center(
                                child: Text(
                                  'หยุดการป้องกัน (ต้องใช้ PIN)',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
