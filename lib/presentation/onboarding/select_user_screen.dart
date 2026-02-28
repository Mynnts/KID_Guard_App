import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/routes.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/onboarding_provider.dart';
import '../../core/utils/responsive_helper.dart';

class SelectUserScreen extends StatefulWidget {
  const SelectUserScreen({super.key});

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isCheckingAuth = true;
  bool _hasNavigated = false;

  // Minimal Premium Colors
  static const _primaryColor = Color(0xFF1A1A2E);
  static const _accentColor = Color(0xFF6B9080);
  static const _parentAccent = Color(0xFF6B9080);
  static const _childAccent = Color(0xFFE67E22);
  static const _bgColor = Color(0xFFFAFAFC);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _textMuted = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    // Check auth state after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    // ตรวจว่าเคยเห็น onboarding หรือยัง
    final onboardingProvider = context.read<OnboardingProvider>();
    // รอจนโหลดเสร็จ
    while (!onboardingProvider.isLoaded) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    if (!onboardingProvider.hasSeenOnboarding) {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
      return;
    }

    // FIRST: Check if child mode is active (app relaunched after swipe-away)
    final prefs = await SharedPreferences.getInstance();
    final isChildModeActive = prefs.getBool('isChildModeActive') ?? false;
    final activeChildId = prefs.getString('activeChildId');
    final activeParentUid = prefs.getString('activeParentUid');

    if (isChildModeActive && activeChildId != null && activeParentUid != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // ดึง PIN จาก SharedPreferences แล้วใช้ childLogin
      final savedPin = prefs.getString('activeParentPin');
      if (savedPin != null && savedPin.isNotEmpty) {
        final success = await authProvider.childLogin(savedPin);
        if (success && authProvider.children.isNotEmpty) {
          try {
            final child = authProvider.children.firstWhere(
              (c) => c.id == activeChildId,
            );
            await authProvider.selectChild(child);

            if (mounted && !_hasNavigated) {
              _hasNavigated = true;
              Navigator.pushReplacementNamed(context, AppRoutes.childHome);
            }
            return;
          } catch (_) {
            // Child not found, clear stale data
          }
        }
      }

      // Failed to restore — clear stale data
      await prefs.setBool('isChildModeActive', false);
      await prefs.remove('activeChildId');
      await prefs.remove('activeParentUid');
      await prefs.remove('activeParentPin');
    }

    // SECOND: Check Firebase Auth for parent login (skip anonymous users)
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null && !firebaseUser.isAnonymous) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      int attempts = 0;
      while (authProvider.userModel == null && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
        if (!mounted) return;
      }

      // Redirect to parent dashboard
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.pushReplacementNamed(context, AppRoutes.parentDashboard);
      }
    } else {
      // Stale anonymous user — sign out
      if (firebaseUser != null && firebaseUser.isAnonymous) {
        try {
          await firebaseUser.delete();
        } catch (_) {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
        }
      }

      // Not logged in, show select user screen
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auth state
    if (_isCheckingAuth) {
      final r = ResponsiveHelper.of(context);
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: r.wp(80),
                height: r.wp(80),
                decoration: BoxDecoration(
                  color: const Color(0xFF779C85),
                  borderRadius: BorderRadius.circular(r.radius(24)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(r.radius(24)),
                  child: Image.asset(
                    'assets/icons/Kid_Guard.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: r.hp(24)),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              ),
            ],
          ),
        ),
      );
    }

    final r = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: r.wp(32)),
                        child: Column(
                          children: [
                            const Spacer(flex: 3),

                            // Minimal Logo
                            _buildMinimalLogo(),

                            SizedBox(height: r.hp(28)),

                            // App Name
                            Text(
                              'Kid Guard',
                              style: TextStyle(
                                fontSize: r.sp(32),
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                letterSpacing: -1,
                              ),
                            ),

                            SizedBox(height: r.hp(8)),

                            Text(
                              'ปกป้อง ดูแล เข้าใจ',
                              style: TextStyle(
                                fontSize: r.sp(14),
                                color: _textSecondary,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const Spacer(flex: 2),

                            // Selection Label
                            _buildSelectionLabel(),

                            SizedBox(height: r.hp(24)),

                            // Parent Card
                            _MinimalUserCard(
                              title: 'ผู้ปกครอง',
                              subtitle: 'จัดการและดูแลกิจกรรมของลูก',
                              icon: Icons.person_outline_rounded,
                              accentColor: _parentAccent,
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.login),
                            ),

                            SizedBox(height: r.hp(16)),

                            // Child Card
                            _MinimalUserCard(
                              title: 'เด็ก',
                              subtitle: 'เชื่อมต่อกับบัญชีผู้ปกครอง',
                              icon: Icons.child_care_outlined,
                              accentColor: _childAccent,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.childPin,
                              ),
                            ),

                            const Spacer(flex: 3),

                            // Footer
                            _buildFooter(),

                            SizedBox(height: r.hp(40)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalLogo() {
    final r = ResponsiveHelper.of(context);
    return Container(
      width: r.wp(80),
      height: r.wp(80),
      decoration: BoxDecoration(
        color: const Color(0xFF779C85),
        borderRadius: BorderRadius.circular(r.radius(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF779C85).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.radius(24)),
        child: Image.asset('assets/icons/Kid_Guard.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSelectionLabel() {
    final r = ResponsiveHelper.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: r.wp(6),
          height: r.wp(6),
          decoration: const BoxDecoration(
            color: _accentColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: r.wp(10)),
        Text(
          'เลือกบทบาทของคุณ',
          style: TextStyle(
            fontSize: r.sp(13),
            fontWeight: FontWeight.w500,
            color: _textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final r = ResponsiveHelper.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: r.iconSize(14),
          color: _textMuted,
        ),
        SizedBox(width: r.wp(6)),
        Text(
          'ปลอดภัยและเป็นส่วนตัว',
          style: TextStyle(
            fontSize: r.sp(12),
            color: _textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _MinimalUserCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _MinimalUserCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_MinimalUserCard> createState() => _MinimalUserCardState();
}

class _MinimalUserCardState extends State<_MinimalUserCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: EdgeInsets.all(r.wp(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r.radius(20)),
            border: Border.all(
              color: _isPressed
                  ? widget.accentColor.withOpacity(0.3)
                  : const Color(0xFFF0F0F5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: r.wp(52),
                height: r.wp(52),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(r.radius(16)),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.accentColor,
                  size: r.iconSize(26),
                ),
              ),
              SizedBox(width: r.wp(16)),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: r.sp(17),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: r.hp(4)),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: r.sp(13),
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: r.iconSize(16),
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
