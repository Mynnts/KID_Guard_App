import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/responsive_helper.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';

  // Premium Color Palette - Base Primary remains the same for brand identity
  static const _primaryColor = Color(0xFF6B9080);

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final r = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Dynamic App Bar
          SliverAppBar(
            expandedHeight: r.hp(280),
            pinned: true,
            elevation: 0,
            backgroundColor: _primaryColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, Color(0xFF84A98C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -30,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: r.hp(40)),
                        // App Icon Wrapper
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Container(
                            width: r.wp(90),
                            height: r.wp(90),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(r.radius(24)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'app_logo',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  r.radius(24),
                                ),
                                child: Image.asset(
                                  'assets/icons/Kid_Guard.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: r.hp(16)),
                        Text(
                          'Kid Guard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: r.sp(28),
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: r.hp(4)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Version $_version',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(r.wp(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slogan
                  Center(
                    child: Text(
                      'Smart Protection for Your Little Wonders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onBackground,
                        fontSize: r.sp(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: r.hp(8)),
                  Center(
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'th'
                          ? 'ดูแลบุตรหลานของคุณให้ปลอดภัยในโลกดิจิทัล'
                          : 'Keep your children safe in the digital world.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onBackground.withValues(alpha: 0.6),
                        fontSize: r.sp(14),
                      ),
                    ),
                  ),

                  SizedBox(height: r.hp(32)),

                  // Project Details Section
                  _buildSectionTitle(
                    Localizations.localeOf(context).languageCode == 'th'
                        ? 'ข้อมูลโปรเจค'
                        : 'Project Information',
                  ),
                  SizedBox(height: r.hp(12)),
                  _buildClassicCard([
                    _buildInfoRow(
                      context,
                      icon: Icons.school_outlined,
                      title: 'Senior Project',
                      value: 'CPE @ KMUTT',
                    ),
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      icon: Icons.code_rounded,
                      title: 'Framework',
                      value: 'Flutter 3.x',
                    ),
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      icon: Icons.cloud_done_outlined,
                      title: 'Backend',
                      value: 'Firebase / Firestore',
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Legal & Support Section
                  _buildSectionTitle(
                    Localizations.localeOf(context).languageCode == 'th'
                        ? 'กฎหมายและข้อกำหนด'
                        : 'Legal & Support',
                  ),
                  SizedBox(height: r.hp(12)),
                  _buildClassicCard([
                    _buildNavRow(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () =>
                          _launchUrl('https://kidguard-app.web.app/privacy'),
                    ),
                    _buildDivider(context),
                    _buildNavRow(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () =>
                          _launchUrl('https://kidguard-app.web.app/terms'),
                    ),
                    _buildDivider(context),
                    _buildNavRow(
                      context,
                      icon: Icons.integration_instructions_outlined,
                      title: 'Open Source Licenses',
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'Kid Guard',
                          applicationVersion: _version,
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 40),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Made with ',
                              style: TextStyle(
                                color: colorScheme.onBackground.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: r.sp(12),
                              ),
                            ),
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 14,
                            ),
                            Text(
                              ' in Thailand',
                              style: TextStyle(
                                color: colorScheme.onBackground.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: r.sp(12),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: r.hp(8)),
                        Text(
                          '© 2025 Kid Guard Solution. All rights reserved.',
                          style: TextStyle(
                            color: colorScheme.onBackground.withValues(
                              alpha: 0.4,
                            ),
                            fontSize: r.sp(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorScheme.onBackground.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildClassicCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 22),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: _primaryColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurface.withValues(alpha: 0.4),
        size: 20,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: 54,
      color: colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}
