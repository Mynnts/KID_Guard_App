import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import 'package:kidguard/l10n/app_localizations.dart';
import '../../core/utils/responsive_helper.dart';

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
  int _selectedAvatarIndex = 0;

  final List<String> _avatars = [
    'assets/avatars/boy_1.png',
    'assets/avatars/girl_2.png',
    'assets/avatars/boy_3.png',
    'assets/avatars/boy_4.png',
    'assets/avatars/girl_5.png',
    'assets/avatars/girl_6.png',
    'assets/avatars/girl_7.png',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child?.name ?? '');
    _ageController = TextEditingController(
      text: widget.child?.age.toString() ?? '',
    );
    if (widget.child != null) {
      _dailyTimeLimit = (widget.child!.dailyTimeLimit / 60).round();
      // Find current avatar index
      if (widget.child!.avatar != null) {
        final idx = _avatars.indexOf(widget.child!.avatar!);
        if (idx >= 0) _selectedAvatarIndex = idx;
      }
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
    final r = ResponsiveHelper.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? AppLocalizations.of(context)!.editChildProfile
              : AppLocalizations.of(context)!.addChildProfile,
          style: TextStyle(fontSize: r.sp(18)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(r.wp(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing
                  ? AppLocalizations.of(context)!.updateProfileDesc
                  : AppLocalizations.of(context)!.createProfileDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: r.sp(14),
              ),
            ),
            SizedBox(height: r.hp(24)),

            // Avatar picker section
            Text(
              'เลือก Avatar',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: r.sp(16),
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: r.hp(16)),
            SizedBox(
              height: r.hp(100),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length,
                separatorBuilder: (_, __) => SizedBox(width: r.wp(12)),
                itemBuilder: (context, index) {
                  final isSelected = _selectedAvatarIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarIndex = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(r.wp(3)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: r.wp(36),
                        backgroundColor: colorScheme.tertiary.withOpacity(0.3),
                        backgroundImage: AssetImage(_avatars[index]),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: r.hp(28)),
            TextFormField(
              controller: _nameController,
              style: TextStyle(fontSize: r.sp(15)),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.childName,
                labelStyle: TextStyle(fontSize: r.sp(14)),
                prefixIcon: Icon(Icons.person_outline, size: r.iconSize(22)),
              ),
            ),
            SizedBox(height: r.hp(16)),
            TextFormField(
              controller: _ageController,
              style: TextStyle(fontSize: r.sp(15)),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.childAge,
                labelStyle: TextStyle(fontSize: r.sp(14)),
                prefixIcon: Icon(Icons.cake_outlined, size: r.iconSize(22)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: r.hp(32)),
            Text(
              '${AppLocalizations.of(context)!.dailyTimeLimit}: ${_dailyTimeLimit == 0 ? AppLocalizations.of(context)!.unlimited : "${(_dailyTimeLimit / 60).toStringAsFixed(1)} ${AppLocalizations.of(context)!.hours}"}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: r.sp(16),
              ),
            ),
            Slider(
              value: _dailyTimeLimit.toDouble(),
              min: 0,
              max: 480,
              divisions: 16,
              label: _dailyTimeLimit == 0
                  ? AppLocalizations.of(context)!.unlimited
                  : '${(_dailyTimeLimit / 60).toStringAsFixed(1)} ${AppLocalizations.of(context)!.hours}',
              onChanged: (value) {
                setState(() {
                  _dailyTimeLimit = value.toInt();
                });
              },
            ),
            SizedBox(height: r.hp(32)),
            Text(
              AppLocalizations.of(context)!.selectMode,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: r.sp(16),
              ),
            ),
            SizedBox(height: r.hp(16)),
            _buildModeOption(
              context,
              title: AppLocalizations.of(context)!.strictMode,
              description: AppLocalizations.of(context)!.strictModeDesc,
              icon: Icons.lock_outline,
              isSelected: true,
            ),
            SizedBox(height: r.hp(12)),
            _buildModeOption(
              context,
              title: AppLocalizations.of(context)!.flexibleMode,
              description: AppLocalizations.of(context)!.flexibleModeDesc,
              icon: Icons.lock_open_outlined,
              isSelected: false,
            ),
            SizedBox(height: r.hp(48)),
            ElevatedButton(
              onPressed: _saveChildProfile,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: r.hp(14)),
              ),
              child: Text(
                isEditing
                    ? AppLocalizations.of(context)!.saveChanges
                    : AppLocalizations.of(context)!.createProfile,
                style: TextStyle(fontSize: r.sp(15)),
              ),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.fillAllFields)),
      );
      return;
    }

    final age = int.tryParse(ageText);
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterValidAge)),
      );
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
        avatar: _avatars[_selectedAvatarIndex],
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
          .set(childToSave.toMap());

      // Send Notification only on create
      if (!isEditing) {
        await NotificationService().addNotification(
          user.uid,
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: AppLocalizations.of(context)!.childAddedTitle,
            message: AppLocalizations.of(context)!.childAddedMessage(name),
            timestamp: DateTime.now(),
            type: 'system',
            category: 'system',
            iconName: 'person_add_rounded',
            colorValue: Colors.green.value,
          ),
        );
      } else {
        await NotificationService().addNotification(
          user.uid,
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: AppLocalizations.of(context)!.profileUpdatedTitle,
            message: AppLocalizations.of(context)!.profileUpdatedMessage(name),
            timestamp: DateTime.now(),
            type: 'system',
            category: 'system',
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
                  ? AppLocalizations.of(context)!.profileUpdated
                  : AppLocalizations.of(context)!.profileCreated(name),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorSavingProfile(e.toString()),
            ),
          ),
        );
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
    final r = ResponsiveHelper.of(context);
    return Container(
      padding: EdgeInsets.all(r.wp(16)),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(r.radius(12)),
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
            size: r.iconSize(32),
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          SizedBox(width: r.wp(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: r.sp(14),
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: r.sp(12),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: r.iconSize(24),
            ),
        ],
      ),
    );
  }
}
