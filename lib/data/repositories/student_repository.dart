// lib/data/repositories/student_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/data/models/user.dart';
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint
// تأكد من استيراد هذا

class StudentRepository {
  final StudentDataSource _studentDataSource;
  final FirebaseFirestore _firestore; // للحصول على دور المستخدم مباشرة

  StudentRepository(this._studentDataSource, this._firestore);

  Stream<List<Student>> getStudentsByClassLeadId(String classLeadId) {
    return _studentDataSource.getStudentsByClassLeadId(classLeadId);
  }

  Stream<List<Student>> getStudentsByClassName(String className) {
    return _studentDataSource.getStudentsByClassName(className);
  }

  // <--- جديد: جلب الطلاب حسب اسم الصف ومعرف المعلم المسؤول
  Stream<List<Student>> getStudentsByClassNameAndClassLeadId(
    String className,
    String classLeadId,
  ) {
    return _studentDataSource.getStudentsByClassNameAndClassLeadId(
      className,
      classLeadId,
    );
  }
  // نهاية إضافة الدالة الجديدة --->

  Stream<List<Student>> getAllStudents() {
    return _studentDataSource.getAllStudents();
  }

  Future<void> addNewStudent(Student student) async {
    await _studentDataSource.addStudent(student);
  }

  // <--- جديد: إضافة دالة addStudentsFromCsv التي تستدعي addMultipleStudents
  Future<void> addStudentsFromCsv(List<Student> students) async {
    await _studentDataSource.addMultipleStudents(students);
  }
  // نهاية إضافة الدالة الجديدة --->

  // الدالة updateMultipleStudentPayments موجودة بالفعل وتستدعي updateStudentPayments من DataSource
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

  Future<UserRole> getUserRole(String userId) async {
    debugPrint('StudentRepository: Attempting to get role for userId: $userId');
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        debugPrint('StudentRepository: User document for $userId exists.');
        if (userDoc.data()!.containsKey('role')) {
          final roleString = userDoc.data()!['role'] as String;
          debugPrint(
            'StudentRepository: Fetched role string from Firestore: "$roleString" for user $userId',
          );

          final cleanedRoleString = roleString.trim().toLowerCase();

          final foundRole = UserRole.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() == cleanedRoleString,
            orElse: () {
              debugPrint(
                'StudentRepository: Role string "$roleString" (cleaned to "$cleanedRoleString") not found in UserRole enum. Defaulting to Student.',
              );
              return UserRole.student;
            },
          );
          debugPrint(
            'StudentRepository: Resolved role for $userId: ${foundRole.toString().split('.').last}',
          );
          return foundRole;
        } else {
          debugPrint(
            'StudentRepository: User document for $userId exists, but does not contain "role" field.',
          );
          return UserRole.student;
        }
      } else {
        debugPrint(
          'StudentRepository: User document for $userId does NOT exist in Firestore.',
        );
        return UserRole.student;
      }
    } catch (e) {
      debugPrint('StudentRepository: ERROR getting user role for $userId: $e');
      return UserRole.student;
    }
  }

  Future<AppUser?> getUserData(String userId) async {
    debugPrint(
      'StudentRepository: Attempting to get AppUser data for userId: $userId',
    );
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        debugPrint('StudentRepository: User data for $userId: $data');
        return AppUser.fromJson(data..['id'] = userDoc.id);
      } else {
        debugPrint(
          'StudentRepository: User document for $userId does NOT exist or is empty.',
        );
        return null;
      }
    } catch (e) {
      debugPrint(
        'StudentRepository: ERROR getting AppUser data for $userId: $e',
      );
      return null;
    }
  }

  Future<void> addUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromJson(doc.data()..['id'] = doc.id))
              .toList(),
        );
  }

  Future<void> deleteUser(String userId) async {
    await _studentDataSource.deleteUser(userId);
  }
}
