import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../core/utils/responsive_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class ChildPinScreen extends StatefulWidget {
  const ChildPinScreen({super.key});

  @override
  State<ChildPinScreen> createState() => _ChildPinScreenState();
}

class _ChildPinScreenState extends State<ChildPinScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  bool _hasError = false;

  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  // Ultra Minimal Color Palette
  static const _bgColor = Color(0xFFF8F9FC);
  static const _cardColor = Color(0xFFFFFFFF);
  static const _primaryColor = Color(0xFF6B9080); // Indigo
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF9CA3AF);
  static const _dotEmpty = Color(0xFFE5E7EB);
  static const _dotFilled = Color(0xFF6B9080);
  static const _errorColor = Color(0xFFEF4444);
  static const _keyBg = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String value) {
    if (_hasError) {
      setState(() => _hasError = false);
    }

    HapticFeedback.selectionClick();

    if (value == 'delete') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    } else if (_pin.length < 6) {
      setState(() => _pin += value);
      if (_pin.length == 6) {
        _submit();
      }
    }
  }

  void _submit() async {
    if (_pin.length != 6) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.childLogin(_pin);

    if (success && mounted) {
      // Save PIN immediately for session restore on app restart
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activeParentPin', _pin);
      if (auth.userModel != null) {
        await prefs.setString('activeParentUid', auth.userModel!.uid);
      }

      if (auth.children.isNotEmpty) {
        Navigator.pushReplacementNamed(context, AppRoutes.childSelection);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.childProfileSetup);
      }
    } else if (mounted) {
      setState(() => _hasError = true);
      HapticFeedback.heavyImpact();
      _shakeController.reset();
      _shakeController.forward();

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _pin = '';
          _hasError = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Minimal Header
                        Padding(
                          padding: EdgeInsets.all(r.wp(16)),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: r.wp(40),
                                  height: r.wp(40),
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(
                                      r.radius(12),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: _textPrimary,
                                    size: r.iconSize(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Simple Icon
                        Container(
                          width: r.wp(64),
                          height: r.wp(64),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(r.radius(20)),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: _primaryColor,
                            size: r.iconSize(28),
                          ),
                        ),

                        SizedBox(height: r.hp(24)),

                        // Title
                        Text(
                          'Enter PIN',
                          style: TextStyle(
                            fontSize: r.sp(24),
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),

                        SizedBox(height: r.hp(8)),

                        Text(
                          'Ask your parent for the code',
                          style: TextStyle(
                            fontSize: r.sp(14),
                            color: _textSecondary,
                          ),
                        ),

                        SizedBox(height: r.hp(32)),

                        // PIN Dots
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            final offset =
                                math.sin(_shakeAnimation.value * math.pi * 4) *
                                10 *
                                (1 - _shakeAnimation.value);
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: _buildPinDots(),
                        ),

                        SizedBox(height: r.hp(16)),

                        // Error text
                        SizedBox(
                          height: r.hp(20),
                          child: _hasError
                              ? Text(
                                  'Incorrect PIN',
                                  style: TextStyle(
                                    fontSize: r.sp(13),
                                    color: _errorColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    if (auth.isLoading) {
                                      return SizedBox(
                                        width: r.wp(16),
                                        height: r.hp(16),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primaryColor,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                        ),

                        const Spacer(flex: 1),

                        // Keypad
                        _buildKeypad(),

                        SizedBox(height: r.hp(32)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    final r = ResponsiveHelper.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _pin.length;
        final color = _hasError
            ? _errorColor
            : isFilled
            ? _dotFilled
            : _dotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: r.wp(6)),
          width: r.wp(12),
          height: r.wp(12),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final r = ResponsiveHelper.of(context);
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.wp(48)),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: r.hp(6)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return SizedBox(width: r.wp(64), height: r.wp(64));
                }
                return _buildKey(key);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String value) {
    final r = ResponsiveHelper.of(context);
    final isDelete = value == 'del';

    return GestureDetector(
      onTap: () => _onKeyPressed(isDelete ? 'delete' : value),
      child: Container(
        width: r.wp(64),
        height: r.wp(64),
        decoration: BoxDecoration(
          color: isDelete ? Colors.transparent : _keyBg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isDelete
              ? Icon(
                  Icons.backspace_outlined,
                  color: _textSecondary,
                  size: r.iconSize(22),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: r.sp(24),
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
