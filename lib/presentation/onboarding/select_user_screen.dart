import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../config/routes.dart';
import '../../logic/providers/auth_provider.dart';

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
    // Use Firebase Auth directly to check if user is logged in
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (firebaseUser != null) {
      // User is logged in, wait for AuthProvider to load user data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for AuthProvider to sync with Firebase (max 3 seconds)
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
      // User is not logged in, show select user screen
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
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              ),
            ],
          ),
        ),
      );
    }

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
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const Spacer(flex: 3),

                            // Minimal Logo
                            _buildMinimalLogo(),

                            const SizedBox(height: 28),

                            // App Name
                            const Text(
                              'Kid Guard',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                letterSpacing: -1,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'ปกป้อง ดูแล เข้าใจ',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const Spacer(flex: 2),

                            // Selection Label
                            _buildSelectionLabel(),

                            const SizedBox(height: 24),

                            // Parent Card
                            _MinimalUserCard(
                              title: 'ผู้ปกครอง',
                              subtitle: 'จัดการและดูแลกิจกรรมของลูก',
                              icon: Icons.person_outline_rounded,
                              accentColor: _parentAccent,
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.login),
                            ),

                            const SizedBox(height: 16),

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
        ),
      ),
    );
  }

  Widget _buildMinimalLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.shield_outlined, size: 40, color: Colors.white),
    );
  }

  Widget _buildSelectionLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _accentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'เลือกบทบาทของคุณ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: _textMuted),
        const SizedBox(width: 6),
        Text(
          'ปลอดภัยและเป็นส่วนตัว',
          style: TextStyle(
            fontSize: 12,
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 26),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
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
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
