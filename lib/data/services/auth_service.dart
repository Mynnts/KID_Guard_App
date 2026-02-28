// ==================== นำเข้า Packages ====================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';
import '../../core/utils/security_logger.dart';

// ==================== AuthService ====================
/// บริการจัดการ Authentication และข้อมูลผู้ใช้
///
/// ฟังก์ชันหลัก:
/// - signIn(), register() - ล็อกอิน/ลงทะเบียนด้วย email
/// - signInWithGoogle() - ล็อกอินด้วย Google
/// - signOut() - ออกจากระบบ
/// - generatePin() - สร้าง PIN 6 หลักสำหรับเชื่อมต่อกับลูก
/// - verifyPin() - ตรวจสอบ PIN ของผู้ปกครอง
/// - registerChild() - ลงทะเบียนลูกใหม่
/// - getChildren() - ดึงรายการลูกทั้งหมด
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream สถานะ authentication (ล็อกอิน/ออกจากระบบ)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== ล็อกอินด้วย Email ====================
  /// ล็อกอินด้วย email และ password
  /// @return UserModel ถ้าสำเร็จ, null ถ้าล้มเหลว
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await SecurityLogger.logAuth('email_sign_in', true, userId: user.uid);
        return await getUserData(user.uid);
      }
      return null;
    } catch (e) {
      await SecurityLogger.logAuth('email_sign_in', false);
      await SecurityLogger.error(
        'Sign in failed',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  // ==================== ลงทะเบียนด้วย Email ====================
  /// สร้างบัญชีใหม่ด้วย email และ password
  /// สร้าง document ใน Firestore ที่ /users/{uid}
  Future<UserModel?> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        // สร้าง document ใน Firestore
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: name,
          role: 'parent', // ผู้ลงทะเบียนใหม่เป็น parent เสมอ
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== ล็อกอินด้วย Google ====================
  /// ล็อกอินด้วย Google Account
  /// ถ้าไม่มี document ใน Firestore จะสร้างให้อัตโนมัติ
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        await SecurityLogger.logAuth('google_sign_in', false);
        return null; // ผู้ใช้ยกเลิก
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        await SecurityLogger.logAuth('google_sign_in', true, userId: user.uid);
        // ตรวจสอบว่ามี document ใน Firestore หรือยัง
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists) {
          // สร้าง document ใหม่ถ้าเป็นผู้ใช้ใหม่
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'Parent',
            role: 'parent',
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
          await SecurityLogger.info(
            'New user registered via Google',
            data: {'uid': user.uid},
          );
          return newUser;
        } else {
          return UserModel.fromMap(
            doc.data() as Map<String, dynamic>,
            user.uid,
          );
        }
      }
      return null;
    } catch (e) {
      await SecurityLogger.logAuth('google_sign_in', false);
      await SecurityLogger.error(
        'Google sign in failed',
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  // ==================== ออกจากระบบ ====================
  /// ออกจากระบบทั้ง Firebase Auth และ Google Sign-In
  Future<void> signOut() async {
    final userId = _auth.currentUser?.uid;
    await SecurityLogger.logAuth('sign_out', true, userId: userId);
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ==================== ดึงข้อมูลผู้ใช้ ====================
  /// ดึงข้อมูลผู้ใช้จาก Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      // Error fetching user data
      return null;
    }
  }

  // ==================== สร้าง PIN ====================
  /// สร้าง PIN 6 หลักสำหรับผู้ปกครอง
  /// - ถ้ามี PIN อยู่แล้วจะคืนค่าเดิม
  /// - ตรวจสอบความไม่ซ้ำผ่าน /pins/{pin} collection
  /// - บันทึกลง Firestore ทั้ง users/{uid} และ pins/{pin}
  Future<String?> generatePin(String uid) async {
    try {
      // ตรวจสอบว่ามี PIN อยู่แล้วหรือไม่
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['pin'] != null && data['pin'].toString().isNotEmpty) {
          // ตรวจว่า pins collection มีข้อมูลด้วย (migration safety)
          final existingPin = data['pin'].toString();
          final pinDoc = await _firestore
              .collection('pins')
              .doc(existingPin)
              .get();
          if (!pinDoc.exists) {
            await _firestore.collection('pins').doc(existingPin).set({
              'parentUid': uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          return existingPin;
        }
      }

      String pin = '';
      bool isUnique = false;
      int attempts = 0;

      while (!isUnique && attempts < 10) {
        // Generate 6-digit PIN
        pin = (100000 + DateTime.now().microsecondsSinceEpoch % 900000)
            .toString();

        // Check uniqueness ผ่าน pins collection (doc read แทน query)
        final pinDoc = await _firestore.collection('pins').doc(pin).get();

        if (!pinDoc.exists) {
          isUnique = true;
        }
        attempts++;
      }

      if (isUnique) {
        // เขียนทั้ง 2 ที่พร้อมกัน (batch)
        final batch = _firestore.batch();
        batch.update(_firestore.collection('users').doc(uid), {'pin': pin});
        batch.set(_firestore.collection('pins').doc(pin), {
          'parentUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        return pin;
      } else {
        throw Exception('Failed to generate unique PIN');
      }
    } catch (e) {
      // Error generating PIN
      return null;
    }
  }

  // ==================== ลงทะเบียนลูก ====================
  /// ลงทะเบียนลูกใหม่ภายใต้ผู้ปกครอง
  /// สร้าง document ที่ /users/{parentUid}/children/{childId}
  Future<ChildModel?> registerChild(
    String parentUid,
    String name,
    int age,
    String avatar,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc();
      final child = ChildModel(
        id: docRef.id,
        parentId: parentUid,
        name: name,
        age: age,
        avatar: avatar,
      );
      await docRef.set(child.toMap());
      return child;
    } catch (e) {
      // Error registering child
      return null;
    }
  }

  // ==================== ดึงรายชื่อลูก ====================
  /// ดึงรายชื่อลูกทั้งหมดของผู้ปกครอง
  Future<List<ChildModel>> getChildren(String parentUid) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .get();
      return query.docs
          .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Error fetching children
      return [];
    }
  }

  // ==================== ตรวจสอบ PIN ====================
  /// ดึง parentUid จาก PIN (อ่านเฉพาะ pins/{pin} — ไม่ต้อง auth)
  Future<String?> getParentUidFromPin(String pin) async {
    try {
      final pinDoc = await _firestore.collection('pins').doc(pin).get();
      if (pinDoc.exists) {
        return pinDoc.data()?['parentUid'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ตรวจสอบ PIN สำหรับการล็อกอินของเด็ก
  /// อ่านจาก /pins/{pin} แทน query users ทั้งหมด
  /// @return UserModel ของผู้ปกครองถ้า PIN ถูกต้อง
  Future<UserModel?> verifyPin(String pin) async {
    try {
      // อ่านจาก pins collection โดยตรง (single doc read)
      final pinDoc = await _firestore.collection('pins').doc(pin).get();

      if (pinDoc.exists) {
        final parentUid = pinDoc.data()?['parentUid'] as String?;
        if (parentUid != null) {
          final userDoc = await _firestore
              .collection('users')
              .doc(parentUid)
              .get();
          if (userDoc.exists) {
            return UserModel.fromMap(
              userDoc.data() as Map<String, dynamic>,
              userDoc.id,
            );
          }
        }
      }
      return null;
    } catch (e) {
      // Error verifying PIN
      return null;
    }
  }

  // ==================== ลบลูก ====================
  /// ลบข้อมูลลูกออกจากระบบ
  Future<void> deleteChild(String parentUid, String childId) async {
    try {
      await _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .delete();
    } catch (e) {
      // Error deleting child
      rethrow;
    }
  }

  // ==================== อัปเดตสถานะลูก ====================
  /// อัปเดตสถานะออนไลน์/ออฟไลน์ และ lastActive
  Future<void> updateChildStatus(
    String parentUid,
    String childId,
    bool isOnline,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .update({
            'isOnline': isOnline,
            'lastActive': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Error updating child status
    }
  }

  // ==================== อัปเดตชื่อผู้ใช้ ====================
  /// อัปเดตชื่อที่แสดงทั้งใน Firestore และ Firebase Auth
  Future<void> updateDisplayName(String uid, String newName) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'displayName': newName,
      });
      // อัปเดตใน Firebase Auth ด้วย
      await _auth.currentUser?.updateDisplayName(newName);
    } catch (e) {
      // Error updating display name
      rethrow;
    }
  }

  // ==================== เปลี่ยนรหัสผ่าน ====================
  /// เปลี่ยนรหัสผ่าน - ต้อง re-authenticate ก่อน
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated');
      }

      // ต้อง re-authenticate ด้วยรหัสผ่านปัจจุบันก่อน
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // เปลี่ยนรหัสผ่านใหม่
      await user.updatePassword(newPassword);
    } catch (e) {
      // Error updating password
      rethrow;
    }
  }
}
