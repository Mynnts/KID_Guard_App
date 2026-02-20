import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isInitialized = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Initialize auth state
  List<ChildModel> _children = [];
  ChildModel? _currentChild;
  StreamSubscription<DocumentSnapshot>? _currentChildSubscription;

  List<ChildModel> get children => _children;
  ChildModel? get currentChild => _currentChild;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Listen to Firebase Auth changes
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _userModel = await _authService.getUserData(user.uid);
        if (_userModel != null) {
          await fetchChildren();
        }
      } else {
        // Only clear if we're not in child mode (handled by PIN)
        final prefs = await SharedPreferences.getInstance();
        final savedPin = prefs.getString('saved_child_pin');
        if (savedPin == null) {
          _userModel = null;
          _children = [];
        }
      }
      notifyListeners();
    });

    try {
      _isLoading = true;
      // 2. Check for child session
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('saved_child_pin');
      final savedChildId = prefs.getString('saved_child_id');

      if (savedPin != null) {
        final success = await childLogin(savedPin, isAutoLogin: true);
        if (success && savedChildId != null && _children.isNotEmpty) {
          final childToSelect = _children.any((c) => c.id == savedChildId)
              ? _children.firstWhere((c) => c.id == savedChildId)
              : null;
          if (childToSelect != null) {
            await selectChild(childToSelect);
          }
        }
      }
    } catch (e) {
      print('AuthProvider init error: $e');
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
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
      print(e);
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
        // Clear child session if parent signs in
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_child_pin');
        await prefs.remove('saved_child_id');
      }
      return true;
    } catch (e) {
      print(e);
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
      print(e);
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
        // Clear child session if parent signs in
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_child_pin');
        await prefs.remove('saved_child_id');
      }
      return _userModel != null;
    } catch (e) {
      print(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_child_pin');
    await prefs.remove('saved_child_id');
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
            iconName: 'vpn_key_rounded',
            colorValue: Colors.orange.value,
          ),
        );
      }
      return pin;
    } catch (e) {
      print(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectChild(ChildModel child) async {
    _currentChild = child;
    notifyListeners();

    // Save session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_child_id', child.id);

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

    // Clear saved child session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_child_pin');
    await prefs.remove('saved_child_id');

    _currentChild = null;
    notifyListeners();
  }

  Future<bool> childLogin(String pin, {bool isAutoLogin = false}) async {
    try {
      if (!isAutoLogin) {
        _isLoading = true;
        notifyListeners();
      }

      final parentUser = await _authService.verifyPin(pin);
      if (parentUser != null) {
        _userModel = parentUser;
        await fetchChildren();

        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_child_pin', pin);

        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    } finally {
      if (!isAutoLogin) {
        _isLoading = false;
        notifyListeners();
      }
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
      print(e);
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
      print(e);
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
      print(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
