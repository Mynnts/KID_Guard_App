// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kid Guard';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get myChildren => 'My Children';

  @override
  String get addChild => 'Add Child';

  @override
  String get seeAll => 'See All';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSubtitle => 'Theme & colors';

  @override
  String get connection => 'Connection';

  @override
  String get general => 'General';

  @override
  String get support => 'Support';

  @override
  String get account => 'Account';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get about => 'About';

  @override
  String get signOut => 'Sign Out';

  @override
  String get points => 'Points';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get redeemRewards => 'Redeem Rewards';

  @override
  String get pointHistory => 'Point History';

  @override
  String get noActivity => 'No activity today';

  @override
  String get homework => 'Homework';

  @override
  String get chores => 'Chores';

  @override
  String get goodBehavior => 'Good Behavior';

  @override
  String get exercise => 'Exercise';

  @override
  String get iceCream => 'Ice Cream';

  @override
  String get gameTime => 'Game Time';

  @override
  String get movie => 'Movie';

  @override
  String get newToy => 'New Toy';

  @override
  String get stayUp => 'Stay Up Late';

  @override
  String get parkTrip => 'Park Trip';

  @override
  String needMorePoints(Object amount) {
    return 'Need $amount more points';
  }

  @override
  String get redeem => 'Redeem';

  @override
  String get cancel => 'Cancel';

  @override
  String redeemConfirm(Object reward) {
    return 'Redeem $reward?';
  }

  @override
  String redeemCost(Object cost) {
    return 'Use $cost points';
  }

  @override
  String get redeemNow => 'Redeem Now';

  @override
  String get success => 'Success!';

  @override
  String earnedReward(Object child, Object reward) {
    return '$child earned $reward';
  }

  @override
  String get close => 'Close';

  @override
  String pointsEarned(Object amount, Object reason) {
    return '+$amount points for $reason';
  }

  @override
  String redeemed(Object reward) {
    return 'Redeemed: $reward';
  }

  @override
  String get editChildProfile => 'Edit Child Profile';

  @override
  String get addChildProfile => 'Add Child Profile';

  @override
  String get updateProfileDesc => 'Update your child\'s profile settings.';

  @override
  String get createProfileDesc =>
      'Create a profile for your child to manage their device usage.';

  @override
  String get childName => 'Child\'s Name';

  @override
  String get childAge => 'Age';

  @override
  String get dailyTimeLimit => 'Daily Time Limit';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get hours => 'hours';

  @override
  String get selectMode => 'Select Mode';

  @override
  String get strictMode => 'Strict Mode';

  @override
  String get strictModeDesc => 'Block all apps except allowed ones.';

  @override
  String get flexibleMode => 'Flexible Mode';

  @override
  String get flexibleModeDesc => 'Allow all apps except blocked ones.';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get enterValidAge => 'Please enter a valid age';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String profileCreated(Object name) {
    return 'Profile for $name created successfully!';
  }

  @override
  String errorSavingProfile(Object error) {
    return 'Error saving profile: $error';
  }

  @override
  String get accountProfile => 'My Account';

  @override
  String get displayName => 'Display Name';

  @override
  String get displayNameDesc => 'Name to be displayed in app';

  @override
  String get email => 'Email';

  @override
  String get cannotBeChanged => 'Cannot be changed';

  @override
  String get verified => 'Verified';

  @override
  String get password => 'Password';

  @override
  String get changePasswordDesc => 'Change your password';

  @override
  String get change => 'Change';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get save => 'Save';

  @override
  String get notSet => 'Not set';

  @override
  String get enterDisplayName => 'Please enter display name';

  @override
  String get nameLengthError => 'Name must be at least 2 characters';

  @override
  String displayNameChanged(Object name) {
    return 'Your display name has been changed to \"$name\".';
  }

  @override
  String get updateSuccess => 'Update successful';

  @override
  String get updateError => 'An error occurred, please try again';

  @override
  String get enterCurrentPassword => 'Please enter current password';

  @override
  String get passwordLengthError =>
      'New password must be at least 6 characters';

  @override
  String get passwordMismatchError => 'Passwords do not match';

  @override
  String get securityAlert => 'Security Alert';

  @override
  String get passwordChangedSuccess =>
      'Your password was changed successfully.';

  @override
  String get passwordChangeSuccessMsg => 'Password changed successfully';

  @override
  String get currentPasswordIncorrect => 'Current password incorrect';

  @override
  String get parentAccount => 'Parent Account';

  @override
  String get edit => 'Edit';

  @override
  String get childAddedTitle => 'Child Added';

  @override
  String childAddedMessage(Object name) {
    return '$name has been added to your family.';
  }

  @override
  String get profileUpdatedTitle => 'Profile Updated';

  @override
  String profileUpdatedMessage(Object name) {
    return '$name\'s profile has been updated.';
  }

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';
}
