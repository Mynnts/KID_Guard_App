import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/theme_provider.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  // Colors
  static const _accentColor = Color(0xFF6B9080);
  static const _bgColor = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);

  static final List<Map<String, dynamic>> _themes = [
    {
      'id': 'light',
      'title': 'Light',
      'subtitle': 'โหมดสว่าง',
      'icon': Icons.light_mode,
      'colors': [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    },
    {
      'id': 'dark',
      'title': 'Dark',
      'subtitle': 'โหมดมืด',
      'icon': Icons.dark_mode,
      'colors': [Color(0xFF1E293B), Color(0xFF0F172A)],
    },
    {
      'id': 'system',
      'title': 'System',
      'subtitle': 'ตามระบบ',
      'icon': Icons.settings_suggest,
      'colors': [Color(0xFF6B9080), Color(0xFF84A98C)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedTheme = themeProvider.themeModeString;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Appearance',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentColor, _accentColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.palette,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ธีมและสี',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'เลือกรูปแบบการแสดงผลที่ต้องการ',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Theme Selection
            const Text(
              'เลือกธีม',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Theme Cards
            ..._themes.map(
              (theme) =>
                  _buildThemeCard(context, theme, selectedTheme, themeProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    Map<String, dynamic> theme,
    String selectedTheme,
    ThemeProvider themeProvider,
  ) {
    final isSelected = selectedTheme == theme['id'];

    return GestureDetector(
      onTap: () {
        themeProvider.setThemeMode(theme['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เปลี่ยนเป็น ${theme['title']} แล้ว'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _accentColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _accentColor.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Preview
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme['colors'],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                theme['icon'],
                color: theme['id'] == 'dark' ? Colors.white : _textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme['title'],
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    theme['subtitle'],
                    style: const TextStyle(color: _textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? _accentColor : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
