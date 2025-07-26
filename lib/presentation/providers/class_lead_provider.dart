// lib/presentation/providers/class_lead_provider.dart

import 'package:flutter/material.dart';
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/repositories/student_repository.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/data/models/student_monthly_payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
import 'package:school_contributions_app/data/models/user.dart'; // <--- استيراد AppUser و UserRole

class ClassLeadProvider extends ChangeNotifier {
  late final StudentRepository _studentRepository;
  List<Student> _classStudents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
  String? _currentClassFilter;

  late final BuildContext _context;

  final Map<String, StudentMonthlyPayment> _localPaymentChanges = {};

  ClassLeadProvider({required BuildContext context}) {
    _context = context;
    _studentRepository = StudentRepository(
      StudentDataSource(FirebaseFirestore.instance),
      FirebaseFirestore.instance,
    );
  }

  List<Student> get classStudents => _classStudents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedMonthKey => _selectedMonthKey;

  // دالة جالبة لـ localPaymentChanges
  Map<String, StudentMonthlyPayment> get localPaymentChanges =>
      _localPaymentChanges;

  // <--- جديد: دالة جالبة للتحقق مما إذا كان جميع الطلاب قد دفعوا
  bool get areAllStudentsPaid {
    if (_localPaymentChanges.isEmpty) return false;
    return _localPaymentChanges.values.every((payment) => payment.isPaid);
  }
  // نهاية إضافة areAllStudentsPaid --->

  void setSelectedMonth(DateTime date) {
    final newMonthKey = DateFormat('yyyy-MM').format(date);
    if (_selectedMonthKey != newMonthKey) {
      _selectedMonthKey = newMonthKey;
      if (_currentClassFilter != null) {
        // يمكن أن تحتاج هذه الدالة إلى استدعاء fetchStudentsForClassAndMonth
        // ولكن يجب أن يتم ذلك بعد التأكد من أن context لا يزال صالحاً.
      }
      notifyListeners();
    }
  }

  Future<void> fetchStudentsForClassAndMonth(
    String className,
    String monthKey,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _classStudents = [];
    _localPaymentChanges.clear();

    _currentClassFilter = className;
    _selectedMonthKey = monthKey;

    final authProvider = Provider.of<AuthProvider>(_context, listen: false);
    final String? classLeadId = authProvider.currentUser?.uid;
    final AppUser? currentAppUser = authProvider.appUser; // <--- جلب AppUser

    if (classLeadId == null || currentAppUser == null) {
      _errorMessage =
          'معرف المعلم المسؤول أو بيانات المستخدم غير متوفرة. الرجاء تسجيل الدخول مرة أخرى.';
      _isLoading = false;
      notifyListeners();
      debugPrint(
        'ClassLeadProvider: Error - classLeadId or currentAppUser is null.',
      );
      return;
    }

    // التحقق من صلاحية العرض
    if (!currentAppUser.canViewStudents) {
      _errorMessage = 'ليس لديك صلاحية لعرض بيانات الطلاب.';
      _isLoading = false;
      notifyListeners();
      debugPrint(
        'ClassLeadProvider: Permission denied - User cannot view students. currentAppUser.canViewStudents is false.',
      );
      return;
    }

    debugPrint(
      'ClassLeadProvider: Fetching students for Class: $className, Month: $monthKey, ClassLeadId: $classLeadId',
    );

    try {
      _studentRepository
          .getStudentsByClassNameAndClassLeadId(className, classLeadId)
          .listen(
            (students) {
              debugPrint(
                'ClassLeadProvider: Received ${students.length} students for class $className and classLeadId $classLeadId.',
              );
              _classStudents = students.map((student) {
                final payment =
                    student.monthlyPayments[monthKey] ??
                    StudentMonthlyPayment(isPaid: false, amount: 1000.0);
                _localPaymentChanges[student.id] = payment;
                return student;
              }).toList();
              _isLoading = false;
              notifyListeners();
              debugPrint(
                'ClassLeadProvider: Students for class $className updated. Notifying listeners.',
              );
            },
            onError: (error) {
              _errorMessage = 'فشل تحميل الطلاب للفصل $className: $error';
              _isLoading = false;
              notifyListeners();
              debugPrint(
                'ClassLeadProvider: Error fetching students for class $className: $error',
              );
            },
          );
    } catch (e) {
      _errorMessage = 'حدث خطأ غير متوقع أثناء جلب الطلاب: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('ClassLeadProvider: Unexpected error fetching students: $e');
    }
  }

  // <--- جديد: دالة لتبديل حالة الدفع لجميع الطلاب محلياً
  void toggleAllPaymentsStatus(bool newStatus) {
    debugPrint(
      'ClassLeadProvider: Toggling all payments status to $newStatus.',
    );
    _localPaymentChanges.forEach((studentId, payment) {
      _localPaymentChanges[studentId] = payment.copyWith(isPaid: newStatus);
    });
    notifyListeners();
  }
  // نهاية إضافة toggleAllPaymentsStatus --->

  void updateStudentPaymentStatusLocally(String studentId, bool isPaid) {
    final currentPayment = _localPaymentChanges[studentId];
    if (currentPayment != null) {
      _localPaymentChanges[studentId] = currentPayment.copyWith(isPaid: isPaid);
      notifyListeners();
      debugPrint(
        'ClassLeadProvider: Updated student $studentId payment status locally to $isPaid.',
      );
    }
  }

  void updateStudentPaymentAmountLocally(String studentId, double amount) {
    final currentPayment = _localPaymentChanges[studentId];
    if (currentPayment != null) {
      _localPaymentChanges[studentId] = currentPayment.copyWith(amount: amount);
      notifyListeners();
      debugPrint(
        'ClassLeadProvider: Updated student $studentId payment amount locally to $amount.',
      );
    }
  }

  Future<void> saveAllChanges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint('ClassLeadProvider: Attempting to save all local changes...');

    final authProvider = Provider.of<AuthProvider>(_context, listen: false);
    final String? classLeadId =
        authProvider.currentUser?.uid; // <--- جلب UID الحالي للمعلم
    final AppUser? currentAppUser = authProvider.appUser; // <--- جلب AppUser

    if (classLeadId == null || currentAppUser == null) {
      _errorMessage =
          'بيانات المستخدم غير متوفرة. الرجاء تسجيل الدخول مرة أخرى.';
      _isLoading = false;
      notifyListeners();
      debugPrint(
        'ClassLeadProvider: Error - classLeadId or currentAppUser is null during save.',
      );
      return;
    }

    debugPrint(
      'ClassLeadProvider: Current logged-in user UID: $classLeadId',
    ); // <--- رسالة Debug جديدة
    debugPrint(
      'ClassLeadProvider: currentAppUser role: ${currentAppUser.role.toString().split('.').last}',
    );
    debugPrint(
      'ClassLeadProvider: currentAppUser canEditPayments: ${currentAppUser.canEditPayments}',
    );

    // التحقق من صلاحية التعديل
    if (!currentAppUser.canEditPayments) {
      _errorMessage = 'ليس لديك صلاحية لتعديل الدفعات الشهرية.';
      _isLoading = false;
      notifyListeners();
      debugPrint(
        'ClassLeadProvider: Permission denied - User cannot edit payments. currentAppUser.canEditPayments is false.',
      );
      return;
    }

    try {
      // <--- تم التعديل هنا: استخدام دالة تحديث مجمعة بدلاً من التحديث الفردي
      // نجمع فقط الطلاب الذين لديهم تغييرات محلية
      final List<Student> studentsToUpdate = [];
      for (final student in _classStudents) {
        final localChange = _localPaymentChanges[student.id];
        // إذا كان هناك تغيير محلي، أضف الطالب مع الدفعة المحدثة
        if (localChange != null) {
          studentsToUpdate.add(
            student.copyWith(
              monthlyPayments: {
                ...student.monthlyPayments, // احتفظ بالدفعات الأخرى
                _selectedMonthKey: localChange, // تحديث الدفعة للشهر الحالي
              },
            ),
          );
        }
      }

      if (studentsToUpdate.isNotEmpty) {
        debugPrint(
          'ClassLeadProvider: Sending ${studentsToUpdate.length} students for batch update for month $_selectedMonthKey.',
        );
        await _studentRepository.updateMultipleStudentPayments(
          studentsToUpdate,
          _selectedMonthKey,
        );
        debugPrint('ClassLeadProvider: Batch update completed successfully.');
      } else {
        debugPrint(
          'ClassLeadProvider: No students with local changes to save.',
        );
      }

      // لا نقوم بمسح _localPaymentChanges هنا، لأن onSnapshot سيقوم بتحديثها
      // _localPaymentChanges.clear();
      _errorMessage = null;
      debugPrint('ClassLeadProvider: All changes saved successfully.');
    } catch (e) {
      _errorMessage = 'فشل حفظ التغييرات: $e';
      debugPrint(
        'ClassLeadProvider: Error saving changes to Firestore: $e',
      ); // <--- Debug
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
