import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/notification_model.dart';
import 'package:kidguard/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/responsive_helper.dart';

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
    final r = ResponsiveHelper.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: r.iconSize(18),
            ),
            SizedBox(width: r.wp(12)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: r.sp(14),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.radius(12)),
        ),
        margin: EdgeInsets.all(r.wp(20)),
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
    final r = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: r.wp(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: r.hp(24)),
                    _buildAvatar(user?.displayName ?? ''),
                    SizedBox(height: r.hp(32)),
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.displayName,
                    ),
                    SizedBox(height: r.hp(16)),
                    _buildNameCard(user?.displayName ?? ''),
                    SizedBox(height: r.hp(24)),
                    _buildEmailCard(user?.email ?? ''),
                    SizedBox(height: r.hp(32)),
                    _buildSectionTitle(AppLocalizations.of(context)!.password),
                    SizedBox(height: r.hp(16)),
                    _buildPasswordCard(),
                    SizedBox(height: r.hp(40)),
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
    final r = ResponsiveHelper.of(context);
    return Padding(
      padding: EdgeInsets.all(r.wp(16)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: r.wp(44),
              height: r.wp(44),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(r.radius(14)),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: _textPrimary,
                size: r.iconSize(16),
              ),
            ),
          ),
          SizedBox(width: r.wp(16)),
          Text(
            AppLocalizations.of(context)!.accountProfile,
            style: TextStyle(
              fontSize: r.sp(20),
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
    final r = ResponsiveHelper.of(context);
    return Center(
      child: Column(
        children: [
          Container(
            width: r.wp(100),
            height: r.wp(100),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: r.sp(40),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: r.hp(8)),
          SizedBox(height: r.hp(8)),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: r.wp(12),
                    vertical: r.hp(6),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(r.radius(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: r.iconSize(10),
                      ),
                      SizedBox(width: r.wp(6)),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: r.sp(13),
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
    final r = ResponsiveHelper.of(context);
    return Padding(
      padding: EdgeInsets.only(left: r.wp(4)),
      child: Text(
        title,
        style: TextStyle(
          color: _textSecondary,
          fontSize: r.sp(13),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNameCard(String currentName) {
    final authProvider = Provider.of<AuthProvider>(context);
    final r = ResponsiveHelper.of(context);

    return Container(
      padding: EdgeInsets.all(r.wp(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(20)),
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
                padding: EdgeInsets.all(r.wp(10)),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _primaryColor,
                  size: r.iconSize(22),
                ),
              ),
              SizedBox(width: r.wp(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: r.sp(15),
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: r.hp(2)),
                    Text(
                      AppLocalizations.of(context)!.displayNameDesc,
                      style: TextStyle(fontSize: r.sp(12), color: _textMuted),
                    ),
                  ],
                ),
              ),
              if (!_isEditingName)
                GestureDetector(
                  onTap: () => setState(() => _isEditingName = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.wp(14),
                      vertical: r.hp(8),
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(r.radius(10)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.edit,
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: r.sp(13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: r.hp(16)),
          if (_isEditingName) ...[
            TextFormField(
              controller: _nameController,
              style: TextStyle(
                fontSize: r.sp(15),
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterDisplayName,
                hintStyle: TextStyle(color: _textMuted, fontSize: r.sp(14)),
                filled: true,
                fillColor: _inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r.radius(14)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r.radius(14)),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r.radius(14)),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: r.wp(16),
                  vertical: r.hp(14),
                ),
              ),
            ),
            SizedBox(height: r.hp(14)),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isEditingName = false);
                      _nameController.text = currentName;
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: r.hp(14)),
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(r.radius(12)),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: r.sp(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: r.wp(12)),
                Expanded(
                  child: GestureDetector(
                    onTap: authProvider.isLoading ? null : _updateDisplayName,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: r.hp(14)),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(r.radius(12)),
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
                            ? SizedBox(
                                width: r.wp(20),
                                height: r.wp(20),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.save,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: r.sp(14),
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
              padding: EdgeInsets.symmetric(
                horizontal: r.wp(16),
                vertical: r.hp(14),
              ),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(r.radius(14)),
                border: Border.all(color: _borderColor),
              ),
              child: Text(
                currentName.isNotEmpty
                    ? currentName
                    : AppLocalizations.of(context)!.notSet,
                style: TextStyle(
                  fontSize: r.sp(15),
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
    final r = ResponsiveHelper.of(context);
    return Container(
      padding: EdgeInsets.all(r.wp(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(20)),
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
                padding: EdgeInsets.all(r.wp(10)),
                decoration: BoxDecoration(
                  color: _textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: _textSecondary,
                  size: r.iconSize(22),
                ),
              ),
              SizedBox(width: r.wp(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.email,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: r.sp(15),
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: r.hp(2)),
                    Text(
                      AppLocalizations.of(context)!.cannotBeChanged,
                      style: TextStyle(fontSize: r.sp(12), color: _textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.wp(10),
                  vertical: r.hp(6),
                ),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.radius(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _successColor,
                      size: r.iconSize(14),
                    ),
                    SizedBox(width: r.wp(4)),
                    Text(
                      AppLocalizations.of(context)!.verified,
                      style: TextStyle(
                        color: _successColor,
                        fontSize: r.sp(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.hp(16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: r.wp(16),
              vertical: r.hp(14),
            ),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(r.radius(14)),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              email,
              style: TextStyle(
                fontSize: r.sp(15),
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
    final r = ResponsiveHelper.of(context);

    return Container(
      padding: EdgeInsets.all(r.wp(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(20)),
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
                padding: EdgeInsets.all(r.wp(10)),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: _primaryColor,
                  size: r.iconSize(22),
                ),
              ),
              SizedBox(width: r.wp(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.password,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: r.sp(15),
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: r.hp(2)),
                    Text(
                      AppLocalizations.of(context)!.changePasswordDesc,
                      style: TextStyle(fontSize: r.sp(12), color: _textMuted),
                    ),
                  ],
                ),
              ),
              if (!_isChangingPassword)
                GestureDetector(
                  onTap: () => setState(() => _isChangingPassword = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.wp(14),
                      vertical: r.hp(8),
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(r.radius(10)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.change,
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: r.sp(13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_isChangingPassword) ...[
            SizedBox(height: r.hp(20)),
            _buildPasswordField(
              controller: _currentPasswordController,
              label: AppLocalizations.of(context)!.currentPassword,
              isVisible: _showCurrentPassword,
              onToggleVisibility: () =>
                  setState(() => _showCurrentPassword = !_showCurrentPassword),
            ),
            SizedBox(height: r.hp(14)),
            _buildPasswordField(
              controller: _newPasswordController,
              label: AppLocalizations.of(context)!.newPassword,
              isVisible: _showNewPassword,
              onToggleVisibility: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
            ),
            SizedBox(height: r.hp(14)),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: AppLocalizations.of(context)!.confirmNewPassword,
              isVisible: _showConfirmPassword,
              onToggleVisibility: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            SizedBox(height: r.hp(20)),
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
                      padding: EdgeInsets.symmetric(vertical: r.hp(14)),
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(r.radius(12)),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: r.sp(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: r.wp(12)),
                Expanded(
                  child: GestureDetector(
                    onTap: authProvider.isLoading ? null : _updatePassword,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: r.hp(14)),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(r.radius(12)),
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
                            ? SizedBox(
                                width: r.wp(20),
                                height: r.wp(20),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'เปลี่ยนรหัสผ่าน',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: r.sp(14),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: r.hp(16)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: r.wp(16),
                vertical: r.hp(14),
              ),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(r.radius(14)),
                border: Border.all(color: _borderColor),
              ),
              child: Text(
                '••••••••••',
                style: TextStyle(
                  fontSize: r.sp(15),
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
    final r = ResponsiveHelper.of(context);
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: TextStyle(
        fontSize: r.sp(15),
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: r.sp(14),
        ),
        floatingLabelStyle: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: r.sp(14),
        ),
        filled: true,
        fillColor: _inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius(14)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius(14)),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.radius(14)),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.wp(16),
          vertical: r.hp(14),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _textMuted,
            size: r.iconSize(20),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}
