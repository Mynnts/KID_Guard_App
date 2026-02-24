import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../config/routes.dart';
import '../onboarding/onboarding_screen.dart';
import 'package:kidguard/l10n/app_localizations.dart';
import '../../core/utils/responsive_helper.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel?.pin == null) {
        authProvider.generatePin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = authProvider.userModel;
    final pin = user?.pin;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: ResponsiveHelper.of(context).hp(100),
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                left: ResponsiveHelper.of(context).wp(16),
                bottom: ResponsiveHelper.of(context).hp(16),
              ),
              title: Text(
                AppLocalizations.of(context)!.settings,
                style: TextStyle(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.of(context).sp(24),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.of(context).wp(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  _buildProfileCard(
                    user?.displayName ?? 'Parent',
                    user?.email ?? '',
                  ),

                  const SizedBox(height: 24),

                  // PIN Section
                  _buildSectionTitle(AppLocalizations.of(context)!.connection),
                  const SizedBox(height: 12),
                  _buildPinCard(pin, authProvider.isLoading, authProvider),

                  const SizedBox(height: 24),

                  // General Settings Section
                  _buildSectionTitle(AppLocalizations.of(context)!.general),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    _SettingItem(
                      icon: Icons.notifications_outlined,
                      title: AppLocalizations.of(context)!.notifications,
                      subtitle: 'Manage alerts',
                      trailing: const _StatusDot(isActive: true),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsNotifications,
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.palette_outlined,
                      title: AppLocalizations.of(context)!.appearance,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.appearanceSubtitle,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsAppearance,
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.language_outlined,
                      title: AppLocalizations.of(context)!.language,
                      subtitle:
                          Localizations.localeOf(context).languageCode == 'th'
                          ? 'ไทย'
                          : 'English',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsLanguage,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Support Section
                  _buildSectionTitle(AppLocalizations.of(context)!.support),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    _SettingItem(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'วิธีใช้งาน',
                      subtitle: 'ดู Tutorial อีกครั้ง',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const OnboardingScreen(fromSettings: true),
                        ),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.help_outline,
                      title: AppLocalizations.of(context)!.helpCenter,
                      subtitle: 'FAQ & guides',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsHelpCenter,
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.feedback_outlined,
                      title: AppLocalizations.of(context)!.sendFeedback,
                      subtitle: 'Report issues',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsFeedback,
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.info_outline_rounded,
                      title: AppLocalizations.of(context)!.about,
                      subtitle:
                          Localizations.localeOf(context).languageCode == 'th'
                          ? 'ข้อมูลแอปพลิเคชัน'
                          : 'App information',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settingsAbout),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Danger Zone
                  _buildSectionTitle(AppLocalizations.of(context)!.account),
                  const SizedBox(height: 12),
                  _buildSignOutButton(authProvider),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String name, String email) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = ResponsiveHelper.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(r.wp(20)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r.radius(32)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.20),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(r.wp(3)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: r.wp(32),
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.sp(28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: r.wp(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: r.sp(20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: r.hp(4)),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: r.sp(14),
                    ),
                  ),
                  SizedBox(height: r.hp(8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.wp(10),
                      vertical: r.hp(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(r.radius(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: r.iconSize(14),
                        ),
                        SizedBox(width: r.wp(4)),
                        Text(
                          'Parent Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: r.sp(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(r.wp(8)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: r.iconSize(20),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/parent/account-profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinCard(String? pin, bool isLoading, AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = ResponsiveHelper.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(r.wp(20)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surface.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r.radius(24)),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(r.wp(10)),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(r.radius(12)),
                  ),
                  child: Icon(Icons.vpn_key, color: colorScheme.primary),
                ),
                SizedBox(width: r.wp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection PIN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: r.sp(16),
                        ),
                      ),
                      Text(
                        'Use this to link child devices',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: r.sp(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: r.hp(20)),
            // PIN Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: r.hp(20)),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(r.radius(16)),
              ),
              child: Center(
                child: isLoading
                    ? CircularProgressIndicator(color: colorScheme.primary)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(
                            pin?.length ?? 6,
                            (index) => _PinDigit(
                              digit: pin?[index] ?? '-',
                              delay: index * 100,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: r.hp(16)),
            // Copy button only
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pin != null
                    ? () {
                        Clipboard.setData(ClipboardData(text: pin));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('PIN copied to clipboard'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r.radius(10)),
                            ),
                          ),
                        );
                      }
                    : null,
                icon: Icon(Icons.copy, size: r.iconSize(18)),
                label: const Text('Copy PIN'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: r.hp(14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(r.radius(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final r = ResponsiveHelper.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: r.wp(4)),
      child: Text(
        title,
        style: TextStyle(
          color: colorScheme.onBackground.withValues(alpha: 0.6),
          fontSize: r.sp(13),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingItem> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = ResponsiveHelper.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surface.withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(r.radius(24)),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(r.wp(8)),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(r.radius(10)),
                    ),
                    child: Icon(
                      item.icon,
                      color: colorScheme.primary,
                      size: r.iconSize(22),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: r.sp(14),
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: r.sp(12),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.trailing != null) item.trailing!,
                      SizedBox(width: r.wp(8)),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: r.iconSize(14),
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  onTap: item.onTap,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: r.wp(56),
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignOutButton(AuthProvider authProvider) {
    final r = ResponsiveHelper.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(r.radius(16)),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(r.wp(8)),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(r.radius(10)),
            ),
            child: Icon(Icons.logout, color: Colors.red, size: r.iconSize(22)),
          ),
          title: Text(
            AppLocalizations.of(context)!.signOut,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: r.sp(14),
            ),
          ),
          subtitle: Text(
            'Log out of your account',
            style: TextStyle(
              color: Colors.red.withOpacity(0.7),
              fontSize: r.sp(12),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: r.iconSize(14),
            color: Colors.red.withOpacity(0.5),
          ),
          onTap: () async {
            await authProvider.signOut();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/select_user',
                (route) => false,
              );
            }
          },
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });
}

class _StatusDot extends StatelessWidget {
  final bool isActive;

  const _StatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'On' : 'Off',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDigit extends StatelessWidget {
  final String digit;
  final int delay;

  const _PinDigit({required this.digit, required this.delay});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value.clamp(0.0, 1.0)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        width: 36,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
