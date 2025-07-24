// lib/presentation/admin/student_management_screen.dart

import 'package:flutter/material.dart';

class StudentManagementScreen extends StatelessWidget {
  const StudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلاب')),
      body: const Center(child: Text('شاشة إدارة الطلاب قيد الإنشاء...')),
    );
  }
}
