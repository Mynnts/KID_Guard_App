import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/notification_model.dart';
import 'package:kidguard/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditingName = false;
  bool _isChangingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Minimal Premium Colors
  static const _primaryColor = Color(0xFF6B9080);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _textMuted = Color(0xFF9CA3AF);
  static const _bgColor = Color(0xFFFAFAFC);
  static const _inputBg = Color(0xFFF5F5F7);
  static const _borderColor = Color(0xFFE5E5EA);
  static const _successColor = Color(0xFF10B981);
  static const _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      _nameController.text = user?.displayName ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _updateDisplayName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.enterDisplayName,
        isError: true,
      );
      return;
    }
    if (name.length < 2) {
      _showSnackBar(
        AppLocalizations.of(context)!.nameLengthError,
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateDisplayName(name);

    if (success) {
      if (mounted) setState(() => _isEditingName = false);

      // Send notification
      final user = authProvider.userModel;
      if (user != null) {
        await NotificationService().addNotification(
          user.uid,
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: AppLocalizations.of(context)!.profileUpdated,
            message: AppLocalizations.of(context)!.displayNameChanged(name),
            timestamp: DateTime.now(),
            type: 'system',
            iconName: 'check_circle_rounded',
            colorValue: Colors.blue.value,
          ),
        );
      }

      if (mounted) _showSnackBar(AppLocalizations.of(context)!.updateSuccess);
    } else {
      if (mounted)
        _showSnackBar(AppLocalizations.of(context)!.updateError, isError: true);
    }
  }

  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.enterCurrentPassword,
        isError: true,
      );
      return;
    }
    if (newPassword.length < 6) {
      _showSnackBar(
        AppLocalizations.of(context)!.passwordLengthError,
        isError: true,
      );
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnackBar(
        AppLocalizations.of(context)!.passwordMismatchError,
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updatePassword(
      currentPassword,
      newPassword,
    );

    if (success) {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });

        // Send notification
        final user = authProvider.userModel;
        if (user != null) {
          await NotificationService().addNotification(
            user.uid,
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: AppLocalizations.of(context)!.securityAlert,
              message: AppLocalizations.of(context)!.passwordChangedSuccess,
              timestamp: DateTime.now(),
              type: 'alert',
              iconName: 'warning_rounded',
              colorValue: Colors.red.value,
            ),
          );
        }

        _showSnackBar(AppLocalizations.of(context)!.passwordChangeSuccessMsg);
      }
    } else {
      if (mounted)
        _showSnackBar(
          AppLocalizations.of(context)!.currentPasswordIncorrect,
          isError: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Profile Avatar
                    _buildAvatar(user?.displayName ?? ''),

                    const SizedBox(height: 32),

                    // Display Name Section
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.displayName,
                    ),
                    const SizedBox(height: 16),
                    _buildNameCard(user?.displayName ?? ''),

                    const SizedBox(height: 24),

                    // Email Section (Read-only)
                    _buildEmailCard(user?.email ?? ''),

                    const SizedBox(height: 32),

                    // Password Section
                    _buildSectionTitle(AppLocalizations.of(context)!.password),
                    const SizedBox(height: 16),
                    _buildPasswordCard(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: _textPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context)!.accountProfile,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryColor, Color(0xFF84A98C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          if (Provider.of<AuthProvider>(context, listen: false).userModel !=
              null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(
                    Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).userModel!.uid,
                  )
                  .collection('children')
                  .snapshots(),
              builder: (context, snapshot) {
                bool isAnyChildOnline = false;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['lastActive'] as Timestamp?;
                    if (timestamp != null) {
                      final lastActive = timestamp.toDate();
                      if (DateTime.now().difference(lastActive).inMinutes < 2) {
                        isAnyChildOnline = true;
                        break;
                      }
                    }
                  }
                }

                final statusColor = isAnyChildOnline
                    ? _successColor
                    : _textMuted;
                final statusText = isAnyChildOnline
                    ? AppLocalizations.of(context)!.online
                    : AppLocalizations.of(context)!.offline;
                final statusIcon = isAnyChildOnline
                    ? Icons.circle
                    : Icons.circle_outlined;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 10),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNameCard(String currentName) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.displayNameDesc,
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              if (!_isEditingName)
                GestureDetector(
                  onTap: () => setState(() => _isEditingName = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.edit,
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditingName) ...[
            TextFormField(
              controller: _nameController,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterDisplayName,
                hintStyle: const TextStyle(color: _textMuted),
                filled: true,
                fillColor: _inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isEditingName = false);
                      _nameController.text = currentName;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: authProvider.isLoading ? null : _updateDisplayName,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.save,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              child: Text(
                currentName.isNotEmpty
                    ? currentName
                    : AppLocalizations.of(context)!.notSet,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: currentName.isNotEmpty ? _textPrimary : _textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailCard(String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  color: _textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.cannotBeChanged,
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: _successColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.verified,
                      style: const TextStyle(
                        color: _successColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              email,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.password,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.changePasswordDesc,
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              if (!_isChangingPassword)
                GestureDetector(
                  onTap: () => setState(() => _isChangingPassword = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.change,
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_isChangingPassword) ...[
            const SizedBox(height: 20),
            _buildPasswordField(
              controller: _currentPasswordController,
              label: AppLocalizations.of(context)!.currentPassword,
              isVisible: _showCurrentPassword,
              onToggleVisibility: () =>
                  setState(() => _showCurrentPassword = !_showCurrentPassword),
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _newPasswordController,
              label: AppLocalizations.of(context)!.newPassword,
              isVisible: _showNewPassword,
              onToggleVisibility: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: AppLocalizations.of(context)!.confirmNewPassword,
              isVisible: _showConfirmPassword,
              onToggleVisibility: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isChangingPassword = false;
                        _currentPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: authProvider.isLoading ? null : _updatePassword,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'เปลี่ยนรหัสผ่าน',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              child: const Text(
                '••••••••••',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _textMuted,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}
