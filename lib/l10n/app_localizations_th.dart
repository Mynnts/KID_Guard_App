// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Kid Guard';

  @override
  String get goodMorning => 'สวัสดีตอนเช้า';

  @override
  String get goodAfternoon => 'สวัสดีตอนบ่าย';

  @override
  String get goodEvening => 'สวัสดีตอนเย็น';

  @override
  String get myChildren => 'ลูกหลานของฉัน';

  @override
  String get addChild => 'เพิ่มลูกหลาน';

  @override
  String get seeAll => 'ดูทั้งหมด';

  @override
  String get quickActions => 'เมนูด่วน';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get profile => 'โปรไฟล์';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get language => 'ภาษา';

  @override
  String get appearance => 'การแสดงผล';

  @override
  String get appearanceSubtitle => 'ธีมและสี';

  @override
  String get connection => 'การเชื่อมต่อ';

  @override
  String get general => 'ทั่วไป';

  @override
  String get support => 'ช่วยเหลือ';

  @override
  String get account => 'บัญชี';

  @override
  String get helpCenter => 'ศูนย์ช่วยเหลือ';

  @override
  String get sendFeedback => 'ส่งข้อเสนอแนะ';

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get points => 'แต้ม';

  @override
  String get quickAdd => 'เพิ่มแต้มด่วน';

  @override
  String get redeemRewards => 'แลกของรางวัล';

  @override
  String get pointHistory => 'ประวัติแต้ม';

  @override
  String get noActivity => 'ไม่มีกิจกรรมในวันนี้';

  @override
  String get homework => 'การบ้าน';

  @override
  String get chores => 'งานบ้าน';

  @override
  String get goodBehavior => 'ความประพฤติดี';

  @override
  String get exercise => 'ออกกำลังกาย';

  @override
  String get iceCream => 'ไอศกรีม';

  @override
  String get gameTime => 'เวลาเล่นเกม';

  @override
  String get movie => 'ดูหนัง';

  @override
  String get newToy => 'ของเล่นใหม่';

  @override
  String get stayUp => 'นอนดึกได้';

  @override
  String get parkTrip => 'ไปสวนสาธารณะ';

  @override
  String needMorePoints(Object amount) {
    return 'ต้องการอีก $amount แต้ม';
  }

  @override
  String get redeem => 'แลก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String redeemConfirm(Object reward) {
    return 'แลก $reward?';
  }

  @override
  String redeemCost(Object cost) {
    return 'ใช้ $cost แต้ม';
  }

  @override
  String get redeemNow => 'แลกเลย';

  @override
  String get success => 'สำเร็จ!';

  @override
  String earnedReward(Object child, Object reward) {
    return '$child ได้รับ $reward';
  }

  @override
  String get close => 'ปิด';

  @override
  String pointsEarned(Object amount, Object reason) {
    return '+$amount แต้ม สำหรับ $reason';
  }

  @override
  String redeemed(Object reward) {
    return 'แลก: $reward';
  }

  @override
  String get editChildProfile => 'แก้ไขโปรไฟล์บุตรหลาน';

  @override
  String get addChildProfile => 'เพิ่มโปรไฟล์บุตรหลาน';

  @override
  String get updateProfileDesc => 'อัปเดตการตั้งค่าโปรไฟล์ของบุตรหลาน';

  @override
  String get createProfileDesc => 'สร้างโปรไฟล์เพื่อจัดการการใช้งานอุปกรณ์';

  @override
  String get childName => 'ชื่อบุตรหลาน';

  @override
  String get childAge => 'อายุ';

  @override
  String get dailyTimeLimit => 'จำกัดเวลาต่อวัน';

  @override
  String get unlimited => 'ไม่จำกัด';

  @override
  String get hours => 'ชั่วโมง';

  @override
  String get selectMode => 'เลือกโหมด';

  @override
  String get strictMode => 'โหมดเข้มงวด';

  @override
  String get strictModeDesc => 'บล็อกทุกแอพยกเว้นที่อนุญาต';

  @override
  String get flexibleMode => 'โหมดยืดหยุ่น';

  @override
  String get flexibleModeDesc => 'อนุญาตทุกแอพยกเว้นที่บล็อก';

  @override
  String get saveChanges => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get createProfile => 'สร้างโปรไฟล์';

  @override
  String get fillAllFields => 'กรุณากรอกข้อมูลให้ครบถ้วน';

  @override
  String get enterValidAge => 'กรุณากรอกอายุที่ถูกต้อง';

  @override
  String get profileUpdated => 'อัปเดตโปรไฟล์เรียบร้อยแล้ว!';

  @override
  String profileCreated(Object name) {
    return 'สร้างโปรไฟล์สำหรับ $name เรียบร้อยแล้ว!';
  }

  @override
  String errorSavingProfile(Object error) {
    return 'เกิดข้อผิดพลาดในการบันทึก: $error';
  }

  @override
  String get accountProfile => 'บัญชีของฉัน';

  @override
  String get displayName => 'ชื่อที่แสดง';

  @override
  String get displayNameDesc => 'ชื่อที่จะแสดงในแอป';

  @override
  String get email => 'อีเมล';

  @override
  String get cannotBeChanged => 'ไม่สามารถเปลี่ยนได้';

  @override
  String get verified => 'ยืนยันแล้ว';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get changePasswordDesc => 'เปลี่ยนรหัสผ่านของคุณ';

  @override
  String get change => 'เปลี่ยน';

  @override
  String get currentPassword => 'รหัสผ่านปัจจุบัน';

  @override
  String get newPassword => 'รหัสผ่านใหม่';

  @override
  String get confirmNewPassword => 'ยืนยันรหัสผ่านใหม่';

  @override
  String get save => 'บันทึก';

  @override
  String get notSet => 'ยังไม่ได้ตั้งชื่อ';

  @override
  String get enterDisplayName => 'กรุณากรอกชื่อที่แสดง';

  @override
  String get nameLengthError => 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';

  @override
  String displayNameChanged(Object name) {
    return 'ชื่อที่แสดงของคุณเปลี่ยนเป็น \"$name\".';
  }

  @override
  String get updateSuccess => 'อัปเดตเรียบร้อยแล้ว';

  @override
  String get updateError => 'เกิดข้อผิดพลาด กรุณาลองใหม่';

  @override
  String get enterCurrentPassword => 'กรุณากรอกรหัสผ่านปัจจุบัน';

  @override
  String get passwordLengthError => 'รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร';

  @override
  String get passwordMismatchError => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get securityAlert => 'แจ้งเตือนความปลอดภัย';

  @override
  String get passwordChangedSuccess => 'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว';

  @override
  String get passwordChangeSuccessMsg => 'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว';

  @override
  String get currentPasswordIncorrect => 'รหัสผ่านปัจจุบันไม่ถูกต้อง';

  @override
  String get parentAccount => 'บัญชีผู้ปกครอง';

  @override
  String get edit => 'แก้ไข';

  @override
  String get childAddedTitle => 'เพิ่มบุตรหลานแล้ว';

  @override
  String childAddedMessage(Object name) {
    return 'เพิ่ม $name เข้ามาในครอบครัวของคุณแล้ว';
  }

  @override
  String get profileUpdatedTitle => 'อัปเดตโปรไฟล์แล้ว';

  @override
  String profileUpdatedMessage(Object name) {
    return 'โปรไฟล์ของ $name ได้รับการอัปเดตเรียบร้อยแล้ว';
  }

  @override
  String get online => 'ออนไลน์';

  @override
  String get offline => 'ออฟไลน์';
}
