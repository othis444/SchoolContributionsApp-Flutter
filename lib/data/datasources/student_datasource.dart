// lib/data/datasources/student_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_contributions_app/data/models/student.dart';
// تأكد من استيراد هذا

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

  // جلب الطلاب حسب اسم الصف
  Stream<List<Student>> getStudentsByClassName(String className) {
    return _firestore
        .collection('students')
        .where('className', isEqualTo: className)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // <--- جديد: جلب الطلاب حسب اسم الصف ومعرف المعلم المسؤول
  Stream<List<Student>> getStudentsByClassNameAndClassLeadId(
    String className,
    String classLeadId,
  ) {
    return _firestore
        .collection('students')
        .where('className', isEqualTo: className)
        .where('classLeadId', isEqualTo: classLeadId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }
  // نهاية إضافة الدالة الجديدة --->

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
      classLeadName: student.classLeadName, // تأكد من حفظ اسم المعلم
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
      final studentToSave = student.copyWith(id: docRef.id);
      batch.set(docRef, studentToSave.toJson());
    }
    await batch.commit();
  }

  // <--- الدالة التي يتم استدعاؤها من StudentRepository --->
  Future<void> updateStudentPayments(
    List<Student> studentsToUpdate,
    String monthKey,
  ) async {
    final WriteBatch batch = _firestore.batch();

    for (var student in studentsToUpdate) {
      final studentRef = _firestore.collection('students').doc(student.id);
      // تحديث حقل monthlyPayments.$monthKey فقط
      // يجب أن يكون monthlyPayments[monthKey] موجوداً في كائن الطالب
      final paymentData = student.monthlyPayments[monthKey];
      if (paymentData != null) {
        batch.update(studentRef, {
          'monthlyPayments.$monthKey': paymentData.toJson(),
        });
      } else {
        // إذا لم يكن هناك بيانات دفع لهذا الشهر، يمكن تسجيل خطأ أو تخطيه
        print(
          'Warning: No payment data for student ${student.id} for month $monthKey. Skipping update for this student/month.',
        );
      }
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
