// lib/presentation/class_lead/class_lead_dashboard_screen.dart

import 'package:flutter/material.dart';

class ClassLeadDashboardScreen extends StatelessWidget {
  const ClassLeadDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة تحكم مسؤول الفصل')),
      body: const Center(child: Text('شاشة مسؤول الفصل قيد الإنشاء...')),
    );
  }
}
