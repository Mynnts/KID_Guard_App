import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isPasswordVisible = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Minimal Premium Colors
  static const _primaryColor = Color(0xFF4F46E5);
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
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success;
    if (_isLogin) {
      success = await authProvider.signIn(email, password);
    } else {
      success = await authProvider.register(email, password, 'Parent');
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
      _emailController.clear();
      _passwordController.clear();
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildBackButton(),
                  ),

                  const SizedBox(height: 48),

                  // Icon
                  Center(child: _buildIcon()),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    _isLogin ? 'ยินดีต้อนรับกลับ' : 'สร้างบัญชีใหม่',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _isLogin
                        ? 'ลงชื่อเข้าใช้เพื่อดำเนินการต่อ'
                        : 'ลงทะเบียนเพื่อเริ่มต้นใช้งาน',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 48),

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

                  const SizedBox(height: 16),

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
                        size: 20,
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Submit Button
                  if (authProvider.isLoading)
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
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

                  const SizedBox(height: 32),

                  // Divider
                  _buildDivider(),

                  const SizedBox(height: 32),

                  // Google Button
                  _buildGoogleButton(authProvider),

                  const SizedBox(height: 40),

                  // Switch Auth Mode
                  _buildAuthModeSwitch(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor, width: 1),
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
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        size: 34,
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, color: _textMuted, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _primaryColor,
          borderRadius: BorderRadius.circular(16),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
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
    return GestureDetector(
      onTap: () async {
        final success = await authProvider.signInWithGoogle();
        if (success && mounted) {
          Navigator.pushReplacementNamed(context, '/parent/dashboard');
        }
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) => Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.g_mobiledata,
                  size: 16,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ดำเนินการต่อด้วย Google',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthModeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'ยังไม่มีบัญชี? ' : 'มีบัญชีอยู่แล้ว? ',
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: _toggleAuthMode,
          child: Text(
            _isLogin ? 'ลงทะเบียน' : 'เข้าสู่ระบบ',
            style: const TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
