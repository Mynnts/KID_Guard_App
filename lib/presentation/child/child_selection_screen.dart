import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../config/routes.dart';
import '../../core/utils/responsive_helper.dart';

class ChildSelectionScreen extends StatefulWidget {
  const ChildSelectionScreen({super.key});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  int? _selectedIndex;

  // Minimal Premium Colors
  static const _accentColor = Color(0xFFE67E22);
  static const _accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE67E22), Color(0xFFD35400)],
  );
  static const _bgColor = Color(0xFFFAFAFC);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E5EA);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final children = authProvider.children;
    final r = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.wp(28),
                    r.hp(40),
                    r.wp(28),
                    r.hp(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: r.wp(56),
                        height: r.wp(56),
                        decoration: BoxDecoration(
                          gradient: _accentGradient,
                          borderRadius: BorderRadius.circular(r.radius(16)),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.child_care_rounded,
                          color: Colors.white,
                          size: r.iconSize(28),
                        ),
                      ),
                      SizedBox(height: r.hp(24)),
                      Text(
                        'ใครกำลังใช้งาน',
                        style: TextStyle(
                          fontSize: r.sp(15),
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: r.hp(6)),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            _accentGradient.createShader(bounds),
                        child: Text(
                          'เครื่องนี้?',
                          style: TextStyle(
                            fontSize: r.sp(34),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      SizedBox(height: r.hp(8)),
                      Text(
                        'เลือกโปรไฟล์เพื่อเริ่มใช้งาน',
                        style: TextStyle(
                          fontSize: r.sp(14),
                          color: _textSecondary.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.wp(24),
                  vertical: r.hp(8),
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: r.wp(16),
                    mainAxisSpacing: r.hp(16),
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == children.length) {
                      return _buildAddChildCard(context, index);
                    }
                    return _buildChildCard(context, children[index], index);
                  }, childCount: children.length + 1),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: r.hp(40))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child, int index) {
    final isSelected = _selectedIndex == index;
    final r = ResponsiveHelper.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, widget) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value.clamp(0.0, 1.0)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: widget),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _selectedIndex = index),
        onTapUp: (_) => setState(() => _selectedIndex = null),
        onTapCancel: () => setState(() => _selectedIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(isSelected ? 0.95 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(r.radius(28)),
              border: Border.all(
                color: isSelected
                    ? _accentColor.withOpacity(0.3)
                    : const Color(0xFFF0F0F5),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? _accentColor.withOpacity(0.15)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isSelected ? 24 : 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(r.radius(28)),
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.selectChild(child);
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.childHome,
                    );
                  }
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(r.wp(12)),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'avatar_${child.id}',
                                child: Container(
                                  padding: EdgeInsets.all(r.wp(3)),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _accentColor.withOpacity(0.4),
                                        _accentColor.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(r.wp(2)),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: r.wp(32),
                                      backgroundColor: const Color(0xFFF8F8FA),
                                      backgroundImage: child.avatar != null
                                          ? AssetImage(child.avatar!)
                                          : null,
                                      child: child.avatar == null
                                          ? Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: _accentGradient,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  child.name.isNotEmpty
                                                      ? child.name[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    fontSize: r.sp(24),
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: r.hp(12)),
                              Text(
                                child.name,
                                style: TextStyle(
                                  fontSize: r.sp(15),
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: r.hp(6)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.wp(10),
                                  vertical: r.hp(4),
                                ),
                                decoration: BoxDecoration(
                                  color: _accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    r.radius(10),
                                  ),
                                ),
                                child: Text(
                                  '${child.age} ปี',
                                  style: TextStyle(
                                    fontSize: r.sp(11),
                                    color: _accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: r.hp(8),
                      right: r.wp(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _confirmDelete(context, child),
                            child: Padding(
                              padding: EdgeInsets.all(r.wp(6)),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey[400],
                                size: r.iconSize(14),
                              ),
                            ),
                          ),
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

  void _confirmDelete(BuildContext context, ChildModel child) {
    final r = ResponsiveHelper.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.radius(24)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(r.wp(10)),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(r.radius(12)),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                size: r.iconSize(22),
              ),
            ),
            SizedBox(width: r.wp(14)),
            Expanded(
              child: Text(
                'ลบโปรไฟล์?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  fontSize: r.sp(18),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ที่จะลบโปรไฟล์ของ ${child.name}? การกระทำนี้จะไม่สามารถย้อนกลับได้',
          style: TextStyle(
            color: _textSecondary,
            fontSize: r.sp(14),
            height: 1.5,
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(r.wp(20), 0, r.wp(20), r.hp(20)),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: r.hp(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(r.radius(14)),
                      side: BorderSide(color: _borderColor),
                    ),
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      color: _textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: r.wp(12)),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).deleteChild(child.id);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ไม่สามารถลบโปรไฟล์ได้',
                            style: TextStyle(fontSize: r.sp(14)),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r.radius(12)),
                          ),
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: r.hp(14)),
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(r.radius(14)),
                    ),
                  ),
                  child: Text(
                    'ลบ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddChildCard(BuildContext context, int index) {
    final r = ResponsiveHelper.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, widget) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value.clamp(0.0, 1.0)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: widget),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r.radius(28)),
          border: Border.all(color: _borderColor, width: 1.5),
          color: Colors.white.withOpacity(0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(r.radius(28)),
            onTap: () {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.childProfileSetup,
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: r.wp(64),
                  height: r.wp(64),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _accentColor.withOpacity(0.3),
                      width: 2,
                    ),
                    color: _accentColor.withOpacity(0.06),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: r.iconSize(30),
                    color: _accentColor,
                  ),
                ),
                SizedBox(height: r.hp(14)),
                Text(
                  'เพิ่มโปรไฟล์',
                  style: TextStyle(
                    fontSize: r.sp(14),
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
