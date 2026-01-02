import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';
import '../../core/utils/security_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Email & Password
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

  // Register with Email & Password
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
        // Create user doc in Firestore
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: name,
          role: 'parent', // Default to parent for now
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        await SecurityLogger.logAuth('google_sign_in', false);
        return null; // User canceled
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
        // Check if user exists, if not create
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists) {
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

  // Sign Out
  Future<void> signOut() async {
    final userId = _auth.currentUser?.uid;
    await SecurityLogger.logAuth('sign_out', true, userId: userId);
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get User Data from Firestore
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
      print(e.toString());
      return null;
    }
  }

  // Generate Unique PIN for Parent (Persistent)
  Future<String?> generatePin(String uid) async {
    try {
      // Check if user already has a PIN
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['pin'] != null && data['pin'].toString().isNotEmpty) {
          return data['pin'].toString(); // Ensure it's returned as a String
        }
      }

      String pin = '';
      bool isUnique = false;
      int attempts = 0;

      while (!isUnique && attempts < 10) {
        // Generate 6-digit PIN
        pin = (100000 + DateTime.now().microsecondsSinceEpoch % 900000)
            .toString();

        // Check uniqueness
        final query = await _firestore
            .collection('users')
            .where('pin', isEqualTo: pin)
            .get();

        if (query.docs.isEmpty) {
          isUnique = true;
        }
        attempts++;
      }

      if (isUnique) {
        await _firestore.collection('users').doc(uid).update({'pin': pin});
        return pin;
      } else {
        throw Exception('Failed to generate unique PIN');
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Register Child
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
      print(e.toString());
      return null;
    }
  }

  // Get Children
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
      print(e.toString());
      return [];
    }
  }

  // Verify PIN for Child Login
  Future<UserModel?> verifyPin(String pin) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('pin', isEqualTo: pin)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return UserModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Delete Child
  Future<void> deleteChild(String parentUid, String childId) async {
    try {
      await _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .delete();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Update Child Status (Online/Offline)
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
      print(e.toString());
    }
  }

  // Update Display Name
  Future<void> updateDisplayName(String uid, String newName) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'displayName': newName,
      });
      // Also update Firebase Auth display name
      await _auth.currentUser?.updateDisplayName(newName);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Update Password
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }
}
