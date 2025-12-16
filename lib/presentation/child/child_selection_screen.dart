import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../config/routes.dart';

class ChildSelectionScreen extends StatefulWidget {
  const ChildSelectionScreen({super.key});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Minimal Premium Colors
  static const _accentColor = Color(0xFFE67E22);
  static const _bgColor = Color(0xFFFAFAFC);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E5EA);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
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

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ใครกำลังใช้งาน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'เครื่องนี้?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: children.length + 1,
                  itemBuilder: (context, index) {
                    if (index == children.length) {
                      return _buildAddChildCard(context);
                    }
                    return _buildChildCard(context, children[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF0F0F5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.selectChild(child);
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.childHome);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'avatar_${child.id}',
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accentColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFF5F5F7),
                          backgroundImage: child.avatar != null
                              ? AssetImage(child.avatar!)
                              : null,
                          child: child.avatar == null
                              ? Text(
                                  child.name.isNotEmpty
                                      ? child.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: _accentColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      child.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${child.age} ปี',
                        style: const TextStyle(
                          fontSize: 12,
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
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _confirmDelete(context, child),
              icon: Icon(
                Icons.close_rounded,
                color: Colors.grey[400],
                size: 16,
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ลบโปรไฟล์?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            fontSize: 18,
          ),
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ที่จะลบโปรไฟล์ของ ${child.name}?',
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<AuthProvider>(
                context,
                listen: false,
              ).deleteChild(child.id);

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('ไม่สามารถลบโปรไฟล์ได้'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'ลบ',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddChildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _borderColor,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: _accentColor,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'เพิ่มโปรไฟล์',
                style: TextStyle(
                  fontSize: 14,
                  color: _accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
