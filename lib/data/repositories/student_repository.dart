// lib/data/repositories/student_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/data/models/user.dart';
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint

class StudentRepository {
  final StudentDataSource _studentDataSource;
  final FirebaseFirestore _firestore;

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

  // دالة جديدة: إضافة مجموعة من الطلاب
  Future<void> addStudentsFromCsv(List<Student> students) async {
    await _studentDataSource.addMultipleStudents(students);
  }

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
