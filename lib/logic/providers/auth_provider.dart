import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/child_model.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/notification_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  // Initialize auth state
  List<ChildModel> _children = [];
  ChildModel? _currentChild;
  StreamSubscription<DocumentSnapshot>? _currentChildSubscription;

  List<ChildModel> get children => _children;
  ChildModel? get currentChild => _currentChild;

  Future<void> init() async {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _userModel = await _authService.getUserData(user.uid);
        if (_userModel != null) {
          await fetchChildren();
        }
      } else {
        _userModel = null;
        _children = [];
      }
      notifyListeners();
    });
  }

  Future<void> fetchChildren() async {
    if (_userModel != null) {
      _children = await _authService.getChildren(_userModel!.uid);
      notifyListeners();
    }
  }

  Future<bool> registerChild(String name, int age, String avatar) async {
    if (_userModel == null) return false;
    try {
      _isLoading = true;
      notifyListeners();
      final child = await _authService.registerChild(
        _userModel!.uid,
        name,
        age,
        avatar,
      );
      if (child != null) {
        _children.add(child);
        _currentChild = child;
        return true;
      }
      return false;
    } catch (e) {
      // Error registering child
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      _userModel = await _authService.signIn(email, password);
      if (_userModel != null) {
        await fetchChildren();
      }
      return true;
    } catch (e) {
      // Error signing in
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();
      _userModel = await _authService.register(email, password, name);
      return true;
    } catch (e) {
      // Error registering
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      _userModel = await _authService.signInWithGoogle();
      if (_userModel != null) {
        await fetchChildren();
      }
      return _userModel != null;
    } catch (e) {
      // Error signing in with Google
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<String?> generatePin() async {
    if (_userModel == null) return null;
    try {
      _isLoading = true;
      notifyListeners();
      final pin = await _authService.generatePin(_userModel!.uid);
      if (pin != null) {
        // Update local user model with new PIN
        _userModel = UserModel(
          uid: _userModel!.uid,
          email: _userModel!.email,
          displayName: _userModel!.displayName,
          role: _userModel!.role,
          childIds: _userModel!.childIds,
          pin: pin,
        );

        // Notify user about PIN change
        await NotificationService().addNotification(
          _userModel!.uid,
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'PIN Updated',
            message: 'Your connection PIN has been regenerated.',
            timestamp: DateTime.now(),
            type: 'system',
            category: 'system',
            iconName: 'vpn_key_rounded',
            colorValue: Colors.orange.value,
          ),
        );
      }
      return pin;
    } catch (e) {
      // Error generating PIN
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectChild(ChildModel child) async {
    _currentChild = child;
    notifyListeners();

    // Cancel previous subscription if exists
    await _currentChildSubscription?.cancel();

    // Subscribe to realtime updates for this child
    if (_userModel != null) {
      _currentChildSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_userModel!.uid)
          .collection('children')
          .doc(child.id)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              _currentChild = ChildModel.fromMap(snapshot.data()!, snapshot.id);
              notifyListeners();
            }
          });

      await _authService.updateChildStatus(_userModel!.uid, child.id, true);
    }
  }

  Future<void> logoutChild() async {
    // Cancel realtime subscription
    await _currentChildSubscription?.cancel();
    _currentChildSubscription = null;

    if (_userModel != null && _currentChild != null) {
      await _authService.updateChildStatus(
        _userModel!.uid,
        _currentChild!.id,
        false,
      );
    }
    _currentChild = null;
    notifyListeners();
  }

  Future<bool> childLogin(String pin) async {
    try {
      _isLoading = true;
      notifyListeners();
      final parentUser = await _authService.verifyPin(pin);
      if (parentUser != null) {
        // For child login, we might want to store the parent's info
        // or a specific child session. For now, we'll store the parent user
        // but we should probably handle this differently in a real app
        // (e.g., separate ChildModel).
        // Assuming the requirement is just to link/login.
        _userModel = parentUser;
        await fetchChildren(); // Fetch children for the parent
        return true;
      }
      return false;
    } catch (e) {
      // Error during child login
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChild(String childId) async {
    if (_userModel == null) return false;
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.deleteChild(_userModel!.uid, childId);
      _children.removeWhere((child) => child.id == childId);
      return true;
    } catch (e) {
      // Error deleting child
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDisplayName(String newName) async {
    if (_userModel == null) return false;
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.updateDisplayName(_userModel!.uid, newName);
      // Update local user model
      _userModel = UserModel(
        uid: _userModel!.uid,
        email: _userModel!.email,
        displayName: newName,
        role: _userModel!.role,
        childIds: _userModel!.childIds,
        pin: _userModel!.pin,
      );
      return true;
    } catch (e) {
      // Error updating display name
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_userModel == null) return false;
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.updatePassword(currentPassword, newPassword);
      return true;
    } catch (e) {
      // Error updating password
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
