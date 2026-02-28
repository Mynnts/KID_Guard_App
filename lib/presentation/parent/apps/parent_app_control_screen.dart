import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/app_info_model.dart';
import '../../../data/services/app_service.dart';
import '../../../data/services/device_service.dart';
import '../../../logic/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/responsive_helper.dart';

class ParentAppControlScreen extends StatefulWidget {
  final String? childId;
  final String? childName;

  const ParentAppControlScreen({super.key, this.childId, this.childName});

  @override
  State<ParentAppControlScreen> createState() => _ParentAppControlScreenState();
}

class _ParentAppControlScreenState extends State<ParentAppControlScreen> {
  String _searchQuery = '';
  bool _showSystemApps = false;
  String? _selectedChildId;
  final Map<String, bool> _optimisticLocks =
      {}; // Local state for instant feedback

  final AppService _appService = AppService();
  final DeviceService _deviceService = DeviceService();

  Stream<List<AppInfoModel>>? _appsStream;
  Stream<DocumentSnapshot>? _childStream;
  String? _lastStreamChildId;
  String? _lastStreamParentUid;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_selectedChildId == null && authProvider.children.isNotEmpty) {
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

    // Initialize or update streams only if IDs changed
    if (_appsStream == null ||
        _childStream == null ||
        _lastStreamChildId != childId ||
        _lastStreamParentUid != user.uid) {
      _lastStreamChildId = childId;
      _lastStreamParentUid = user.uid;
      _appsStream = _appService.streamApps(user.uid, childId);
      _childStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(childId)
          .snapshots();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _childStream,
      builder: (context, childSnapshot) {
        final childData = childSnapshot.data?.data() as Map<String, dynamic>?;
        final bool isSystemActive = childData?['isChildModeActive'] ?? false;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            title: Text(
              widget.childName != null
                  ? 'App Control - ${widget.childName}'
                  : 'App Control',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: isSystemActive
                    ? 'Refresh apps from device'
                    : 'Child Mode must be active to refresh',
                onPressed: isSystemActive
                    ? () => _onRefreshPressed(user.uid, childId)
                    : null,
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
              if (!isSystemActive)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber[800],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'กรุณาเปิด "โหมดป้องกัน" ที่เครื่องของลูกก่อน เพื่อดึงข้อมูลและจัดการแอป',
                          style: TextStyle(
                            color: Colors.amber[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Search Field
              _buildSearchField(isSystemActive),

              // Apps List
              Expanded(
                child: isSystemActive
                    ? _buildAppsList(user.uid, childId, isSystemActive)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_clock_rounded,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ระบบป้องกันยังไม่ได้ถูกเปิดใช้งาน',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'เปิดโหมดเด็กที่เครื่องลูกเพื่อเริ่มจัดการ',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField(bool isSystemActive) {
    final r = ResponsiveHelper.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.wp(16), r.hp(8), r.wp(16), r.hp(16)),
      child: TextField(
        enabled: isSystemActive,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: isSystemActive ? 'Search apps...' : 'ระบบไม่ทำงาน',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: isSystemActive ? Colors.white : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(r.radius(12)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: r.wp(16)),
        ),
      ),
    );
  }

  Widget _buildAppsList(String parentUid, String childId, bool isSystemActive) {
    final r = ResponsiveHelper.of(context);

    return StreamBuilder<List<AppInfoModel>>(
      stream: _appsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
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
                  var app = apps[index];
                  // Use optimistic state if available
                  if (_optimisticLocks.containsKey(app.packageName)) {
                    if (_optimisticLocks[app.packageName] == app.isLocked) {
                      // Stream has caught up! remove from optimistic map
                      _optimisticLocks.remove(app.packageName);
                    } else {
                      // Still waiting, override with optimistic
                      app = app.copyWith(
                        isLocked: _optimisticLocks[app.packageName]!,
                      );
                    }
                  }
                  return _buildAppCard(
                    context,
                    app,
                    parentUid,
                    childId,
                    isSystemActive,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onRefreshPressed(String parentUid, String childId) async {
    // Refresh all devices for the selected child
    await _deviceService.requestAllDevicesSync(parentUid, childId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.sync, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Expanded(child: Text('กำลังขอข้อมูลแอพจากอุปกรณ์ลูก...')),
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
    bool isSystemActive,
  ) {
    final isBlocked = app.isLocked;
    final r = ResponsiveHelper.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: r.hp(12)),
      decoration: BoxDecoration(
        color: isSystemActive ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(r.radius(16)),
        border: Border.all(
          color: isBlocked
              ? Colors.red.withOpacity(isSystemActive ? 0.3 : 0.1)
              : Colors.green.withOpacity(isSystemActive ? 0.3 : 0.1),
          width: 2,
        ),
        boxShadow: [
          if (isSystemActive)
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
          onTap: isSystemActive
              ? () {
                  _showAppDetailsDialog(
                    context,
                    app,
                    parentUid,
                    childId,
                    isSystemActive,
                  );
                }
              : null,
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
                          child: Opacity(
                            opacity: isSystemActive ? 1.0 : 0.5,
                            child: Image.memory(
                              base64Decode(app.iconBase64!),
                              key: ValueKey(
                                '${app.packageName}_${app.iconBase64!.hashCode}',
                              ),
                              width: r.wp(56),
                              height: r.wp(56),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.android,
                          size: r.iconSize(32),
                          color: (isBlocked ? Colors.red : Colors.green)
                              .withOpacity(isSystemActive ? 1.0 : 0.5),
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
                          color: isSystemActive ? Colors.black : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: r.hp(4)),
                      Text(
                        app.packageName,
                        style: TextStyle(
                          fontSize: r.sp(12),
                          color: Colors.grey[isSystemActive ? 600 : 400],
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
                    onChanged: isSystemActive
                        ? (value) {
                            final newLockedState = !value;

                            // Optimistic Update: Update UI immediately
                            setState(() {
                              _optimisticLocks[app.packageName] =
                                  newLockedState;
                            });

                            _toggleAppLock(
                              parentUid,
                              childId,
                              app.packageName,
                              newLockedState,
                            );
                          }
                        : null,
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
  ) async {
    try {
      await _appService.toggleAppLockAllDevices(
        parentUid,
        childId,
        packageName,
        isLocked,
      );

      // We don't remove from _optimisticLocks here anymore.
      // Instead, we let the StreamBuilder handle it when it sees the updated value.
      // This prevents the "flicker" if Firestore is slow.
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticLocks.remove(packageName);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating lock status: $e')),
        );
      }
    }
  }

  void _showAppDetailsDialog(
    BuildContext context,
    AppInfoModel app,
    String parentUid,
    String childId,
    bool isSystemActive,
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
          if (isSystemActive)
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
