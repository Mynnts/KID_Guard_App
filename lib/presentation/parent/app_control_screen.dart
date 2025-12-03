import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/app_service.dart';
import '../../data/models/app_info_model.dart';

class AppControlScreen extends StatefulWidget {
  final String childId;
  const AppControlScreen({super.key, required this.childId});

  @override
  State<AppControlScreen> createState() => _AppControlScreenState();
}

class _AppControlScreenState extends State<AppControlScreen> {
  final AppService _appService = AppService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('App Control')),
      body: StreamBuilder<List<AppInfoModel>>(
        stream: _appService.streamApps(user.uid, widget.childId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final apps = snapshot.data ?? [];

          if (apps.isEmpty) {
            return const Center(child: Text('No apps found. Syncing...'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: SwitchListTile(
                  value:
                      !app.isLocked, // UI shows "Allowed" (inverse of Locked)
                  onChanged: (bool value) {
                    _appService.toggleAppLock(
                      user.uid,
                      widget.childId,
                      app.packageName.replaceAll(
                        '.',
                        '_',
                      ), // Ensure ID matches sync logic
                      !value, // If allowed (true), locked is false
                    );
                  },
                  title: Text(
                    app.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(app.packageName),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.android, color: Colors.blueGrey),
                  ),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
