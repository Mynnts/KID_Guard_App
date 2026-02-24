import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/theme_provider.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/notification_model.dart';
import '../../../logic/providers/auth_provider.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  // Colors - Base Primary remains the same for brand identity
  static const _accentColor = Color(0xFF6B9080);

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedTheme = themeProvider.themeModeString;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            color: colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
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
                  colors: [_accentColor, _accentColor.withValues(alpha: 0.8)],
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
                      color: Colors.white.withValues(alpha: 0.2),
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
            Text(
              'เลือกธีม',
              style: TextStyle(
                color: colorScheme.onBackground.withValues(alpha: 0.6),
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
    Map<String, dynamic> themeData,
    String selectedTheme,
    ThemeProvider themeProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedTheme == themeData['id'];

    return GestureDetector(
      onTap: () async {
        if (isSelected) return; // Verify change

        themeProvider.setThemeMode(themeData['id']);

        // Send notification
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userModel;
        if (user != null) {
          await NotificationService().addNotification(
            user.uid,
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Theme Changed',
              message: 'App theme has been updated to ${themeData['title']}.',
              timestamp: DateTime.now(),
              type: 'system',
              category: 'system',
              iconName: 'settings_rounded',
              colorValue: Colors.purple.value,
            ),
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เปลี่ยนเป็น ${themeData['title']} แล้ว'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _accentColor
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _accentColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
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
                  colors: themeData['colors'],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                themeData['icon'],
                color: themeData['id'] == 'dark' ? Colors.white : Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    themeData['title'],
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    themeData['subtitle'],
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
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
                color: isSelected
                    ? _accentColor
                    : colorScheme.outline.withValues(alpha: 0.1),
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
