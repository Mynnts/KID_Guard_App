import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/auth_provider.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _appBlockedAlerts = true;
  bool _timeLimitAlerts = true;
  bool _locationAlerts = true;
  bool _dailyReports = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Colors
  static const _accentColor = Color(0xFF6B9080);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appBlockedAlerts = prefs.getBool('notif_app_blocked') ?? true;
      _timeLimitAlerts = prefs.getBool('notif_time_limit') ?? true;
      _locationAlerts = prefs.getBool('notif_location') ?? true;
      _dailyReports = prefs.getBool('notif_daily_reports') ?? false;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
    });

    // Sync from Firestore if available
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authProvider.userModel!.uid)
          .get();

      if (doc.exists &&
          doc.data()?.containsKey('notificationSettings') == true) {
        final settings =
            doc.data()!['notificationSettings'] as Map<String, dynamic>;
        setState(() {
          _appBlockedAlerts = settings['appBlocked'] ?? _appBlockedAlerts;
          _timeLimitAlerts = settings['timeLimit'] ?? _timeLimitAlerts;
          _locationAlerts = settings['location'] ?? _locationAlerts;
          _dailyReports = settings['dailyReports'] ?? _dailyReports;
          _soundEnabled = settings['sound'] ?? _soundEnabled;
          _vibrationEnabled = settings['vibration'] ?? _vibrationEnabled;
        });

        // Update local prefs to match Firestore
        await prefs.setBool('notif_app_blocked', _appBlockedAlerts);
        await prefs.setBool('notif_time_limit', _timeLimitAlerts);
        await prefs.setBool('notif_location', _locationAlerts);
        await prefs.setBool('notif_daily_reports', _dailyReports);
        await prefs.setBool('notif_sound', _soundEnabled);
        await prefs.setBool('notif_vibration', _vibrationEnabled);
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_app_blocked', _appBlockedAlerts);
    await prefs.setBool('notif_time_limit', _timeLimitAlerts);
    await prefs.setBool('notif_location', _locationAlerts);
    await prefs.setBool('notif_daily_reports', _dailyReports);
    await prefs.setBool('notif_sound', _soundEnabled);
    await prefs.setBool('notif_vibration', _vibrationEnabled);

    // Save to Firestore for cross-device sync
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authProvider.userModel!.uid)
          .set({
            'notificationSettings': {
              'appBlocked': _appBlockedAlerts,
              'timeLimit': _timeLimitAlerts,
              'location': _locationAlerts,
              'dailyReports': _dailyReports,
              'sound': _soundEnabled,
              'vibration': _vibrationEnabled,
            },
          }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          'Notifications',
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
                      Icons.notifications,
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
                          'จัดการการแจ้งเตือน',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'เลือกประเภทการแจ้งเตือนที่ต้องการรับ',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Alert Types Section
            _buildSectionTitle('ประเภทการแจ้งเตือน'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.block,
                title: 'แอพถูกบล็อก',
                subtitle: 'แจ้งเตือนเมื่อเด็กพยายามเปิดแอพที่ถูกบล็อก',
                value: _appBlockedAlerts,
                onChanged: (v) {
                  setState(() => _appBlockedAlerts = v);
                  _saveSettings();
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.timer,
                title: 'ใกล้หมดเวลา',
                subtitle: 'แจ้งเตือนเมื่อใกล้ถึงเวลาที่กำหนด',
                value: _timeLimitAlerts,
                onChanged: (v) {
                  setState(() => _timeLimitAlerts = v);
                  _saveSettings();
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.location_on,
                title: 'ตำแหน่ง',
                subtitle: 'แจ้งเตือนเมื่อเด็กออกนอกพื้นที่ปลอดภัย',
                value: _locationAlerts,
                onChanged: (v) {
                  setState(() => _locationAlerts = v);
                  _saveSettings();
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.summarize,
                title: 'รายงานประจำวัน',
                subtitle: 'รับสรุปการใช้งานทุกวัน',
                value: _dailyReports,
                onChanged: (v) {
                  setState(() => _dailyReports = v);
                  _saveSettings();
                },
              ),
            ]),

            const SizedBox(height: 28),

            // Sound & Vibration Section
            _buildSectionTitle('เสียงและการสั่น'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.volume_up,
                title: 'เสียงแจ้งเตือน',
                subtitle: 'เปิดเสียงเมื่อมีการแจ้งเตือน',
                value: _soundEnabled,
                onChanged: (v) {
                  setState(() => _soundEnabled = v);
                  _saveSettings();
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.vibration,
                title: 'การสั่น',
                subtitle: 'เปิดการสั่นเมื่อมีการแจ้งเตือน',
                value: _vibrationEnabled,
                onChanged: (v) {
                  setState(() => _vibrationEnabled = v);
                  _saveSettings();
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.onBackground.withValues(alpha: 0.6),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final colorScheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: 60,
      color: colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}
