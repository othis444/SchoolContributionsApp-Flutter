// lib/presentation/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
import 'package:school_contributions_app/core/constants/routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              // GoRouter سيتعامل مع إعادة التوجيه إلى شاشة تسجيل الدخول
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          // لضمان التمرير إذا كانت الشاشة صغيرة
          padding: const EdgeInsets.all(24.0),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // لجعل الأزرار تمتد بعرض الشاشة
              children: [
                // أيقونة ترحيبية أو شعار
                Icon(
                  Icons.dashboard, // أيقونة لوحة التحكم
                  size: 100,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(height: 24.0),
                Text(
                  'مرحباً بك أيها المدير!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'اختر الإجراء الذي تريد القيام به:',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 40.0),

                // زر إدارة الطلاب
                ElevatedButton.icon(
                  // <--- تم التعديل هنا: استخدام المسار الكامل الصحيح
                  onPressed: () => GoRouter.of(context).go(
                    '${AppRoutes.adminDashboard}/${AppRoutes.studentManagement}',
                  ),
                  icon: const Icon(Icons.people_alt_rounded, size: 28),
                  label: const Text(
                    'إدارة الطلاب',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Colors.blue.shade300,
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // زر إدارة المستخدمين
                ElevatedButton.icon(
                  // <--- تم التعديل هنا: استخدام المسار الكامل الصحيح
                  onPressed: () => GoRouter.of(context).go(
                    '${AppRoutes.adminDashboard}/${AppRoutes.userManagement}',
                  ),
                  icon: const Icon(Icons.manage_accounts_rounded, size: 28),
                  label: const Text(
                    'إدارة المستخدمين',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Colors.green.shade300,
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // يمكنك إضافة المزيد من الأزرار هنا لوظائف إدارية أخرى
                // مثال: زر التقارير
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('شاشة التقارير قيد الإنشاء.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart_rounded, size: 28),
                  label: const Text(
                    'التقارير والإحصائيات',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Colors.orange.shade300,
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
