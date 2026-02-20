import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _bgColor = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);

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
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_app_blocked', _appBlockedAlerts);
    await prefs.setBool('notif_time_limit', _timeLimitAlerts);
    await prefs.setBool('notif_location', _locationAlerts);
    await prefs.setBool('notif_daily_reports', _dailyReports);
    await prefs.setBool('notif_sound', _soundEnabled);
    await prefs.setBool('notif_vibration', _vibrationEnabled);
  }

  @override
  Widget build(BuildContext context) {
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
          'Notifications',
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
    return Text(
      title,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
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
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
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
    return Divider(height: 1, indent: 60, color: Colors.grey.shade200);
  }
}
