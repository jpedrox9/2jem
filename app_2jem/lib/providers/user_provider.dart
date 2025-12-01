import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserRole?> validateLogin(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(cred.user!.uid).get();

      if (!userDoc.exists) {
        return UserRole.technician;
      }

      final data = userDoc.data() as Map<String, dynamic>;

      // Check if account is disabled
      if (data['isActive'] == false) {
        await _auth.signOut();
        throw Exception('Login failed');
      }

      String roleStr = data['role'] ?? 'technician';
      return roleStr == 'admin' ? UserRole.admin : UserRole.technician;
    } on FirebaseAuthException catch (e) {
      // We log the real error to console for debugging, but throw generic to UI
      debugPrint("Auth Error: ${e.code}");
      throw Exception('Login failed');
    } catch (e) {
      // Catch any other errors (like the isActive check above)
      throw Exception('Login failed');
    }
  }

  Future<void> addUser(String email, String password, UserRole role) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role.name,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> toggleUserStatus(String uid, bool newStatus) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': newStatus,
    });
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
