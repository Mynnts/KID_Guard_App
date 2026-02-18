import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
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
  bool _isChildrenModeActive = false;

  // Modern Sage Green Theme Colors
  static const _primaryColor = Color(0xFF6B9080);
  static const _secondaryColor = Color(0xFF84A98C);
  static const _tertiaryColor = Color(0xFFCCE3DE);
  static const _bgColor = Color(0xFFF6FBF4);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _successColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _backgroundService = BackgroundService(
      onBlockedAppDetected: (packageName) {
        OverlayService().showBlockOverlay(packageName);
      },
      onTimeLimitReached: () {
        OverlayService().showBlockOverlay("Time Limit Reached");
      },
      onAppAllowed: () {
        OverlayService().hideOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final child = authProvider.currentChild;
    final childName = child?.name ?? 'น้อง';
    final points = child?.points ?? 0;
    final screenTime = child?.screenTime ?? 0;
    final limitUsedTime = child?.limitUsedTime ?? 0;
    final dailyLimit = child?.dailyTimeLimit ?? 0;
    final remainingTime = dailyLimit > 0
        ? (dailyLimit - limitUsedTime).clamp(0, dailyLimit)
        : 0;

    return PopScope(
      canPop: !_isChildrenModeActive,
      onPopInvokedWithResult: (didPop, result) {
        if (_isChildrenModeActive && didPop == false) {
          // แสดง dialog บอกว่าต้องกรอก PIN เพื่อปิดโหมด
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: _primaryColor),
                  SizedBox(width: 12),
                  Text('ต้องปิดโหมดเด็ก'),
                ],
              ),
              content: const Text(
                'ต้องกรอก PIN ผู้ปกครองเพื่อปิดโหมดเด็กให้ได้',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ยืนยัน',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Points Card
                  _buildPointsCard(points, childName),

                  const SizedBox(height: 32),

                  // Shield Icon
                  _buildShieldIcon(),

                  const SizedBox(height: 32),

                  // Title & Subtitle
                  Text(
                    'สวัสดี $childName',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isChildrenModeActive
                        ? 'โหมดป้องกันกำลังทำงาน'
                        : 'เปิดใช้งานเพื่อเริ่มการป้องกัน',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Toggle Switch
                  _buildToggleSwitch(),

                  const SizedBox(height: 20),

                  // Status Badge
                  _buildStatusBadge(),

                  const SizedBox(height: 32),

                  // Screen Time Info - pass both values
                  if (dailyLimit > 0 || screenTime > 0 || limitUsedTime > 0)
                    _buildScreenTimeCard(
                      screenTime,
                      limitUsedTime,
                      remainingTime,
                      dailyLimit,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(int points, String childName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Star Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Points Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'แต้มสะสม',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: points),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Text(
                      '$value pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Trophy Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Level ${(points ~/ 100) + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: _isChildrenModeActive
            ? const LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _isChildrenModeActive ? null : _tertiaryColor.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        boxShadow: _isChildrenModeActive
            ? [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.30),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(
        _isChildrenModeActive ? Icons.shield_rounded : Icons.shield_outlined,
        size: 56,
        color: _isChildrenModeActive ? Colors.white : _textSecondary,
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isChildrenModeActive = !_isChildrenModeActive;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 88,
        height: 48,
        decoration: BoxDecoration(
          gradient: _isChildrenModeActive
              ? const LinearGradient(colors: [_primaryColor, _secondaryColor])
              : null,
          color: _isChildrenModeActive ? null : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isChildrenModeActive
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: _isChildrenModeActive
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(4),
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isChildrenModeActive ? Icons.check_rounded : Icons.close_rounded,
              size: 20,
              color: _isChildrenModeActive ? _primaryColor : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _isChildrenModeActive
            ? _successColor.withValues(alpha: 0.1)
            : _tertiaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isChildrenModeActive
              ? _successColor.withValues(alpha: 0.3)
              : _tertiaryColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isChildrenModeActive ? _successColor : _textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isChildrenModeActive ? 'กำลังป้องกัน' : 'ปิดอยู่',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isChildrenModeActive ? _successColor : _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeCard(
    int screenTime,
    int limitUsedTime,
    int remainingTime,
    int dailyLimit,
  ) {
    return Column(
      children: [
        // Section 1: Total Daily Screen Time (resets at midnight)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFCFDFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _tertiaryColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tertiaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.today_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'เวลาเล่นทั้งหมดวันนี้',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(screenTime),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Resets at midnight badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _tertiaryColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: _textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Reset เที่ยงคืน',
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section 2: Time Limit Progress (if limit is set)
        if (dailyLimit > 0) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  remainingTime < 1800 ? const Color(0xFFFEF2F2) : Colors.white,
                  remainingTime < 1800
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFFCFDFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: remainingTime < 1800
                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                    : _tertiaryColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: remainingTime < 1800
                      ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: remainingTime < 1800
                            ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                            : _tertiaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: remainingTime < 1800
                            ? const Color(0xFFEF4444)
                            : _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'ขีดจำกัดเวลาเล่น',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats Row
                Row(
                  children: [
                    // Used Time
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(limitUsedTime),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ใช้ไปแล้ว',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(width: 1, height: 50, color: _tertiaryColor),
                    // Remaining Time
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(remainingTime),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: remainingTime < 1800
                                  ? const Color(0xFFEF4444)
                                  : _successColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'เหลืออีก',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Progress Bar
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (limitUsedTime / dailyLimit).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: _tertiaryColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (limitUsedTime / dailyLimit) > 0.8
                          ? const Color(0xFFEF4444)
                          : _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}ชม. ${minutes}น.';
    }
    return '${minutes}น.';
  }
}
