// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // استيراد Firebase Core
import 'package:provider/provider.dart'; // استيراد Provider لإدارة الحالة

// استيراد ملف التطبيق الرئيسي
import 'package:school_contributions_app/app.dart';

// استيراد ملف إعدادات Firebase (يتم إنشاؤه بواسطة FlutterFire CLI)
import 'package:school_contributions_app/firebase_options.dart';

// استيراد مزودي الحالة (Providers)
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
import 'package:school_contributions_app/presentation/providers/admin_dashboard_provider.dart';
import 'package:school_contributions_app/presentation/providers/class_lead_provider.dart';

void main() async {
  // التأكد من تهيئة Flutter Widgets قبل أي عمليات أخرى
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تشغيل التطبيق وتوفير مزودي الحالة (Providers)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        // <--- تم التعديل هنا: تمرير context إلى ClassLeadProvider
        ChangeNotifierProvider(
          create: (context) => ClassLeadProvider(context: context),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
