// lib/presentation/providers/admin_dashboard_provider.dart

import 'package:flutter/material.dart';
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/repositories/student_repository.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // لتهيئة StudentRepository

class AdminDashboardProvider extends ChangeNotifier {
  late final StudentRepository _studentRepository;
  List<Student> _allStudents = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminDashboardProvider() {
    _studentRepository = StudentRepository(
      StudentDataSource(FirebaseFirestore.instance),
      FirebaseFirestore.instance,
    );
    // يمكن البدء بتحميل البيانات هنا أو عند الحاجة
    _listenToAllStudents();
  }

  List<Student> get allStudents => _allStudents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _listenToAllStudents() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _studentRepository.getAllStudents().listen(
      (students) {
        _allStudents = students;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'فشل تحميل بيانات الطلاب: $error';
        _isLoading = false;
        notifyListeners();
        print('Error listening to all students: $error');
      },
    );
  }

  // دوال لإدارة الطلاب (إضافة، تعديل، حذف)
  Future<void> addStudent(Student student) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _studentRepository.addNewStudent(student);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'فشل إضافة الطالب: $e';
      print('Error adding student: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // يمكنك إضافة دوال أخرى هنا مثل:
  // Future<void> updateStudent(Student student) async { ... }
  // Future<void> deleteStudent(String studentId) async { ... }
  // Future<void> importStudentsFromCsv(File csvFile) async { ... }
}
