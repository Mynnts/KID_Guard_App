import 'package:flutter/material.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/shared/parent_shell.dart';
import '../presentation/child/child_home_screen.dart';
import '../presentation/child/child_mode_activation_screen.dart';
import '../presentation/onboarding/select_user_screen.dart';
import '../presentation/child/child_pin_screen.dart';
import '../presentation/parent/parent_settings_screen.dart';
import '../presentation/child/child_profile_setup_screen.dart';
import '../presentation/child/child_selection_screen.dart';
import '../presentation/parent/contacts/parent_contacts_screen.dart';
import '../presentation/parent/apps/parent_app_control_screen.dart';
import '../presentation/parent/account_profile_screen.dart';
// Settings Screens
import '../presentation/parent/settings/notifications_settings_screen.dart';
import '../presentation/parent/settings/appearance_settings_screen.dart';
import '../presentation/parent/settings/language_settings_screen.dart';
import '../presentation/parent/settings/help_center_screen.dart';
import '../presentation/parent/settings/feedback_screen.dart';
import '../presentation/parent/settings/about_screen.dart';
import '../presentation/child/friendly_lock_screen.dart';

class AppRoutes {
  static const String selectUser = '/select_user';
  static const String login = '/login';
  static const String parentDashboard = '/parent/dashboard';
  static const String childHome = '/child/home';
  static const String childActivation = '/child/activation';
  static const String childPin = '/child/pin';
  static const String parentSettings = '/parent/settings';
  static const String childProfileSetup = '/child/profile_setup';
  static const String childSelection = '/child/selection';
  static const String parentContacts = '/parent/contacts';
  static const String parentAppControl = '/parent/app_control';
  static const String parentAccountProfile = '/parent/account-profile';
  // Settings Routes
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsLanguage = '/settings/language';
  static const String settingsHelpCenter = '/settings/help-center';
  static const String settingsFeedback = '/settings/feedback';
  static const String settingsAbout = '/settings/about';
  static const String childFriendlyLock = '/child/friendly-lock';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      selectUser: (context) => const SelectUserScreen(),
      login: (context) => const LoginScreen(),
      parentDashboard: (context) => const ParentShell(),
      childHome: (context) => const ChildHomeScreen(),
      childActivation: (context) => const ChildModeActivationScreen(),
      childPin: (context) => const ChildPinScreen(),
      parentSettings: (context) => const ParentSettingsScreen(),
      childProfileSetup: (context) => const ChildProfileSetupScreen(),
      childSelection: (context) => const ChildSelectionScreen(),
      parentContacts: (context) => const ParentContactsScreen(),
      parentAppControl: (context) => const ParentAppControlScreen(),
      parentAccountProfile: (context) => const AccountProfileScreen(),
      // Settings Routes
      settingsNotifications: (context) => const NotificationsSettingsScreen(),
      settingsAppearance: (context) => const AppearanceSettingsScreen(),
      settingsLanguage: (context) => const LanguageSettingsScreen(),
      settingsHelpCenter: (context) => const HelpCenterScreen(),
      settingsFeedback: (context) => const FeedbackScreen(),
      settingsAbout: (context) => const AboutScreen(),
      childFriendlyLock: (context) => const FriendlyLockScreen(),
    };
  }
}
