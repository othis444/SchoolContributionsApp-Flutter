// lib/presentation/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide AuthProvider; // إخفاء AuthProvider من Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // لتهيئة StudentRepository
import 'package:school_contributions_app/data/datasources/auth_datasource.dart';
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/repositories/auth_repository.dart';
import 'package:school_contributions_app/data/repositories/student_repository.dart';
import 'package:school_contributions_app/data/models/user.dart'; // استيراد UserRole

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _authRepository;
  late final StudentRepository _studentRepository;

  User? _currentUser;
  UserRole? _userRole;
  bool _isLoading = true; // حالة تحميل المصادقة الأولية

  AuthProvider() {
    _authRepository = AuthRepository(AuthDataSource(FirebaseAuth.instance));
    _studentRepository = StudentRepository(
      StudentDataSource(FirebaseFirestore.instance),
      FirebaseFirestore.instance,
    );

    // الاستماع لتغيرات حالة المصادقة
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _currentUser = user;
      if (user != null) {
        // إذا كان المستخدم مسجل الدخول، قم بجلب دوره من Firestore
        _userRole = await _studentRepository.getUserRole(user.uid);
      } else {
        _userRole = null;
      }
      _isLoading = false; // انتهى التحميل الأولي
      notifyListeners(); // إعلام المستمعين بالتغيير
    });
  }

  // Getter لتحديد ما إذا كان المستخدم مسجل الدخول
  bool get isLoggedIn => _currentUser != null;

  // Getter للحصول على دور المستخدم
  UserRole? get userRole => _userRole;

  // Getter للحصول على المستخدم الحالي (Firebase User)
  User? get currentUser => _currentUser;

  // Getter لحالة التحميل الأولية للمصادقة
  bool get isLoading => _isLoading;

  // دالة لتسجيل الدخول
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.signIn(email, password);
      // حالة المصادقة ستتغير تلقائياً عبر المستمع في الـ constructor
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // دالة لتسجيل الخروج
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.signOut();
    } catch (e) {
      debugPrint('Logout failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
