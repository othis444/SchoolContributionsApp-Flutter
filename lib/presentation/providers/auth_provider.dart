// lib/presentation/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_contributions_app/data/datasources/auth_datasource.dart';
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/repositories/auth_repository.dart';
import 'package:school_contributions_app/data/repositories/student_repository.dart';
import 'package:school_contributions_app/data/models/user.dart'; // <--- استيراد AppUser و UserRole
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _authRepository;
  late final StudentRepository _studentRepository;

  User? _currentUser;
  AppUser? _appUser; // <--- لتخزين كائن AppUser الكامل
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
      _isLoading = true; // <--- ابدأ التحميل عند كل تغيير في حالة المصادقة
      notifyListeners(); // أبلغ المستمعين بأن التحميل قد بدأ

      if (user != null) {
        debugPrint(
          'AuthProvider: authStateChanges detected user: ${user.email}. Attempting to fetch AppUser data...',
        );
        try {
          _appUser = await _studentRepository.getUserData(
            user.uid,
          ); // <--- جلب AppUser
          if (_appUser != null) {
            debugPrint(
              'AuthProvider: Successfully fetched AppUser for user: ${user.email}, Role: ${_appUser!.role.toString().split('.').last}, CanEditPayments: ${_appUser!.canEditPayments}, CanViewStudents: ${_appUser!.canViewStudents}',
            );
          } else {
            debugPrint(
              'AuthProvider: AppUser data not found for user: ${user.email}. Setting AppUser to null.',
            );
          }
        } catch (e) {
          debugPrint(
            'AuthProvider: Error fetching AppUser for user ${user.email}: $e',
          );
          _appUser = null; // تعيين AppUser إلى null في حالة الفشل
        }
      } else {
        _appUser = null; // مسح AppUser عند تسجيل الخروج
        debugPrint('AuthProvider: authStateChanges detected no user.');
      }
      _isLoading = false; // <--- انتهى التحميل بعد تحديد الدور (أو فشل جلبه)
      notifyListeners(); // أبلغ المستمعين بالحالة النهائية (المستخدم والدور)
      debugPrint(
        'AuthProvider: Loading complete. IsLoggedIn: $isLoggedIn, UserRole: ${userRole?.toString().split('.').last}',
      );
    });
  }

  bool get isLoggedIn => _currentUser != null;
  UserRole? get userRole => _appUser?.role; // <--- جلب الدور مباشرة من _appUser
  User? get currentUser => _currentUser;
  AppUser? get appUser => _appUser; // Getter لكائن AppUser الكامل
  bool get isLoading => _isLoading;

  Future<void> signIn(String email, String password) async {
    _isLoading = true; // ابدأ التحميل عند محاولة تسجيل الدخول
    notifyListeners();
    debugPrint('AuthProvider: Attempting sign-in for $email...');
    try {
      await _authRepository.signIn(email, password);
      // مستمع authStateChanges سيقوم بتحديث _isLoading والدور بعد ذلك
      debugPrint(
        'AuthProvider: Sign-in attempt successful for $email (Auth part).',
      );
    } catch (e) {
      debugPrint('AuthProvider: Login failed for $email: $e');
      _isLoading = false; // في حالة الفشل، أوقف التحميل
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _isLoading = true; // ابدأ التحميل عند محاولة تسجيل الخروج
    notifyListeners();
    debugPrint('AuthProvider: Attempting sign-out...');
    try {
      await _authRepository.signOut();
      debugPrint('AuthProvider: User signed out.');
    } catch (e) {
      debugPrint('AuthProvider: Logout failed: $e');
      rethrow;
    } finally {
      _isLoading = false; // أوقف التحميل بعد تسجيل الخروج
      notifyListeners();
    }
  }
}
