// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // استيراد حزمة التدويل
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// استيراد المسارات
import 'package:school_contributions_app/core/constants/routes.dart';

// استيراد الشاشات التي سنستخدمها
import 'package:school_contributions_app/presentation/auth/login_screen.dart';
import 'package:school_contributions_app/presentation/admin/admin_dashboard_screen.dart';
import 'package:school_contributions_app/presentation/class_lead/class_lead_dashboard_screen.dart';
import 'package:school_contributions_app/presentation/class_lead/class_lead_selection_screen.dart'; // <--- استيراد الشاشة الجديدة
import 'package:school_contributions_app/presentation/admin/student_management_screen.dart';
import 'package:school_contributions_app/presentation/admin/user_management_screen.dart';
import 'package:school_contributions_app/presentation/student_details_screen.dart';
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
import 'package:school_contributions_app/data/models/user.dart';
// import 'package:flutter/foundation.dart'; // <--- تم إزالة هذا الاستيراد غير الضروري

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  bool _isRouterInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _router = GoRouter(
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
              GoRoute(
                path: AppRoutes.studentManagement,
                builder: (context, state) => const StudentManagementScreen(),
              ),
              GoRoute(
                path: AppRoutes.userManagement,
                builder: (context, state) => const UserManagementScreen(),
              ),
            ],
          ),
          // مسار شاشة اختيار الشهر والصف للمعلم
          GoRoute(
            path: AppRoutes.classLeadSelection,
            builder: (context, state) => const ClassLeadSelectionScreen(),
          ),
          // مسار لوحة تحكم المعلم مع المعاملات
          GoRoute(
            path: '${AppRoutes.classLeadDashboard}/:monthKey/:className',
            builder: (context, state) {
              final monthKey = state.pathParameters['monthKey'];
              final className = state.pathParameters['className'];
              if (monthKey == null || className == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('خطأ')),
                  body: const Center(
                    child: Text('معلومات الشهر أو الصف مفقودة!'),
                  ),
                );
              }
              // <--- تمرير المعاملات كـ named parameters
              return ClassLeadDashboardScreen(
                monthKey: monthKey,
                className: className,
                key: ValueKey('classLeadDashboard-$monthKey-$className'),
              );
            },
          ),
          GoRoute(
            path: '${AppRoutes.studentDetails}/:studentId',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId'];
              debugPrint(
                'StudentDetailsScreen builder: studentId received: $studentId',
              );
              if (studentId == null) {
                debugPrint(
                  'StudentDetailsScreen builder: studentId is NULL, showing error screen.',
                );
                return Scaffold(
                  appBar: AppBar(title: const Text('خطأ')),
                  body: const Center(child: Text('معرف الطالب مفقود!')),
                );
              }
              return StudentDetailsScreen(
                studentId: studentId,
                key: ValueKey('studentDetails-$studentId'),
              );
            },
          ),
        ],
        refreshListenable: authProvider,
        redirect: (context, state) {
          final bool isLoggedIn = authProvider.isLoggedIn;
          final UserRole? userRole = authProvider.userRole;
          final bool isLoadingAuth = authProvider.isLoading;

          debugPrint(
            'GoRouter Redirect: Current Path: ${state.fullPath}, IsLoggedIn: $isLoggedIn, UserRole: ${userRole?.toString().split('.').last}, IsLoading: $isLoadingAuth',
          );

          if (isLoadingAuth) {
            debugPrint(
              'GoRouter Redirect: Auth or Role is still loading, returning null.',
            );
            return null;
          }

          final bool isLoggingIn = state.fullPath == AppRoutes.login;
          final bool isGoingToAdminDashboard =
              state.fullPath == AppRoutes.adminDashboard ||
              (state.fullPath?.startsWith('${AppRoutes.adminDashboard}/') ??
                  false);
          final bool isGoingToClassLeadSelection =
              state.fullPath == AppRoutes.classLeadSelection;
          final bool isGoingToClassLeadDashboard =
              state.fullPath?.startsWith('${AppRoutes.classLeadDashboard}/') ??
              false;
          final bool isGoingToStudentDetails =
              (state.fullPath?.startsWith('${AppRoutes.studentDetails}/') ??
              false);

          if (!isLoggedIn) {
            debugPrint(
              'GoRouter Redirect: Not logged in. Redirecting to login if not already there.',
            );
            return isLoggingIn ? null : AppRoutes.login;
          }

          if (isLoggingIn && isLoggedIn) {
            debugPrint(
              'GoRouter Redirect: Logged in and on login screen. Checking role for redirection.',
            );
            if (userRole == UserRole.admin) {
              debugPrint(
                'GoRouter Redirect: Role is Admin. Redirecting to Admin Dashboard.',
              );
              return AppRoutes.adminDashboard;
            } else if (userRole == UserRole.classLead) {
              debugPrint(
                'GoRouter Redirect: Role is Class Lead. Redirecting to Class Lead Selection.',
              );
              return AppRoutes.classLeadSelection;
            }
            debugPrint(
              'GoRouter Redirect: Role not recognized or is Student. Redirecting to Login.',
            );
            return AppRoutes.login;
          }

          // إذا كان المستخدم مسجل الدخول وليس في شاشة تسجيل الدخول،
          // تأكد من أنه في لوحة التحكم الصحيحة لدوره
          if (isLoggedIn && !isLoggingIn) {
            if (userRole == UserRole.admin &&
                !isGoingToAdminDashboard &&
                !isGoingToStudentDetails) {
              debugPrint(
                'GoRouter Redirect: Logged in as Admin, but not on Admin Dashboard or Student Details path. Redirecting.',
              );
              return AppRoutes.adminDashboard;
            } else if (userRole == UserRole.classLead &&
                !isGoingToClassLeadSelection &&
                !isGoingToClassLeadDashboard &&
                !isGoingToStudentDetails) {
              debugPrint(
                'GoRouter Redirect: Logged in as Class Lead, but not on Class Lead Selection/Dashboard or Student Details path. Redirecting.',
              );
              return AppRoutes.classLeadSelection;
            } else if (userRole == UserRole.student) {
              debugPrint(
                'GoRouter Redirect: Logged in as Student. Redirecting to Login.',
              );
              return AppRoutes.login;
            }
          }

          debugPrint(
            'GoRouter Redirect: No specific redirect needed. User is in correct state.',
          );
          return null;
        },
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('خطأ')),
          body: Center(child: Text('حدث خطأ: ${state.error}')),
        ),
      );
      setState(() {
        _isRouterInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRouterInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

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
              fontSize: 16,
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
