// lib/data/models/user.dart

import 'package:flutter/foundation.dart'; // لاستخدام debugPrint

enum UserRole { admin, classLead, student }

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final List<String> assignedClasses; // الفصول التي يديرها المعلم
  final bool canEditPayments; // <--- جديد: هل يمكنه تعديل الدفعات الشهرية؟
  final bool canViewStudents; // <--- جديد: هل يمكنه رؤية الطلاب؟

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.assignedClasses = const [],
    this.canEditPayments = true, // <--- القيمة الافتراضية
    this.canViewStudents = true, // <--- القيمة الافتراضية
  });

  // Factory constructor لتحويل البيانات من JSON/Map إلى كائن AppUser
  factory AppUser.fromJson(Map<String, dynamic> json) {
    debugPrint('AppUser.fromJson: Parsing JSON: $json'); // Debug
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.student, // دور افتراضي إذا لم يتم العثور عليه
      ),
      assignedClasses:
          (json['assignedClasses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      canEditPayments:
          json['canEditPayments'] as bool? ??
          true, // <--- قراءة مع قيمة افتراضية
      canViewStudents:
          json['canViewStudents'] as bool? ??
          true, // <--- قراءة مع قيمة افتراضية
    );
  }

  // دالة لتحويل كائن AppUser إلى JSON/Map لحفظه في Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.toString().split('.').last,
      'assignedClasses': assignedClasses,
      'canEditPayments': canEditPayments, // <--- حفظ الحقل الجديد
      'canViewStudents': canViewStudents, // <--- حفظ الحقل الجديد
    };
  }

  // دالة مساعدة لإنشاء نسخة جديدة من المستخدم مع تحديثات
  AppUser copyWith({
    String? id,
    String? email,
    UserRole? role,
    List<String>? assignedClasses,
    bool? canEditPayments, // <--- حقل جديد لـ copyWith
    bool? canViewStudents, // <--- حقل جديد لـ copyWith
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      canEditPayments:
          canEditPayments ?? this.canEditPayments, // <--- استخدام الحقل الجديد
      canViewStudents:
          canViewStudents ?? this.canViewStudents, // <--- استخدام الحقل الجديد
    );
  }
}
