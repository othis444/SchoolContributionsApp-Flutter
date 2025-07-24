// lib/presentation/providers/class_lead_provider.dart

import 'package:flutter/material.dart';
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/repositories/student_repository.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/data/models/student_monthly_payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // لتهيئة StudentRepository
import 'package:firebase_auth/firebase_auth.dart'; // للحصول على UID المعلم

class ClassLeadProvider extends ChangeNotifier {
  late final StudentRepository _studentRepository;
  List<Student> _classStudents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentClassLeadId; // UID الخاص بالمعلم الحالي
  String _selectedMonthKey = ''; // 'YYYY-MM'

  ClassLeadProvider() {
    _studentRepository = StudentRepository(
      StudentDataSource(FirebaseFirestore.instance),
      FirebaseFirestore.instance,
    );
    _initializeMonthKey();
    _listenToAuthChanges(); // الاستماع لتغيرات المصادقة للحصول على UID
  }

  List<Student> get classStudents => _classStudents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedMonthKey => _selectedMonthKey;

  void _initializeMonthKey() {
    final now = DateTime.now();
    _selectedMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _currentClassLeadId = user.uid;
        _listenToClassStudents(); // ابدأ الاستماع للطلاب بمجرد توفر UID
      } else {
        _currentClassLeadId = null;
        _classStudents = [];
        notifyListeners();
      }
    });
  }

  void _listenToClassStudents() {
    if (_currentClassLeadId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _studentRepository
        .getStudentsForClassLead(_currentClassLeadId!)
        .listen(
          (students) {
            _classStudents = students;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'فشل تحميل بيانات الطلاب: $error';
            _isLoading = false;
            notifyListeners();
            print('Error listening to class students: $error');
          },
        );
  }

  void setSelectedMonth(DateTime date) {
    _selectedMonthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  // تحديث حالة الدفع لطالب معين (مؤقتاً في الذاكرة)
  void updateStudentPaymentStatusLocally(String studentId, bool isPaid) {
    final index = _classStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final student = _classStudents[index];
      final currentPayments = Map<String, StudentMonthlyPayment>.from(
        student.monthlyPayments,
      );
      currentPayments[_selectedMonthKey] = StudentMonthlyPayment(
        isPaid: isPaid,
        amount: currentPayments[_selectedMonthKey]?.amount ?? 1000.0,
        notes: currentPayments[_selectedMonthKey]?.notes,
      );
      _classStudents[index] = student.copyWith(
        monthlyPayments: currentPayments,
      );
      notifyListeners();
    }
  }

  // تحديث مبلغ الدفع لطالب معين (مؤقتاً في الذاكرة)
  void updateStudentPaymentAmountLocally(String studentId, double amount) {
    final index = _classStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final student = _classStudents[index];
      final currentPayments = Map<String, StudentMonthlyPayment>.from(
        student.monthlyPayments,
      );
      currentPayments[_selectedMonthKey] = StudentMonthlyPayment(
        isPaid: currentPayments[_selectedMonthKey]?.isPaid ?? false,
        amount: amount,
        notes: currentPayments[_selectedMonthKey]?.notes,
      );
      _classStudents[index] = student.copyWith(
        monthlyPayments: currentPayments,
      );
      notifyListeners();
    }
  }

  // تحديث ملاحظات الدفع لطالب معين (مؤقتاً في الذاكرة)
  void updateStudentPaymentNotesLocally(String studentId, String notes) {
    final index = _classStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final student = _classStudents[index];
      final currentPayments = Map<String, StudentMonthlyPayment>.from(
        student.monthlyPayments,
      );
      currentPayments[_selectedMonthKey] = StudentMonthlyPayment(
        isPaid: currentPayments[_selectedMonthKey]?.isPaid ?? false,
        amount: currentPayments[_selectedMonthKey]?.amount ?? 1000.0,
        notes: notes,
      );
      _classStudents[index] = student.copyWith(
        monthlyPayments: currentPayments,
      );
      notifyListeners();
    }
  }

  // حفظ جميع التغييرات المعلقة إلى Firebase
  Future<void> saveAllChanges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // هنا يمكنك تمرير قائمة الطلاب التي تم تعديلها فقط
      // أو ببساطة تمرير القائمة الحالية كلها لتحديث Firestore
      await _studentRepository.updateMultipleStudentPayments(
        _classStudents,
        _selectedMonthKey,
      );
      _errorMessage = null; // مسح أي رسائل خطأ سابقة عند النجاح
    } catch (e) {
      _errorMessage = 'فشل حفظ التغييرات: $e';
      print('Error saving changes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
