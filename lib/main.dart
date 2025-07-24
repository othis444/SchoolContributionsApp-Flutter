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
  // هذا السطر يقوم بتهيئة Firebase باستخدام الخيارات الخاصة بمنصتك
  // التي يتم إنشاؤها تلقائياً بواسطة FlutterFire CLI في ملف firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تشغيل التطبيق وتوفير مزودي الحالة (Providers)
  runApp(
    MultiProvider(
      providers: [
        // توفير AuthProvider لإدارة حالة المصادقة في جميع أنحاء التطبيق
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // توفير AdminDashboardProvider لإدارة حالة لوحة تحكم المدير
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        // توفير ClassLeadProvider لإدارة حالة لوحة تحكم مسؤول الفصل
        ChangeNotifierProvider(create: (_) => ClassLeadProvider()),
        // يمكنك إضافة أي مزودي حالة إضافيين هنا حسب الحاجة
      ],
      // MyApp هو الـ Widget الجذر لتطبيقك، والذي تم تعريفه في ملف app.dart
      child: const MyApp(),
    ),
  );
}
