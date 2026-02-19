import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

class ChildSetupScreen extends StatefulWidget {
  final ChildModel? child;
  const ChildSetupScreen({super.key, this.child});

  @override
  State<ChildSetupScreen> createState() => _ChildSetupScreenState();
}

class _ChildSetupScreenState extends State<ChildSetupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  int _dailyTimeLimit = 0; // in minutes

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child?.name ?? '');
    _ageController = TextEditingController(
      text: widget.child?.age.toString() ?? '',
    );
    if (widget.child != null) {
      _dailyTimeLimit = (widget.child!.dailyTimeLimit / 60).round();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.child != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Child Profile' : 'Add Child Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing
                  ? 'Update your child\'s profile settings.'
                  : 'Create a profile for your child to manage their device usage.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundImage: widget.child?.avatar != null
                        ? AssetImage(widget.child!.avatar!)
                        : null,
                    child: widget.child?.avatar == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Child\'s Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            Text(
              'Daily Time Limit: ${_dailyTimeLimit == 0 ? "Unlimited" : "${(_dailyTimeLimit / 60).toStringAsFixed(1)} hours"}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _dailyTimeLimit.toDouble(),
              min: 0,
              max: 480, // 8 hours
              divisions: 16, // 30 min steps
              label: _dailyTimeLimit == 0
                  ? 'Unlimited'
                  : '${(_dailyTimeLimit / 60).toStringAsFixed(1)} h',
              onChanged: (value) {
                setState(() {
                  _dailyTimeLimit = value.toInt();
                });
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Select Mode',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // TODO: Implement actual mode selection logic. currently just UI
            _buildModeOption(
              context,
              title: 'Strict Mode',
              description: 'Block all apps except allowed ones.',
              icon: Icons.lock_outline,
              isSelected: true,
            ),
            const SizedBox(height: 12),
            _buildModeOption(
              context,
              title: 'Flexible Mode',
              description: 'Allow all apps except blocked ones.',
              icon: Icons.lock_open_outlined,
              isSelected: false,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _saveChildProfile,
              child: Text(isEditing ? 'Save Changes' : 'Create Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChildProfile() async {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();

    if (name.isEmpty || ageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final age = int.tryParse(ageText);
    if (age == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a valid age')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final isEditing = widget.child != null;
      final childId = isEditing
          ? widget.child!.id
          : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('children')
                .doc()
                .id;

      final childToSave = ChildModel(
        id: childId,
        parentId: user.uid,
        name: name,
        age: age,
        dailyTimeLimit: _dailyTimeLimit * 60, // Convert minutes to seconds
        isLocked: isEditing ? widget.child!.isLocked : false,
        // Preserve existing values if editing, or defaults
        avatar: isEditing ? widget.child!.avatar : null,
        screenTime: isEditing ? widget.child!.screenTime : 0,
        limitUsedTime: isEditing ? widget.child!.limitUsedTime : 0,
        isOnline: isEditing ? widget.child!.isOnline : false,
        lastActive: isEditing ? widget.child!.lastActive : null,
        sessionStartTime: isEditing ? widget.child!.sessionStartTime : null,
        isChildModeActive: isEditing ? widget.child!.isChildModeActive : false,
        unlockRequested: isEditing ? widget.child!.unlockRequested : false,
        timeLimitDisabledUntil: isEditing
            ? widget.child!.timeLimitDisabledUntil
            : null,
        lockReason: isEditing ? widget.child!.lockReason : '',
        points: isEditing ? widget.child!.points : 0,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(childId)
          .set(
            childToSave.toMap(),
          ); // set with merge usually better effectively but toMap returns full object so set is fine

      // Send Notification only on create
      if (!isEditing) {
        await NotificationService().addNotification(
          user.uid,
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Child Added',
            message: '$name has been added to your family.',
            timestamp: DateTime.now(),
            type: 'system',
            iconName: 'person_add_rounded',
            colorValue: Colors.green.value,
          ),
        );
      } else {
        // Notification for profile update? Maybe effectively
        await NotificationService().addNotification(
          user.uid,
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Profile Updated',
            message: '$name\'s profile has been updated.',
            timestamp: DateTime.now(),
            type: 'system',
            iconName: 'edit_rounded',
            colorValue: Colors.blue.value,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        Navigator.pop(context); // Pop screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Profile updated successfully!'
                  : 'Profile for $name created successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
