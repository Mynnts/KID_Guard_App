import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/locale_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/notification_model.dart';
import '../../../../l10n/app_localizations.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  // Colors
  static const _accentColor = Color(0xFF6B9080);

  static const List<Map<String, String>> _languages = [
    {'id': 'th', 'name': 'ไทย', 'nativeName': 'Thai', 'flag': '🇹🇭'},
    {'id': 'en', 'name': 'English', 'nativeName': 'อังกฤษ', 'flag': '🇺🇸'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final selectedLanguage = localeProvider.languageCode;

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
          'Language',
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
                      Icons.language,
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
                          'ภาษา',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'เลือกภาษาที่ต้องการใช้งาน',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Language Selection
            Text(
              'เลือกภาษา',
              style: TextStyle(
                color: colorScheme.onBackground.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Language Cards
            ..._languages.map(
              (lang) => _buildLanguageCard(
                context,
                lang,
                selectedLanguage,
                localeProvider,
              ),
            ),

            const SizedBox(height: 24),

            // Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'การเปลี่ยนภาษาจะมีผลทันที',
                      style: TextStyle(color: Colors.amber[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    Map<String, String> lang,
    String selectedLanguage,
    LocaleProvider localeProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedLanguage == lang['id'];

    return GestureDetector(
      onTap: () async {
        final oldLocale = localeProvider.languageCode;
        if (oldLocale == lang['id']) return;

        localeProvider.setLocale(lang['id']!);

        // Send notification
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.userModel != null) {
          final l10n = AppLocalizations.of(context)!;
          await NotificationService().addNotification(
            authProvider.userModel!.uid,
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: l10n.languageChangedTitle,
              message: l10n.languageChangedMessage(lang['name']!),
              timestamp: DateTime.now(),
              type: 'system',
              category: 'system',
              iconName: 'settings_rounded',
              colorValue: _accentColor.value,
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang['id'] == 'th'
                  ? 'เปลี่ยนเป็นภาษาไทยแล้ว'
                  : 'Changed to English',
            ),
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
            // Flag
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  lang['flag']!,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang['nativeName']!,
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
