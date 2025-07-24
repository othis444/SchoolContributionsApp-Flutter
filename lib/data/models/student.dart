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
  final String? classLeadName; // اسم المعلم المسؤول

  // تحديثات لبيانات الدفع الشهرية
  final Map<String, StudentMonthlyPayment>
  monthlyPayments; // Key: 'YYYY-MM', Value: StudentMonthlyPayment object

  Student({
    required this.id,
    required this.serialNumber,
    required this.studentName,
    required this.className,
    required this.gender,
    required this.section,
    required this.classLeadId,
    this.classLeadName,
    this.monthlyPayments = const {}, // القيمة الافتراضية هي خريطة فارغة
  });

  // Factory constructor لتحويل البيانات من JSON/Map إلى كائن Student
  factory Student.fromJson(Map<String, dynamic> json, String documentId) {
    final Map<String, dynamic>? paymentsJson =
        json['monthlyPayments'] as Map<String, dynamic>?;
    final Map<String, StudentMonthlyPayment> parsedPayments = {};
    if (paymentsJson != null) {
      paymentsJson.forEach((key, value) {
        // تأكد أن القيمة هي Map قبل التحويل
        if (value is Map<String, dynamic>) {
          parsedPayments[key] = StudentMonthlyPayment.fromJson(value);
        }
      });
    }

    return Student(
      id: documentId,
      serialNumber: json['serialNumber'] as String,
      studentName: json['studentName'] as String,
      className: json['className'] as String,
      gender: json['gender'] as String,
      section: json['section'] as String,
      classLeadId: json['classLeadId'] as String,
      classLeadName: json['classLeadName'] as String?,
      monthlyPayments:
          parsedPayments, // استخدام الخريطة المحللة (قد تكون فارغة)
    );
  }

  // دالة لتحويل كائن Student إلى JSON/Map لحفظه في Firestore
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
      'classLeadName': classLeadName,
      'monthlyPayments': paymentsJson,
    };
  }

  // دالة مساعدة لإنشاء نسخة جديدة من الطالب مع تحديثات
  Student copyWith({
    String? id,
    String? serialNumber,
    String? studentName,
    String? className,
    String? gender,
    String? section,
    String? classLeadId,
    String? classLeadName,
    Map<String, StudentMonthlyPayment>? monthlyPayments,
  }) {
    return Student(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      gender: gender ?? this.gender,
      section: section ?? this.section,
      classLeadId: classLeadId ?? this.classLeadId,
      classLeadName: classLeadName ?? this.classLeadName,
      monthlyPayments: monthlyPayments ?? this.monthlyPayments,
    );
  }
}
