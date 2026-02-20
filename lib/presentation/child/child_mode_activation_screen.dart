import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/services/background_service.dart';
import '../../logic/services/overlay_service.dart';
import '../../core/utils/responsive_helper.dart';

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
    final r = ResponsiveHelper.of(context);
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
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r.radius(24)),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: _primaryColor,
                    size: r.iconSize(24),
                  ),
                  SizedBox(width: r.wp(12)),
                  Text('ต้องปิดโหมดเด็ก', style: TextStyle(fontSize: r.sp(18))),
                ],
              ),
              content: Text(
                'ต้องกรอก PIN ผู้ปกครองเพื่อปิดโหมดเด็กให้ได้',
                style: TextStyle(color: _textSecondary, fontSize: r.sp(14)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'ยืนยัน',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(14),
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
              padding: EdgeInsets.symmetric(
                horizontal: r.wp(24),
                vertical: r.hp(20),
              ),
              child: Column(
                children: [
                  _buildPointsCard(points, childName),
                  SizedBox(height: r.hp(32)),
                  _buildShieldIcon(),
                  SizedBox(height: r.hp(32)),
                  Text(
                    'สวัสดี $childName',
                    style: TextStyle(
                      fontSize: r.sp(28),
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: r.hp(8)),
                  Text(
                    _isChildrenModeActive
                        ? 'โหมดป้องกันกำลังทำงาน'
                        : 'เปิดใช้งานเพื่อเริ่มการป้องกัน',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.sp(15),
                      color: _textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: r.hp(40)),
                  _buildToggleSwitch(),
                  SizedBox(height: r.hp(20)),
                  _buildStatusBadge(),
                  SizedBox(height: r.hp(32)),
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
    final r = ResponsiveHelper.of(context);
    return Container(
      padding: EdgeInsets.all(r.wp(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.radius(28)),
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
          Container(
            width: r.wp(56),
            height: r.wp(56),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(r.radius(16)),
            ),
            child: Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: r.iconSize(32),
            ),
          ),
          SizedBox(width: r.wp(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'แต้มสะสม',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: r.sp(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: r.hp(4)),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: points),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Text(
                      '$value pts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.sp(28),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.wp(12),
              vertical: r.hp(6),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(r.radius(20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: r.iconSize(18),
                ),
                SizedBox(width: r.wp(6)),
                Text(
                  'Level ${(points ~/ 100) + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: r.sp(13),
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
    final r = ResponsiveHelper.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: r.wp(120),
      height: r.wp(120),
      decoration: BoxDecoration(
        gradient: _isChildrenModeActive
            ? const LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _isChildrenModeActive
            ? null
            : _tertiaryColor.withValues(alpha: 0.5),
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
        size: r.iconSize(56),
        color: _isChildrenModeActive ? Colors.white : _textSecondary,
      ),
    );
  }

  Widget _buildToggleSwitch() {
    final r = ResponsiveHelper.of(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _isChildrenModeActive = !_isChildrenModeActive;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: r.wp(88),
        height: r.hp(48),
        decoration: BoxDecoration(
          gradient: _isChildrenModeActive
              ? const LinearGradient(colors: [_primaryColor, _secondaryColor])
              : null,
          color: _isChildrenModeActive ? null : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(r.radius(24)),
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
            margin: EdgeInsets.all(r.wp(4)),
            width: r.wp(40),
            height: r.wp(40),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isChildrenModeActive ? Icons.check_rounded : Icons.close_rounded,
              size: r.iconSize(20),
              color: _isChildrenModeActive ? _primaryColor : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final r = ResponsiveHelper.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: r.wp(20), vertical: r.hp(10)),
      decoration: BoxDecoration(
        color: _isChildrenModeActive
            ? _successColor.withValues(alpha: 0.1)
            : _tertiaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(r.radius(24)),
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
            width: r.wp(8),
            height: r.wp(8),
            decoration: BoxDecoration(
              color: _isChildrenModeActive ? _successColor : _textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: r.wp(10)),
          Text(
            _isChildrenModeActive ? 'กำลังป้องกัน' : 'ปิดอยู่',
            style: TextStyle(
              fontSize: r.sp(14),
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
    final r = ResponsiveHelper.of(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(r.wp(20)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFCFDFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(r.radius(24)),
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
                padding: EdgeInsets.all(r.wp(12)),
                decoration: BoxDecoration(
                  color: _tertiaryColor,
                  borderRadius: BorderRadius.circular(r.radius(14)),
                ),
                child: Icon(
                  Icons.today_rounded,
                  color: _primaryColor,
                  size: r.iconSize(24),
                ),
              ),
              SizedBox(width: r.wp(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เวลาเล่นทั้งหมดวันนี้',
                      style: TextStyle(
                        fontSize: r.sp(13),
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: r.hp(4)),
                    Text(
                      _formatTime(screenTime),
                      style: TextStyle(
                        fontSize: r.sp(26),
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.wp(10),
                  vertical: r.hp(6),
                ),
                decoration: BoxDecoration(
                  color: _tertiaryColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: r.iconSize(14),
                      color: _textSecondary,
                    ),
                    SizedBox(width: r.wp(4)),
                    Text(
                      'Reset เที่ยงคืน',
                      style: TextStyle(
                        fontSize: r.sp(11),
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (dailyLimit > 0) ...[
          SizedBox(height: r.hp(16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(r.wp(20)),
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
              borderRadius: BorderRadius.circular(r.radius(24)),
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
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(r.wp(12)),
                      decoration: BoxDecoration(
                        color: remainingTime < 1800
                            ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                            : _tertiaryColor,
                        borderRadius: BorderRadius.circular(r.radius(14)),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: remainingTime < 1800
                            ? const Color(0xFFEF4444)
                            : _primaryColor,
                        size: r.iconSize(24),
                      ),
                    ),
                    SizedBox(width: r.wp(16)),
                    Expanded(
                      child: Text(
                        'ขีดจำกัดเวลาเล่น',
                        style: TextStyle(
                          fontSize: r.sp(16),
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.hp(20)),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(limitUsedTime),
                            style: TextStyle(
                              fontSize: r.sp(24),
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          SizedBox(height: r.hp(4)),
                          Text(
                            'ใช้ไปแล้ว',
                            style: TextStyle(
                              fontSize: r.sp(13),
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: r.hp(50),
                      color: _tertiaryColor,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(remainingTime),
                            style: TextStyle(
                              fontSize: r.sp(24),
                              fontWeight: FontWeight.bold,
                              color: remainingTime < 1800
                                  ? const Color(0xFFEF4444)
                                  : _successColor,
                            ),
                          ),
                          SizedBox(height: r.hp(4)),
                          Text(
                            'เหลืออีก',
                            style: TextStyle(
                              fontSize: r.sp(13),
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.hp(20)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.radius(8)),
                  child: LinearProgressIndicator(
                    value: (limitUsedTime / dailyLimit).clamp(0.0, 1.0),
                    minHeight: r.hp(8),
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
