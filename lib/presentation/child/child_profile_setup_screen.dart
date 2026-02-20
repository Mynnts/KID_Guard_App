import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../core/utils/responsive_helper.dart';

class ChildProfileSetupScreen extends StatefulWidget {
  const ChildProfileSetupScreen({super.key});

  @override
  State<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState extends State<ChildProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  int _selectedAvatar = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<String> _avatars = [
    'assets/avatars/boy_1.png',
    'assets/avatars/girl_2.png',
  ];

  // Minimal Premium Colors
  static const _accentColor = Color(0xFFE67E22);
  static const _bgColor = Color(0xFFFAFAFC);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _textMuted = Color(0xFF9CA3AF);
  static const _borderColor = Color(0xFFE5E5EA);
  static const _inputBg = Color(0xFFF5F5F7);

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
    _nameController.dispose();
    _ageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: r.wp(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: r.hp(16)),
                _buildBackButton(),
                SizedBox(height: r.hp(40)),
                Text(
                  'สร้างโปรไฟล์',
                  style: TextStyle(
                    fontSize: r.sp(28),
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: r.hp(8)),
                Text(
                  'เลือก avatar และกรอกข้อมูลของน้อง',
                  style: TextStyle(
                    fontSize: r.sp(14),
                    color: _textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: r.hp(40)),
                Center(
                  child: SizedBox(
                    height: r.hp(110),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: _avatars.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: r.wp(20)),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedAvatar == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatar = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(r.wp(4)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? _accentColor
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _accentColor.withOpacity(0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: CircleAvatar(
                              radius: r.wp(46),
                              backgroundColor: const Color(0xFFF5F5F7),
                              backgroundImage: AssetImage(_avatars[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: r.hp(48)),
                _buildTextField(
                  controller: _nameController,
                  label: 'ชื่อเล่น',
                  icon: Icons.person_outline_rounded,
                ),
                SizedBox(height: r.hp(16)),
                _buildTextField(
                  controller: _ageController,
                  label: 'อายุ',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: r.hp(48)),
                _buildSubmitButton(),
                SizedBox(height: r.hp(40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    final r = ResponsiveHelper.of(context);
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: r.wp(44),
        height: r.wp(44),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.radius(14)),
          border: Border.all(color: _borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_rounded,
          color: _textPrimary,
          size: r.iconSize(16),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final r = ResponsiveHelper.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: r.sp(15),
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: r.sp(14),
        ),
        floatingLabelStyle: const TextStyle(
          color: _accentColor,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: r.wp(16), right: r.wp(12)),
          child: Icon(icon, color: _textMuted, size: r.iconSize(20)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        filled: true,
        fillColor: _inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius(16)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius(16)),
          borderSide: const BorderSide(color: _borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius(16)),
          borderSide: const BorderSide(color: _accentColor, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.wp(16),
          vertical: r.hp(18),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final r = ResponsiveHelper.of(context);
    return GestureDetector(
      onTap: () async {
        final name = _nameController.text.trim();
        final age = int.tryParse(_ageController.text.trim());
        if (name.isNotEmpty && age != null) {
          final success = await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).registerChild(name, age, _avatars[_selectedAvatar]);
          if (success && mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.childHome);
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: r.hp(56),
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(r.radius(16)),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'เริ่มต้นใช้งาน',
            style: TextStyle(
              color: Colors.white,
              fontSize: r.sp(15),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
