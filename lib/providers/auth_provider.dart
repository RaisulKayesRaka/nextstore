import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == 'admin';

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<String?> login(String email, String password) async {
    setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      return e.message ?? "Login failed";
    } catch (e) {
      setLoading(false);
      return "An error occurred";
    }
  }

  Future<String?> signup(String name, String email, String password) async {
    setLoading(true);
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        UserModel newUser = UserModel(
          id: cred.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(newUser.toMap());
        _currentUser = newUser;
      }
      setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      return e.message ?? "Signup failed";
    } catch (e) {
      setLoading(false);
      return "An error occurred";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (_currentUser == null) return "Not logged in";
    setLoading(true);
    try {
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'name': name,
        'phone': phone,
      });
      _currentUser = _currentUser!.copyWith(name: name, phone: phone);
      setLoading(false);
      return null;
    } catch (e) {
      setLoading(false);
      return "Failed to update profile";
    }
  }

  Future<String?> forgotPassword(String email) async {
    setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      return e.message ?? "Failed to send reset email";
    } catch (e) {
      setLoading(false);
      return "An error occurred";
    }
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    if (_auth.currentUser == null || _auth.currentUser!.email == null) {
      return "User not logged in";
    }
    setLoading(true);
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: oldPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      await _auth.currentUser!.updatePassword(newPassword);
      setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      return e.message ?? "Failed to change password";
    } catch (e) {
      setLoading(false);
      return "An error occurred";
    }
  }
}
