import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/app_info_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/services/app_service.dart';
import '../../../data/services/device_service.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../core/utils/responsive_helper.dart';

class ParentAppControlScreen extends StatefulWidget {
  const ParentAppControlScreen({super.key});

  @override
  State<ParentAppControlScreen> createState() => _ParentAppControlScreenState();
}

class _ParentAppControlScreenState extends State<ParentAppControlScreen> {
  String _searchQuery = '';
  bool _showSystemApps = true;
  String? _selectedChildId;
  String? _selectedDeviceId; // null means "All Devices"

  final AppService _appService = AppService();
  final DeviceService _deviceService = DeviceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.children.isNotEmpty && _selectedChildId == null) {
        setState(() {
          _selectedChildId = authProvider.children.first.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final children = authProvider.children;

    final childId =
        _selectedChildId ?? (children.isNotEmpty ? children.first.id : null);

    if (user == null || childId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('App Control')),
        body: const Center(child: Text('No child selected')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'App Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh apps from device',
            onPressed: () => _onRefreshPressed(user.uid, childId),
          ),
          PopupMenuButton<bool>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Apps',
            onSelected: (value) {
              setState(() {
                _showSystemApps = value;
              });
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: !_showSystemApps,
                checked: _showSystemApps,
                child: const Text('Show System Apps'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Selectors Section
          _buildSelectorsSection(children, childId),
          // Device Selector
          _buildDeviceSelector(user.uid, childId),
          // Search Field
          _buildSearchField(),
          // Apps List
          Expanded(child: _buildAppsList(user.uid, childId)),
        ],
      ),
    );
  }

  Widget _buildSelectorsSection(List<dynamic> children, String childId) {
    if (children.length <= 1) return const SizedBox.shrink();
    final r = ResponsiveHelper.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.wp(16), r.hp(16), r.wp(16), r.hp(8)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.wp(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.radius(12)),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: childId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: children.map((child) {
              return DropdownMenuItem<String>(
                value: child.id,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: r.wp(14),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        child.name.isNotEmpty
                            ? child.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: r.wp(12)),
                    Text(
                      child.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: r.sp(14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedChildId = value;
                  _selectedDeviceId = null;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSelector(String parentUid, String childId) {
    final r = ResponsiveHelper.of(context);
    return StreamBuilder<List<DeviceModel>>(
      stream: _deviceService.streamDevices(parentUid, childId),
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];

        if (devices.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(r.wp(16), r.hp(8), r.wp(16), r.hp(8)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: r.wp(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(r.radius(12)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedDeviceId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                hint: Row(
                  children: [
                    Icon(
                      Icons.devices,
                      size: r.iconSize(20),
                      color: Colors.grey,
                    ),
                    SizedBox(width: r.wp(12)),
                    const Text('ทุกอุปกรณ์'),
                  ],
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.devices,
                          size: r.iconSize(20),
                          color: Colors.grey,
                        ),
                        SizedBox(width: r.wp(12)),
                        const Text('ทุกอุปกรณ์'),
                      ],
                    ),
                  ),
                  ...devices.map((device) {
                    return DropdownMenuItem<String?>(
                      value: device.deviceId,
                      child: Row(
                        children: [
                          Icon(
                            Icons.smartphone,
                            size: r.iconSize(20),
                            color: device.isOnline ? Colors.green : Colors.grey,
                          ),
                          SizedBox(width: r.wp(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  device.deviceName,
                                  style: TextStyle(fontSize: r.sp(14)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  device.isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                                  style: TextStyle(
                                    fontSize: r.sp(11),
                                    color: device.isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDeviceId = value;
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    final r = ResponsiveHelper.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.wp(16), r.hp(8), r.wp(16), r.hp(16)),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search apps...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(r.radius(12)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: r.wp(16)),
        ),
      ),
    );
  }

  Widget _buildAppsList(String parentUid, String childId) {
    final r = ResponsiveHelper.of(context);
    final Stream<List<AppInfoModel>> appsStream;

    if (_selectedDeviceId != null) {
      appsStream = _appService.streamAppsForDevice(
        parentUid,
        childId,
        _selectedDeviceId!,
      );
    } else {
      appsStream = _appService.streamApps(parentUid, childId);
    }

    return StreamBuilder<List<AppInfoModel>>(
      stream: appsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var apps = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          apps = apps
              .where(
                (app) =>
                    app.name.toLowerCase().contains(_searchQuery) ||
                    app.packageName.toLowerCase().contains(_searchQuery),
              )
              .toList();
        }

        if (!_showSystemApps) {
          apps = apps.where((app) => !app.isSystemApp).toList();
        }

        if (apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apps_outlined,
                  size: r.iconSize(64),
                  color: Colors.grey[400],
                ),
                SizedBox(height: r.hp(16)),
                Text(
                  _searchQuery.isEmpty
                      ? 'No apps synced yet.'
                      : 'No apps found.',
                  style: TextStyle(fontSize: r.sp(16), color: Colors.grey[600]),
                ),
                SizedBox(height: r.hp(8)),
                Text(
                  'Make sure the child app is running and synced.',
                  style: TextStyle(fontSize: r.sp(14), color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final blockedApps = apps.where((app) => app.isLocked).toList();
        final allowedApps = apps.where((app) => !app.isLocked).toList();

        return Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: r.wp(16)),
              padding: EdgeInsets.all(r.wp(20)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(r.radius(16)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Apps',
                    apps.length.toString(),
                    Icons.apps,
                  ),
                  Container(width: 1, height: r.hp(40), color: Colors.white30),
                  _buildStatItem(
                    'Blocked',
                    blockedApps.length.toString(),
                    Icons.block,
                    Colors.red[300],
                  ),
                  Container(width: 1, height: r.hp(40), color: Colors.white30),
                  _buildStatItem(
                    'Allowed',
                    allowedApps.length.toString(),
                    Icons.check_circle,
                    Colors.green[300],
                  ),
                ],
              ),
            ),
            SizedBox(height: r.hp(16)),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: r.wp(16)),
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  return _buildAppCard(context, app, parentUid, childId);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onRefreshPressed(String parentUid, String childId) async {
    if (_selectedDeviceId != null) {
      // Refresh specific device
      await _deviceService.requestDeviceSync(
        parentUid,
        childId,
        _selectedDeviceId!,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.sync, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Expanded(child: Text('กำลังขอข้อมูลแอพจากอุปกรณ์ที่เลือก...')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Refresh all devices
      await _deviceService.requestAllDevicesSync(parentUid, childId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.sync, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Expanded(child: Text('กำลังขอข้อมูลแอพจากทุกอุปกรณ์...')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    final r = ResponsiveHelper.of(context);
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: r.iconSize(28)),
        SizedBox(height: r.hp(8)),
        Text(
          value,
          style: TextStyle(
            fontSize: r.sp(24),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: r.sp(12), color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    AppInfoModel app,
    String parentUid,
    String childId,
  ) {
    final isBlocked = app.isLocked;
    final r = ResponsiveHelper.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: r.hp(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(16)),
        border: Border.all(
          color: isBlocked
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(r.radius(16)),
          onTap: () {
            _showAppDetailsDialog(context, app, parentUid, childId);
          },
          child: Padding(
            padding: EdgeInsets.all(r.wp(16)),
            child: Row(
              children: [
                Container(
                  width: r.wp(56),
                  height: r.wp(56),
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(r.radius(12)),
                  ),
                  child: app.iconBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(r.radius(12)),
                          child: Image.memory(
                            base64Decode(app.iconBase64!),
                            width: r.wp(56),
                            height: r.wp(56),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.android,
                          size: r.iconSize(32),
                          color: isBlocked ? Colors.red : Colors.green,
                        ),
                ),
                SizedBox(width: r.wp(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: TextStyle(
                          fontSize: r.sp(16),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: r.hp(4)),
                      Text(
                        app.packageName,
                        style: TextStyle(
                          fontSize: r.sp(12),
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: r.hp(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.wp(8),
                          vertical: r.hp(4),
                        ),
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(r.radius(6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBlocked ? Icons.block : Icons.check_circle,
                              size: r.iconSize(14),
                              color: isBlocked ? Colors.red : Colors.green,
                            ),
                            SizedBox(width: r.wp(4)),
                            Text(
                              isBlocked ? 'Blocked' : 'Allowed',
                              style: TextStyle(
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.bold,
                                color: isBlocked ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: !isBlocked,
                    onChanged: (value) {
                      _toggleAppLock(
                        parentUid,
                        childId,
                        app.packageName,
                        !value,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? '${app.name} is now allowed'
                                : '${app.name} is now blocked',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleAppLock(
    String parentUid,
    String childId,
    String packageName,
    bool isLocked,
  ) {
    if (_selectedDeviceId != null) {
      // Toggle for specific device
      _appService.toggleAppLockForDevice(
        parentUid,
        childId,
        _selectedDeviceId!,
        packageName,
        isLocked,
      );
    } else {
      // Toggle for all devices
      _appService.toggleAppLockAllDevices(
        parentUid,
        childId,
        packageName,
        isLocked,
      );
    }
  }

  void _showAppDetailsDialog(
    BuildContext context,
    AppInfoModel app,
    String parentUid,
    String childId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.android, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                app.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Package', app.packageName),
            const SizedBox(height: 12),
            _buildDetailRow('Status', app.isLocked ? 'Blocked' : 'Allowed'),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Type',
              app.isSystemApp ? 'System App' : 'User App',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _toggleAppLock(
                parentUid,
                childId,
                app.packageName,
                !app.isLocked,
              );
              Navigator.pop(context);
            },
            icon: Icon(app.isLocked ? Icons.check_circle : Icons.block),
            label: Text(app.isLocked ? 'Allow' : 'Block'),
            style: ElevatedButton.styleFrom(
              backgroundColor: app.isLocked ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final r = ResponsiveHelper.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: r.wp(80),
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: r.sp(14),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[600], fontSize: r.sp(14)),
          ),
        ),
      ],
    );
  }
}
