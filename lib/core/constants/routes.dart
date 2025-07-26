// lib/core/constants/routes.dart

class AppRoutes {
  static const String login = '/';
  static const String adminDashboard = '/admin-dashboard';
  static const String classLeadSelection =
      '/class-lead-selection'; // <--- جديد: مسار شاشة اختيار المعلم
  static const String classLeadDashboard = '/class-lead-dashboard';
  // <--- تم التعديل هنا: جعل هذه المسارات نسبية للمسار الأب
  static const String studentManagement =
      'student-management'; // لا تبدأ بـ '/'
  static const String userManagement = 'user-management'; // لا تبدأ بـ '/'
  static const String studentDetails =
      '/student-details'; // مسار اختياري لتفاصيل الطالب
}
