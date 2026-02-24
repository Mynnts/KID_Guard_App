// ==================== Onboarding Screen ====================
/// หน้า Tutorial/Walkthrough สำหรับผู้ใช้ใหม่
/// แสดงครั้งแรกที่เปิดแอพ + เข้าถึงได้จาก Settings
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/onboarding_provider.dart';
import '../../config/routes.dart';
import '../../core/utils/responsive_helper.dart';

class OnboardingScreen extends StatefulWidget {
  /// true = เปิดจาก Settings (ไม่ navigate ไป select_user)
  final bool fromSettings;

  const OnboardingScreen({super.key, this.fromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _iconAnimController;
  late Animation<double> _iconBounce;

  // Design tokens — consistent with select_user_screen
  static const _bgColor = Color(0xFFFAFAFC);
  static const _accentColor = Color(0xFF6B9080);
  static const _accentLight = Color(0xFF84A98C);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.shield_outlined,
      iconBgGradient: [Color(0xFF6B9080), Color(0xFF84A98C)],
      title: 'ยินดีต้อนรับสู่ Kid Guard',
      subtitle: 'ปกป้อง ดูแล เข้าใจ',
      description:
          'เลือกบทบาทเป็น ผู้ปกครอง หรือ เด็ก เพื่อเริ่มต้นใช้งาน\nผู้ปกครองจะดูแลและจัดการอุปกรณ์ของลูก',
    ),
    _OnboardingPage(
      icon: Icons.people_alt_outlined,
      iconBgGradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      title: 'เพิ่มโปรไฟล์ & เชื่อมต่อ',
      subtitle: 'ง่ายๆ ด้วยรหัส PIN',
      description:
          'เพิ่มโปรไฟล์เด็กในหน้าผู้ปกครอง\nใช้ PIN 6 หลักเพื่อเชื่อมต่อมือถือของลูก',
    ),
    _OnboardingPage(
      icon: Icons.timer_outlined,
      iconBgGradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      title: 'ตั้ง Time Limit & Schedule',
      subtitle: 'ควบคุมเวลาหน้าจอ',
      description: 'กำหนดเวลาใช้งานต่อวัน\nตั้งเวลานอน & ช่วงเวลาพักตามต้องการ',
    ),
    _OnboardingPage(
      icon: Icons.apps_rounded,
      iconBgGradient: [Color(0xFFEF4444), Color(0xFFF87171)],
      title: 'Block App & Rewards',
      subtitle: 'ล็อคแอพ + ให้รางวัล',
      description:
          'เลือกแอพที่ต้องการบล็อคได้ทันที\nให้คะแนนเป็นรางวัลเมื่อลูกทำตามกฎ ⭐',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconAnimController, curve: Curves.elasticOut),
    );
    _iconAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _iconAnimController.forward(from: 0.0);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() => _finishOnboarding();

  Future<void> _finishOnboarding() async {
    final provider = context.read<OnboardingProvider>();
    await provider.completeOnboarding();

    if (!mounted) return;

    if (widget.fromSettings) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.selectUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — Skip button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: r.wp(16),
                vertical: r.hp(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'ข้าม',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: r.sp(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // PageView — main content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], r);
                },
              ),
            ),

            // Bottom section — dots + button
            Padding(
              padding: EdgeInsets.fromLTRB(
                r.wp(32),
                r.hp(16),
                r.wp(32),
                r.hp(32),
              ),
              child: Column(
                children: [
                  // Page indicator dots
                  _buildDots(r),
                  SizedBox(height: r.hp(32)),
                  // Action button
                  _buildActionButton(r),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, ResponsiveHelper r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.wp(32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Animated icon
          AnimatedBuilder(
            animation: _iconBounce,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * _iconBounce.value.clamp(0.0, 1.0)),
                child: Opacity(
                  opacity: _iconBounce.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              width: r.wp(120),
              height: r.wp(120),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: page.iconBgGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(r.radius(36)),
                boxShadow: [
                  BoxShadow(
                    color: page.iconBgGradient.first.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  page.icon,
                  size: r.iconSize(52),
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: r.hp(32)),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: r.sp(26),
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),

          SizedBox(height: r.hp(8)),

          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: r.sp(15),
              fontWeight: FontWeight.w600,
              color: _accentColor,
              letterSpacing: 0.3,
            ),
          ),

          SizedBox(height: r.hp(20)),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: r.sp(14),
              color: _textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildDots(ResponsiveHelper r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: r.wp(4)),
          width: isActive ? r.wp(28) : r.wp(8),
          height: r.wp(8),
          decoration: BoxDecoration(
            color: isActive ? _accentColor : _accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(r.radius(4)),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(ResponsiveHelper r) {
    final isLastPage = _currentPage == _pages.length - 1;

    return GestureDetector(
      onTap: _nextPage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: r.hp(18)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accentColor, _accentLight]),
          borderRadius: BorderRadius.circular(r.radius(18)),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastPage ? 'เริ่มใช้งาน' : 'ถัดไป',
              style: TextStyle(
                color: Colors.white,
                fontSize: r.sp(16),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: r.wp(8)),
            Icon(
              isLastPage
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: r.iconSize(20),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Data Model ====================
class _OnboardingPage {
  final IconData icon;
  final List<Color> iconBgGradient;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.iconBgGradient,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
