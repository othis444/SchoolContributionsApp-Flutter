// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // استيراد حزمة التدويل
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// استيراد المسارات
import 'package:school_contributions_app/core/constants/routes.dart';
import 'package:school_contributions_app/presentation/admin/student_management_screen.dart';

// استيراد الشاشات التي سنستخدمها
import 'package:school_contributions_app/presentation/auth/login_screen.dart';
import 'package:school_contributions_app/presentation/admin/admin_dashboard_screen.dart';
import 'package:school_contributions_app/presentation/class_lead/class_lead_dashboard_screen.dart';
import 'package:school_contributions_app/presentation/admin/user_management_screen.dart';
import 'package:school_contributions_app/presentation/student_details_screen.dart'; // شاشة تفاصيل الطالب

// استيراد AuthProvider
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
import 'package:school_contributions_app/data/models/user.dart'; // لاستخدام UserRole

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _router = _buildRouter(authProvider);
  }

  GoRouter _buildRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminDashboard,
          builder: (context, state) => const AdminDashboardScreen(),
          routes: [
            // <--- تعريف المسارات الفرعية هنا
            GoRoute(
              path: AppRoutes
                  .studentManagement, // <--- تم التعديل هنا (باستخدام المسار النسبي الجديد)
              builder: (context, state) => const StudentManagementScreen(),
            ),
            GoRoute(
              path: AppRoutes
                  .userManagement, // <--- تم التعديل هنا (باستخدام المسار النسبي الجديد)
              builder: (context, state) => const UserManagementScreen(),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.classLeadDashboard,
          builder: (context, state) =>
              ClassLeadDashboardScreen(key: ValueKey('classLeadDashboard')),
        ),
        GoRoute(
          path: AppRoutes.studentDetails,
          builder: (context, state) =>
              StudentDetailsScreen(key: ValueKey('studentDetails')),
        ),
      ],
      refreshListenable: authProvider,
      redirect: (context, state) {
        final bool isLoggedIn = authProvider.isLoggedIn;
        final UserRole? userRole = authProvider.userRole;
        final bool isLoadingAuth = authProvider.isLoading;

        if (isLoadingAuth) {
          return null;
        }

        final bool isLoggingIn = state.fullPath == AppRoutes.login;
        // <--- تم التعديل هنا: التحقق من أن المسار يبدأ بمسار لوحة تحكم المدير
        final bool isGoingToAdminDashboard =
            state.fullPath == AppRoutes.adminDashboard ||
            (state.fullPath?.startsWith('${AppRoutes.adminDashboard}/') ??
                false); // <--- تم التعديل هنا
        final bool isGoingToClassLeadDashboard =
            state.fullPath == AppRoutes.classLeadDashboard;

        if (!isLoggedIn) {
          return isLoggingIn ? null : AppRoutes.login;
        }

        if (isLoggingIn && isLoggedIn) {
          // <--- تم تبديل الترتيب ليكون منطقيًا أكثر
          if (userRole == UserRole.admin) {
            return AppRoutes.adminDashboard;
          } else if (userRole == UserRole.classLead) {
            return AppRoutes.classLeadDashboard;
          }
          return AppRoutes.login;
        }

        // منع المستخدمين من الوصول إلى لوحات التحكم غير المخصصة لهم
        if (isLoggedIn) {
          if (userRole == UserRole.admin &&
              !isGoingToAdminDashboard &&
              !isLoggingIn) {
            return AppRoutes.adminDashboard;
          }
          if (userRole == UserRole.classLead &&
              !isGoingToClassLeadDashboard &&
              !isLoggingIn) {
            return AppRoutes.classLeadDashboard;
          }
          // إذا كان المستخدم في لوحة التحكم الصحيحة، لا توجيه
          if (userRole == UserRole.admin && isGoingToAdminDashboard)
            return null;
          if (userRole == UserRole.classLead && isGoingToClassLeadDashboard)
            return null;
        }

        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: Center(child: Text('حدث خطأ: ${state.error}')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'متابعة المساهمات المجتمعية',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', ''), Locale('en', '')],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shadowColor: Colors.blue.shade300,
            elevation: 5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          labelStyle: const TextStyle(color: Colors.black87),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
