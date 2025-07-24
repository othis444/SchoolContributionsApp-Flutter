// lib/presentation/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_contributions_app/data/datasources/auth_datasource.dart';
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/repositories/auth_repository.dart';
import 'package:school_contributions_app/data/repositories/student_repository.dart';
import 'package:school_contributions_app/data/models/user.dart';
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _authRepository;
  late final StudentRepository _studentRepository;

  User? _currentUser;
  UserRole? _userRole;
  bool _isLoading = true; // حالة تحميل شاملة للمصادقة وجلب الدور

  AuthProvider() {
    _authRepository = AuthRepository(AuthDataSource(FirebaseAuth.instance));
    _studentRepository = StudentRepository(
      StudentDataSource(FirebaseFirestore.instance),
      FirebaseFirestore.instance,
    );

    // الاستماع لتغيرات حالة المصادقة
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _currentUser = user;
      _isLoading = true; // ابدأ التحميل عند كل تغيير في حالة المصادقة
      notifyListeners(); // أبلغ المستمعين بأن التحميل قد بدأ

      if (user != null) {
        debugPrint(
          'AuthProvider: authStateChanges detected user: ${user.email}. Attempting to fetch role...',
        ); // <--- Debug
        try {
          // إذا كان المستخدم مسجل الدخول، قم بجلب دوره من Firestore بشكل متزامن
          _userRole = await _studentRepository.getUserRole(user.uid);
          debugPrint(
            'AuthProvider: Successfully fetched role: ${_userRole?.toString().split('.').last} for user: ${user.email}',
          ); // <--- Debug
        } catch (e) {
          debugPrint(
            'AuthProvider: Error fetching role for user ${user.email}: $e',
          ); // <--- Debug
          _userRole = null; // تعيين الدور إلى null في حالة الفشل
        }
      } else {
        _userRole = null;
        debugPrint(
          'AuthProvider: authStateChanges detected no user.',
        ); // <--- Debug
      }
      _isLoading = false; // انتهى التحميل بعد تحديد الدور (أو فشل جلبه)
      notifyListeners(); // أبلغ المستمعين بالحالة النهائية (المستخدم والدور)
      debugPrint(
        'AuthProvider: Loading complete. IsLoggedIn: $isLoggedIn, UserRole: ${_userRole?.toString().split('.').last}',
      ); // <--- Debug
    });
  }

  bool get isLoggedIn => _currentUser != null;
  UserRole? get userRole => _userRole;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> signIn(String email, String password) async {
    _isLoading = true; // ابدأ التحميل عند محاولة تسجيل الدخول
    notifyListeners();
    debugPrint('AuthProvider: Attempting sign-in for $email...'); // <--- Debug
    try {
      await _authRepository.signIn(email, password);
      // مستمع authStateChanges سيقوم بتحديث _isLoading والدور بعد ذلك
      debugPrint(
        'AuthProvider: Sign-in attempt successful for $email (Auth part).',
      ); // <--- Debug
    } catch (e) {
      debugPrint('AuthProvider: Login failed for $email: $e'); // <--- Debug
      _isLoading = false; // في حالة الفشل، أوقف التحميل
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _isLoading = true; // ابدأ التحميل عند محاولة تسجيل الخروج
    notifyListeners();
    debugPrint('AuthProvider: Attempting sign-out...'); // <--- Debug
    try {
      await _authRepository.signOut();
      debugPrint('AuthProvider: User signed out.'); // <--- Debug
    } catch (e) {
      debugPrint('AuthProvider: Logout failed: $e'); // <--- Debug
      rethrow;
    } finally {
      _isLoading = false; // أوقف التحميل بعد تسجيل الخروج
      notifyListeners();
    }
  }
}
