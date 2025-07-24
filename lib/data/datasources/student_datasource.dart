// lib/data/datasources/student_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_contributions_app/data/models/student.dart';
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
              .map(
                (doc) => Student.fromJson(doc.data(), doc.id),
              ) // تمرير doc.id هنا
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
              .map(
                (doc) => Student.fromJson(doc.data(), doc.id),
              ) // تمرير doc.id هنا
              .toList(),
        );
  }

  // إضافة طالب جديد (باستخدام Auto-ID)
  Future<void> addStudent(Student student) async {
    // عند استخدام Auto-ID، نترك doc() بدون وسيط ونقوم بتحديث الـ ID في الكائن بعد الإضافة
    final docRef = _firestore.collection('students').doc();
    await docRef.set(
      student.copyWith(id: docRef.id).toJson(),
    ); // تحديث الـ ID في الكائن قبل الحفظ
  }

  // تحديث بيانات الدفع الشهرية لطالب (عملية دفع مجمعة)
  Future<void> updateStudentPayments(
    List<Student> studentsToUpdate,
    String monthKey,
  ) async {
    final WriteBatch batch = _firestore.batch();

    for (var student in studentsToUpdate) {
      final studentRef = _firestore.collection('students').doc(student.id);
      // تحديث حقل monthlyPayments فقط
      batch.update(studentRef, {
        'monthlyPayments.$monthKey': student.monthlyPayments[monthKey]
            ?.toJson(),
      });
    }

    await batch.commit();
  }

  // تحديث بيانات طالب واحد (إذا تم تغيير الاسم، الصف، إلخ)
  Future<void> updateStudent(Student student) async {
    // لا نستخدم student.id هنا كحقل، بل كمعرف للمستند
    await _firestore
        .collection('students')
        .doc(student.id)
        .update(student.toJson());
  }

  // حذف طالب
  Future<void> deleteStudent(String studentId) async {
    await _firestore.collection('students').doc(studentId).delete();
  }
}
