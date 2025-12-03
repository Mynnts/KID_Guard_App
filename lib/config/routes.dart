import 'package:flutter/material.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/parent/parent_dashboard_screen.dart';
import '../presentation/child/child_home_screen.dart';
import '../presentation/child/child_mode_activation_screen.dart';
import '../presentation/onboarding/select_user_screen.dart';
import '../presentation/child/child_pin_screen.dart';
import '../presentation/parent/parent_settings_screen.dart';
import '../presentation/child/child_profile_setup_screen.dart';
import '../presentation/child/child_selection_screen.dart';
import '../presentation/parent/contacts/parent_contacts_screen.dart';
import '../presentation/parent/apps/parent_app_control_screen.dart';

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

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      selectUser: (context) => const SelectUserScreen(),
      login: (context) => const LoginScreen(),
      parentDashboard: (context) => const ParentDashboardScreen(),
      childHome: (context) => const ChildHomeScreen(),
      childActivation: (context) => const ChildModeActivationScreen(),
      childPin: (context) => const ChildPinScreen(),
      parentSettings: (context) => const ParentSettingsScreen(),
      childProfileSetup: (context) => const ChildProfileSetupScreen(),
      childSelection: (context) => const ChildSelectionScreen(),
      parentContacts: (context) => const ParentContactsScreen(),
      parentAppControl: (context) => const ParentAppControlScreen(),
    };
  }
}
