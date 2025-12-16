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

class _ChildPinScreenState extends State<ChildPinScreen> {
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _hasError = false;

  // Theme Colors
  static const _primaryColor = Color(0xFFF97316); // Orange
  static const _bgColor = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
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
          content: const Text('Invalid PIN. Please try again.'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 32,
                  color: _primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Enter Parent PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Ask your parent for the 6-digit PIN',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),

              const SizedBox(height: 48),

              // PIN Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 44,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (e) => _onKeyPressed(index, e),
                      child: TextFormField(
                        controller: _pinControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _hasError ? Colors.red : _primaryColor,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _hasError
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.grey[200]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _hasError ? Colors.red : _primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (v) => _onDigitChanged(index, v),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Connect Button
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.link_rounded, size: 20),
                      label: const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Help Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Where to find PIN?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Settings → Connection PIN',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
