import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/app_info_model.dart';
import '../../../data/services/app_service.dart';
import '../../../logic/providers/auth_provider.dart';

class ParentAppControlScreen extends StatefulWidget {
  const ParentAppControlScreen({super.key});

  @override
  State<ParentAppControlScreen> createState() => _ParentAppControlScreenState();
}

class _ParentAppControlScreenState extends State<ParentAppControlScreen> {
  String _searchQuery = '';
  bool _showSystemApps = true; // Default to hidden

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final childId = authProvider.children.isNotEmpty
        ? authProvider.children.first.id
        : null;

    if (user == null || childId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('App Control')),
        body: const Center(child: Text('No child selected')),
      );
    }

    final appService = AppService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'App Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<AppInfoModel>>(
        stream: appService.streamApps(user.uid, childId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var apps = snapshot.data ?? [];

          // Filter by search query
          if (_searchQuery.isNotEmpty) {
            apps = apps
                .where(
                  (app) =>
                      app.name.toLowerCase().contains(_searchQuery) ||
                      app.packageName.toLowerCase().contains(_searchQuery),
                )
                .toList();
          }

          // Filter system apps
          if (!_showSystemApps) {
            apps = apps.where((app) => !app.isSystemApp).toList();
          }

          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apps_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No apps synced yet.'
                        : 'No apps found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure the child app is running and synced.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Group apps by blocked/allowed
          final blockedApps = apps.where((app) => app.isLocked).toList();
          final allowedApps = apps.where((app) => !app.isLocked).toList();

          return Column(
            children: [
              // Stats Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                    Container(width: 1, height: 40, color: Colors.white30),
                    _buildStatItem(
                      'Blocked',
                      blockedApps.length.toString(),
                      Icons.block,
                      Colors.red[300],
                    ),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _buildStatItem(
                      'Allowed',
                      allowedApps.length.toString(),
                      Icons.check_circle,
                      Colors.green[300],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Apps List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return _buildAppCard(
                      context,
                      app,
                      user.uid,
                      childId,
                      appService,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    AppInfoModel app,
    String parentUid,
    String childId,
    AppService appService,
  ) {
    final isBlocked = app.isLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showAppDetailsDialog(context, app, parentUid, childId, appService);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // App Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: app.iconBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(app.iconBase64!),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.android,
                          size: 32,
                          color: isBlocked ? Colors.red : Colors.green,
                        ),
                ),
                const SizedBox(width: 16),

                // App Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.packageName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBlocked ? Icons.block : Icons.check_circle,
                              size: 14,
                              color: isBlocked ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isBlocked ? 'Blocked' : 'Allowed',
                              style: TextStyle(
                                fontSize: 12,
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

                // Toggle Switch
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: !isBlocked, // ON = Allowed, OFF = Blocked
                    onChanged: (value) {
                      appService.toggleAppLock(
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

  void _showAppDetailsDialog(
    BuildContext context,
    AppInfoModel app,
    String parentUid,
    String childId,
    AppService appService,
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
              appService.toggleAppLock(
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }
}
