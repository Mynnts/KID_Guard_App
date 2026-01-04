import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../config/routes.dart';
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
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: _textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Simple Icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: _primaryColor,
                            size: 28,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Enter PIN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Ask your parent for the code',
                          style: TextStyle(fontSize: 14, color: _textSecondary),
                        ),

                        const SizedBox(height: 32),

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

                        const SizedBox(height: 16),

                        // Error text
                        SizedBox(
                          height: 20,
                          child: _hasError
                              ? const Text(
                                  'Incorrect PIN',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _errorColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    if (auth.isLoading) {
                                      return const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
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

                        const SizedBox(height: 32),
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
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 64, height: 64);
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
    final isDelete = value == 'del';

    return GestureDetector(
      onTap: () => _onKeyPressed(isDelete ? 'delete' : value),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isDelete ? Colors.transparent : _keyBg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isDelete
              ? const Icon(
                  Icons.backspace_outlined,
                  color: _textSecondary,
                  size: 22,
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
