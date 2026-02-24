import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../core/utils/responsive_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isPasswordVisible = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Minimal Premium Colors
  static const _primaryColor = Color(0xFF6B9080);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _textMuted = Color(0xFF9CA3AF);
  static const _bgColor = Color(0xFFFAFAFC);
  static const _inputBg = Color(0xFFF5F5F7);
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success;
    if (_isLogin) {
      success = await authProvider.signIn(email, password);
    } else {
      success = await authProvider.register(email, password, name);
    }

    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/parent/dashboard');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Text(
                  'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  void _toggleAuthMode() {
    _animController.reset();
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
    _animController.forward();
  }

  // ==================== ลืมรหัสผ่าน ====================
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    final r = ResponsiveHelper.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.radius(24)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_reset_rounded,
              color: _primaryColor,
              size: r.iconSize(24),
            ),
            SizedBox(width: r.wp(10)),
            Text(
              'ลืมรหัสผ่าน',
              style: TextStyle(
                fontSize: r.sp(18),
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กรอกอีเมลที่ใช้สมัคร ระบบจะส่งลิงก์\nรีเซ็ตรหัสผ่านไปที่อีเมลของคุณ',
              style: TextStyle(
                fontSize: r.sp(13),
                color: _textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: r.hp(16)),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'example@email.com',
                prefixIcon: Icon(
                  Icons.mail_outline_rounded,
                  color: _textMuted,
                  size: r.iconSize(20),
                ),
                filled: true,
                fillColor: _inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r.radius(14)),
                  borderSide: BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r.radius(14)),
                  borderSide: BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r.radius(14)),
                  borderSide: BorderSide(color: _primaryColor, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: _textSecondary, fontSize: r.sp(14)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('กรุณากรอกอีเมลให้ถูกต้อง'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ส่งลิงค์รีเซ็ตรหัสผ่านไปที่ $email แล้ว',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: _primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(20),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  String msg = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
                  if (e.code == 'user-not-found') {
                    msg = 'ไม่พบบัญชีที่ใช้อีเมลนี้';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(msg),
                        ],
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(20),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r.radius(12)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: r.wp(20),
                vertical: r.hp(12),
              ),
            ),
            child: Text('ส่งลิงค์รีเซ็ต', style: TextStyle(fontSize: r.sp(14))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final r = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: r.wp(28)),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: r.hp(16)),

                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildBackButton(),
                  ),

                  SizedBox(height: r.hp(48)),

                  // Icon
                  Center(child: _buildIcon()),

                  SizedBox(height: r.hp(32)),

                  // Title
                  Text(
                    _isLogin ? 'ยินดีต้อนรับกลับ' : 'สร้างบัญชีใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.sp(28),
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: r.hp(8)),

                  Text(
                    _isLogin
                        ? 'ลงชื่อเข้าใช้เพื่อดำเนินการต่อ'
                        : 'ลงทะเบียนเพื่อเริ่มต้นใช้งาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.sp(14),
                      color: _textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: r.hp(48)),

                  // Name Field (only for registration)
                  if (!_isLogin) ...[
                    _buildTextField(
                      controller: _nameController,
                      label: 'ชื่อที่แสดง',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกชื่อที่แสดง';
                        }
                        if (value.length < 2) {
                          return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: r.hp(16)),
                  ],

                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: 'อีเมล',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'กรุณากรอกอีเมล';
                      if (!value.contains('@')) return 'อีเมลไม่ถูกต้อง';
                      return null;
                    },
                  ),

                  SizedBox(height: r.hp(16)),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: 'รหัสผ่าน',
                    icon: Icons.lock_outline_rounded,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _textMuted,
                        size: r.iconSize(20),
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6)
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      return null;
                    },
                  ),

                  if (_isLogin) ...[
                    SizedBox(height: r.hp(12)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: r.hp(32)),

                  // Submit Button
                  if (authProvider.isLoading)
                    Center(
                      child: Container(
                        width: r.wp(52),
                        height: r.hp(52),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(r.radius(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: r.wp(24),
                            height: r.hp(24),
                            child: const CircularProgressIndicator(
                              color: _primaryColor,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildPrimaryButton(
                      onPressed: _submit,
                      text: _isLogin ? 'เข้าสู่ระบบ' : 'สร้างบัญชี',
                    ),

                  SizedBox(height: r.hp(32)),

                  // Divider
                  _buildDivider(),

                  SizedBox(height: r.hp(32)),

                  // Google Button
                  _buildGoogleButton(authProvider),

                  SizedBox(height: r.hp(40)),

                  // Switch Auth Mode
                  _buildAuthModeSwitch(),

                  SizedBox(height: r.hp(48)),
                ],
              ),
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
        height: r.hp(44),
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

  Widget _buildIcon() {
    final r = ResponsiveHelper.of(context);
    return Container(
      width: r.wp(72),
      height: r.wp(72),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(r.radius(22)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.person_outline_rounded,
        size: r.iconSize(34),
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final r = ResponsiveHelper.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
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
          color: _primaryColor,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: r.wp(16), right: r.wp(12)),
          child: Icon(icon, color: _textMuted, size: r.iconSize(20)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        suffixIcon: suffixIcon,
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
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius(16)),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius(16)),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.wp(16),
          vertical: r.hp(18),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    final r = ResponsiveHelper.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: r.hp(56),
        decoration: BoxDecoration(
          color: _primaryColor,
          borderRadius: BorderRadius.circular(r.radius(16)),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _borderColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'หรือ',
            style: TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: _borderColor)),
      ],
    );
  }

  Widget _buildGoogleButton(AuthProvider authProvider) {
    final r = ResponsiveHelper.of(context);
    return GestureDetector(
      onTap: () async {
        final success = await authProvider.signInWithGoogle();
        if (success && mounted) {
          Navigator.pushReplacementNamed(context, '/parent/dashboard');
        }
      },
      child: Container(
        height: r.hp(56),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.radius(16)),
          border: Border.all(color: _borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              width: r.wp(20),
              height: r.wp(20),
              errorBuilder: (_, __, ___) => Container(
                width: r.wp(20),
                height: r.wp(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(r.radius(6)),
                ),
                child: Icon(
                  Icons.g_mobiledata,
                  size: r.iconSize(16),
                  color: const Color(0xFF4285F4),
                ),
              ),
            ),
            SizedBox(width: r.wp(12)),
            Text(
              'ดำเนินการต่อด้วย Google',
              style: TextStyle(
                color: _textPrimary,
                fontSize: r.sp(14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthModeSwitch() {
    final r = ResponsiveHelper.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'ยังไม่มีบัญชี? ' : 'มีบัญชีอยู่แล้ว? ',
          style: TextStyle(
            color: _textSecondary,
            fontSize: r.sp(14),
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: _toggleAuthMode,
          child: Text(
            _isLogin ? 'ลงทะเบียน' : 'เข้าสู่ระบบ',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: r.sp(14),
            ),
          ),
        ),
      ],
    );
  }
}
