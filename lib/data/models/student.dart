// lib/data/models/student.dart

import 'package:school_contributions_app/data/models/student_monthly_payment.dart';

class Student {
  final String id; // Firestore Document ID (Auto-ID)
  final String serialNumber; // الرقم التسلسلي للطالب
  final String studentName; // اسم الطالب
  final String className; // الصف (مثلاً "الصف السابع أ")
  final String gender; // الجنس (ذكر أو أنثى)
  final String section; // الشعبة (مثلاً "أ")
  final String classLeadId; // ID الخاص بالمعلم المسؤول عن هذا الصف

  // تحديثات لبيانات الدفع الشهرية
  final Map<String, StudentMonthlyPayment>
  monthlyPayments; // Key: 'YYYY-MM', Value: StudentMonthlyPayment object

  Student({
    required this.id, // هذا سيكون Document ID من Firestore
    required this.serialNumber,
    required this.studentName,
    required this.className,
    required this.gender,
    required this.section,
    required this.classLeadId,
    this.monthlyPayments = const {},
  });

  // Factory constructor لتحويل البيانات من JSON/Map إلى كائن Student
  factory Student.fromJson(Map<String, dynamic> json, String documentId) {
    final Map<String, dynamic>? paymentsJson =
        json['monthlyPayments'] as Map<String, dynamic>?;
    final Map<String, StudentMonthlyPayment> parsedPayments = {};
    if (paymentsJson != null) {
      paymentsJson.forEach((key, value) {
        parsedPayments[key] = StudentMonthlyPayment.fromJson(
          Map<String, dynamic>.from(value),
        );
      });
    }

    return Student(
      id: documentId, // استخدام Document ID كـ 'id' للكائن
      serialNumber: json['serialNumber'] as String,
      studentName: json['studentName'] as String,
      className: json['className'] as String,
      gender: json['gender'] as String,
      section: json['section'] as String,
      classLeadId: json['classLeadId'] as String,
      monthlyPayments: parsedPayments,
    );
  }

  // دالة لتحويل كائن Student إلى JSON/Map لحفظه في Firestore (لا تتضمن الـ 'id' هنا)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> paymentsJson = {};
    monthlyPayments.forEach((key, value) {
      paymentsJson[key] = value.toJson();
    });

    return {
      'serialNumber': serialNumber,
      'studentName': studentName,
      'className': className,
      'gender': gender,
      'section': section,
      'classLeadId': classLeadId,
      'monthlyPayments': paymentsJson,
    };
  }

  // دالة مساعدة لإنشاء نسخة جديدة من الطالب مع تحديثات
  Student copyWith({
    String? serialNumber,
    String? studentName,
    String? className,
    String? gender,
    String? section,
    String? classLeadId,
    Map<String, StudentMonthlyPayment>? monthlyPayments,
  }) {
    return Student(
      id: id,
      serialNumber: serialNumber ?? this.serialNumber,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      gender: gender ?? this.gender,
      section: section ?? this.section,
      classLeadId: classLeadId ?? this.classLeadId,
      monthlyPayments: monthlyPayments ?? this.monthlyPayments,
    );
  }
}
