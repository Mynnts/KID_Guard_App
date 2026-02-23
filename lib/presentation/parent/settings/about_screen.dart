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

  // Premium Color Palette
  static const _primaryColor = Color(0xFF6B9080);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);
  static const _bgColor = Color(0xFFF8FAFC);

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
    final r = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: _bgColor,
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
                  color: Colors.white.withOpacity(0.2),
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
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -30,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withOpacity(0.05),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(r.radius(24)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Hero(
                              tag: 'app_logo',
                              child: Icon(
                                Icons.shield_rounded,
                                color: _primaryColor,
                                size: 50,
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
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Version $_version',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
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
                        color: _textPrimary,
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
                        color: _textSecondary,
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
                      icon: Icons.school_outlined,
                      title: 'Senior Project',
                      value: 'CPE @ KMUTT',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.code_rounded,
                      title: 'Framework',
                      value: 'Flutter 3.x',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
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
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () =>
                          _launchUrl('https://kidguard-app.web.app/privacy'),
                    ),
                    _buildDivider(),
                    _buildNavRow(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () =>
                          _launchUrl('https://kidguard-app.web.app/terms'),
                    ),
                    _buildDivider(),
                    _buildNavRow(
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
                                color: _textSecondary,
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
                                color: _textSecondary,
                                fontSize: r.sp(12),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: r.hp(8)),
                        Text(
                          '© 2025 Kid Guard Solution. All rights reserved.',
                          style: TextStyle(
                            color: _textSecondary.withOpacity(0.6),
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
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildClassicCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 22),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _primaryColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: _textSecondary,
        size: 20,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 54, color: Colors.grey.shade100);
  }
}
