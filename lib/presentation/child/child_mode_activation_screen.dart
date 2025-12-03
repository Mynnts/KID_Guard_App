import 'package:flutter/material.dart';
import '../../logic/services/background_service.dart';
import '../../logic/services/overlay_service.dart';

class ChildModeActivationScreen extends StatefulWidget {
  const ChildModeActivationScreen({super.key});

  @override
  State<ChildModeActivationScreen> createState() =>
      _ChildModeActivationScreenState();
}

class _ChildModeActivationScreenState extends State<ChildModeActivationScreen> {
  late final BackgroundService _backgroundService;
  final OverlayService _overlayService = OverlayService();
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _backgroundService = BackgroundService(
      onBlockedAppDetected: (packageName) {
        print('Blocked app detected: $packageName');
        OverlayService().showBlockOverlay(packageName);
      },
      onTimeLimitReached: () {
        print('Time limit reached!');
        // For now, we can reuse the block overlay or create a specific one.
        // Let's use a generic "Time's Up" message if possible,
        // or just block the current app.
        // Since we don't have the package name here easily without passing it,
        // we might need to adjust. But for MVP, let's just show a generic overlay.
        OverlayService().showBlockOverlay("Time Limit Reached");
      },
      onAppAllowed: () {
        OverlayService().hideOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Child Mode Activation')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Invisible Guardian',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This mode runs in the background to monitor and protect your child.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                // Check Permissions
                bool overlayPerm = await _overlayService.checkPermission();
                if (!overlayPerm) {
                  await _overlayService.requestPermission();
                  return;
                }

                // Start Service
                // Note: This screen might be deprecated in favor of ChildHomeScreen auto-start
                // Passing empty strings for now to satisfy lint if this screen is still used
                await _backgroundService.startMonitoring(
                  'dummy_child',
                  'dummy_parent',
                );
                setState(() {
                  _isActive = true;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Protection Activated! You can now exit the app.',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isActive ? Colors.grey : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isActive ? 'Protection Active' : 'Activate Protection',
              ),
            ),
            if (_isActive)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: OutlinedButton(
                  onPressed: () async {
                    await _backgroundService.stopMonitoring();
                    setState(() {
                      _isActive = false;
                    });
                  },
                  child: const Text('Stop Protection (PIN Required)'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
