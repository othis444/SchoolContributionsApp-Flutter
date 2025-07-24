// lib/data/datasources/student_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_contributions_app/data/models/student.dart'; // <--- تأكد من وجود هذا الاستيراد
import 'package:school_contributions_app/data/models/student_monthly_payment.dart';

class StudentDataSource {
  final FirebaseFirestore _firestore;

  StudentDataSource(this._firestore);

  // جلب الطلاب حسب مسؤول الفصل
  Stream<List<Student>> getStudentsByClassLeadId(String classLeadId) {
    return _firestore
        .collection('students')
        .where('classLeadId', isEqualTo: classLeadId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // جلب جميع الطلاب (للمدير)
  Stream<List<Student>> getAllStudents() {
    return _firestore
        .collection('students')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // إضافة طالب جديد (باستخدام Auto-ID)
  Future<void> addStudent(Student student) async {
    final docRef = _firestore.collection('students').doc();
    final studentToSave = Student(
      id: docRef.id,
      serialNumber: student.serialNumber,
      studentName: student.studentName,
      className: student.className,
      gender: student.gender,
      section: student.section,
      classLeadId: student.classLeadId,
      monthlyPayments: student.monthlyPayments,
    );
    await docRef.set(studentToSave.toJson());
  }

  // دالة جديدة: إضافة مجموعة من الطلاب باستخدام WriteBatch
  Future<void> addMultipleStudents(List<Student> students) async {
    final WriteBatch batch = _firestore.batch();
    for (var student in students) {
      final docRef = _firestore
          .collection('students')
          .doc(); // إنشاء معرف تلقائي لكل طالب
      // إنشاء نسخة من الطالب مع الـ ID الجديد قبل تحويله إلى JSON
      final studentToSave = student.copyWith(id: docRef.id);
      batch.set(docRef, studentToSave.toJson());
    }
    await batch.commit();
  }

  // تحديث بيانات الدفع الشهرية لطالب (عملية دفع مجمعة)
  Future<void> updateStudentPayments(
    List<Student> studentsToUpdate,
    String monthKey,
  ) async {
    final WriteBatch batch = _firestore.batch();

    for (var student in studentsToUpdate) {
      final studentRef = _firestore.collection('students').doc(student.id);
      batch.update(studentRef, {
        'monthlyPayments.$monthKey': student.monthlyPayments[monthKey]
            ?.toJson(),
      });
    }

    await batch.commit();
  }

  // تحديث بيانات طالب واحد (إذا تم تغيير الاسم، الصف، إلخ)
  Future<void> updateStudent(Student student) async {
    await _firestore
        .collection('students')
        .doc(student.id)
        .update(student.toJson());
  }

  // حذف طالب
  Future<void> deleteStudent(String studentId) async {
    await _firestore.collection('students').doc(studentId).delete();
  }

  // دالة جديدة: حذف مستخدم من مجموعة 'users'
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}
