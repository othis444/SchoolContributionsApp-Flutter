// lib/data/repositories/student_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide AuthProvider; // إخفاء AuthProvider من Firebase
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/data/models/user.dart'; // استيراد نموذج المستخدم

class StudentRepository {
  final StudentDataSource _studentDataSource;
  final FirebaseFirestore _firestore; // للوصول إلى بيانات المستخدم/الدور

  StudentRepository(this._studentDataSource, this._firestore);

  Stream<List<Student>> getStudentsForClassLead(String classLeadId) {
    return _studentDataSource.getStudentsByClassLeadId(classLeadId);
  }

  Stream<List<Student>> getAllStudents() {
    return _studentDataSource.getAllStudents();
  }

  Future<void> addNewStudent(Student student) async {
    await _studentDataSource.addStudent(student);
  }

  // تحديث مجمع للدفعات
  Future<void> updateMultipleStudentPayments(
    List<Student> students,
    String monthKey,
  ) async {
    await _studentDataSource.updateStudentPayments(students, monthKey);
  }

  Future<void> updateStudentData(Student student) async {
    await _studentDataSource.updateStudent(student);
  }

  Future<void> deleteStudent(String studentId) async {
    await _studentDataSource.deleteStudent(studentId);
  }

  // للحصول على دور المستخدم من Firestore
  Future<UserRole> getUserRole(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('role')) {
        final roleString = userDoc.data()!['role'] as String;
        return UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == roleString,
          orElse: () =>
              UserRole.student, // دور افتراضي إذا لم يتم العثور على الدور
        );
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
    return UserRole
        .student; // دور افتراضي إذا لم يتم العوثور على المستند أو الدور
  }

  // إضافة مستخدم جديد (مدير فقط)
  Future<void> addUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  // تحديث بيانات المستخدم (مثل الفصول المخصصة)
  Future<void> updateUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  // جلب جميع المستخدمين (للمدير)
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppUser.fromJson(doc.data()..['id'] = doc.id),
              ) // تأكد من تعيين الـ ID
              .toList(),
        );
  }
}
