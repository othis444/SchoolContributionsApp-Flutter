// lib/data/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart'
    hide AuthProvider; // إخفاء AuthProvider من Firebase
import 'package:school_contributions_app/data/datasources/auth_datasource.dart';

class AuthRepository {
  final AuthDataSource _authDataSource;

  AuthRepository(this._authDataSource);

  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _authDataSource.signInWithEmailAndPassword(
        email,
        password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow; // أعد رمي الخطأ ليتم التعامل معه في طبقة الـ Provider/UI
    }
  }

  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  User? getCurrentUser() {
    return _authDataSource.getCurrentUser();
  }
}
