// lib/data/models/user.dart

enum UserRole {
  admin,
  classLead,
  student, // يمكن إضافة هذا الدور إذا كان هناك شاشة خاصة بالطلاب
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final List<String> assignedClasses; // قائمة بالصفوف المخصصة لمسؤول الفصل

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.assignedClasses = const [],
  });

  // Factory constructor لتحويل البيانات من JSON/Map إلى كائن AppUser
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      // تحويل النص (مثل 'admin') إلى قيمة enum (UserRole.admin)
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'] as String,
        orElse: () =>
            UserRole.student, // قيمة افتراضية إذا لم يتم العثور على الدور
      ),
      assignedClasses: List<String>.from(json['assignedClasses'] ?? []),
    );
  }

  // دالة لتحويل كائن AppUser إلى JSON/Map لحفظه في Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role
          .toString()
          .split('.')
          .last, // تخزين الدور كنص (e.g., 'admin', 'classLead')
      'assignedClasses': assignedClasses,
    };
  }
}
