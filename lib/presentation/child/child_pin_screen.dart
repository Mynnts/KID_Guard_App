import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../config/routes.dart';

class ChildPinScreen extends StatefulWidget {
  const ChildPinScreen({super.key});

  @override
  State<ChildPinScreen> createState() => _ChildPinScreenState();
}

class _ChildPinScreenState extends State<ChildPinScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _hasError = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Minimal Premium Colors - Child Theme (Warm Orange)
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _pin => _pinControllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_hasError) setState(() => _hasError = false);
    if (_pin.length == 6) _submit();
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _pinControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _submit() async {
    final pin = _pin;
    if (pin.length != 6) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.childLogin(pin);

    if (success && mounted) {
      if (auth.children.isNotEmpty) {
        Navigator.pushReplacementNamed(context, AppRoutes.childSelection);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.childProfileSetup);
      }
    } else if (mounted) {
      setState(() => _hasError = true);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text(
                'รหัส PIN ไม่ถูกต้อง กรุณาลองใหม่',
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
      for (var c in _pinControllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildBackButton(),
                  ),

                  const SizedBox(height: 56),

                  // Icon
                  _buildIcon(),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'กรอกรหัส PIN',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'ขอรหัส 6 หลักจากผู้ปกครอง',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // PIN Boxes
                  _buildPinBoxes(),

                  const SizedBox(height: 40),

                  // Connect Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.isLoading) {
                        return Center(
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
                                  color: _accentColor,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildConnectButton();
                    },
                  ),

                  const SizedBox(height: 56),

                  // Help Card
                  _buildHelpCard(),

                  const SizedBox(height: 40),
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
      child: const Icon(
        Icons.child_care_outlined,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPinBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final hasValue = _pinControllers[index].text.isNotEmpty;
        final isFocused = _focusNodes[index].hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isFocused ? Colors.white : _inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasError
                  ? const Color(0xFFEF4444)
                  : isFocused
                  ? _accentColor
                  : hasValue
                  ? _accentColor.withOpacity(0.4)
                  : _borderColor,
              width: isFocused ? 1.5 : 1,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (e) => _onKeyPressed(index, e),
            child: TextFormField(
              controller: _pinControllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _hasError ? const Color(0xFFEF4444) : _textPrimary,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => _onDigitChanged(index, v),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildConnectButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_rounded, size: 20, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'เชื่อมต่อ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F5), width: 1),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'หารหัส PIN ที่ไหน?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ตั้งค่า → รหัสเชื่อมต่อ',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Arrow
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _textMuted),
        ],
      ),
    );
  }
}
