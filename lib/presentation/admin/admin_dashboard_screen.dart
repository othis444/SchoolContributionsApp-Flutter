// lib/presentation/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة تحكم الإدارة')),
      body: const Center(child: Text('شاشة لوحة تحكم الإدارة قيد الإنشاء...')),
    );
  }
}
