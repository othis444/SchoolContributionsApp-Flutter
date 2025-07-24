// lib/data/datasources/auth_datasource.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthDataSource(this._firebaseAuth);

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // يمكنك هنا تحويل أخطاء Firebase إلى أخطاء أكثر وضوحاً للتطبيق
      if (e.code == 'user-not-found') {
        throw Exception('لا يوجد مستخدم بهذا البريد الإلكتروني.');
      } else if (e.code == 'wrong-password') {
        throw Exception('كلمة المرور خاطئة.');
      } else if (e.code == 'invalid-email') {
        throw Exception('صيغة البريد الإلكتروني غير صحيحة.');
      }
      throw Exception('فشل تسجيل الدخول: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع أثناء تسجيل الدخول: $e');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
