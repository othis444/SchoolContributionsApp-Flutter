import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // استيراد حزمة التدويل
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // إذا كنت تستخدم Provider
import 'package:school_contributions_app/core/constants/routes.dart'; // تعريف مساراتك
import 'package:school_contributions_app/data/models/user.dart';

// استيراد الشاشات التي سنستخدمها
import 'package:school_contributions_app/presentation/auth/login_screen.dart';
import 'package:school_contributions_app/presentation/admin/admin_dashboard_screen.dart';
import 'package:school_contributions_app/presentation/class_lead/class_lead_dashboard_screen.dart';
import 'package:school_contributions_app/presentation/admin/student_management_screen.dart';
import 'package:school_contributions_app/presentation/admin/user_management_screen.dart';

// استيراد AuthProvider (لإدارة حالة المصادقة وتحديد الدور)
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // تعريف GoRouter للمسارات
    final GoRouter _router = GoRouter(
      initialLocation: AppRoutes.login, // الشاشة الأولية عند فتح التطبيق
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminDashboard,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.classLeadDashboard,
          builder: (context, state) => const ClassLeadDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentManagement,
          builder: (context, state) => const StudentManagementScreen(),
        ),
        GoRoute(
          path: AppRoutes.userManagement,
          builder: (context, state) => const UserManagementScreen(),
        ),
        // يمكنك إضافة مسارات إضافية هنا
      ],
      // منطق إعادة التوجيه بناءً على حالة المصادقة والدور
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final bool loggedIn = authProvider.isLoggedIn;
        final UserRole? userRole =
            authProvider.userRole; // يجب أن يكون الدور نصًا (admin, classLead)

        // تحديد ما إذا كان المستخدم يحاول الوصول إلى شاشة المصادقة
        final bool isLoggingIn = state.fullPath == AppRoutes.login;

        // إذا لم يكن المستخدم مسجل الدخول ويحاول الوصول إلى شاشة غير شاشة تسجيل الدخول، أعد توجيهه إلى شاشة تسجيل الدخول
        if (!loggedIn && !isLoggingIn) {
          return AppRoutes.login;
        }

        // إذا كان المستخدم مسجل الدخول ويحاول الوصول إلى شاشة تسجيل الدخول، أعد توجيهه إلى الشاشة المناسبة لدوره
        if (loggedIn && isLoggingIn) {
          if (userRole == 'admin') {
            return AppRoutes.adminDashboard;
          } else if (userRole == 'classLead') {
            return AppRoutes.classLeadDashboard;
          }
          // إذا كان الدور غير معروف أو غير مدعوم، يمكن إعادته إلى شاشة تسجيل الدخول أو شاشة خطأ
          return AppRoutes.login;
        }

        // لا توجيه إذا كان المستخدم في المكان الصحيح
        return null;
      },
      // معالجة الأخطاء (مثل مسار غير موجود)
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: Center(child: Text('حدث خطأ: ${state.error}')),
      ),
    );

    return MaterialApp.router(
      title: 'متابعة المساهمات المجتمعية',

      // إعدادات التدويل (Internationalization) ودعم اللغة العربية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // دعم اللغة العربية
        Locale('en', ''), // دعم اللغة الإنجليزية (افتراضي)
      ],
      // تحديد اللغة الافتراضية إذا كانت لغة الجهاز غير مدعومة
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales
            .first; // العودة إلى أول لغة مدعومة (العربية في هذه الحالة)
      },

      // إعدادات الثيم (Theme)
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true, // توسيط العنوان
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintStyle: const TextStyle(color: Colors.grey),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        // إعداد اتجاه النص الافتراضي ليكون RTL
        // هذا سيجعل معظم الـ Widgets تتبع اتجاه RTL تلقائياً
        // ومع ذلك، قد تحتاج لضبط بعض الـ Widgets يدوياً إذا لم تتبع الاتجاه بشكل صحيح
        // TextDirection.rtl هو القيمة الافتراضية للغة العربية
        // يمكنك استخدام Directionality Widget لتجاوز هذا في أجزاء معينة
        // ولكن بشكل عام، MaterialApp يتعامل مع هذا بناءً على الـ locale
        // لا حاجة لـ textDirection: TextDirection.rtl هنا بشكل صريح
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false, // لإزالة شارة "Debug"
    );
  }
}
