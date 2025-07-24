// lib/presentation/student_details_screen.dart

import 'package:flutter/material.dart';

class StudentDetailsScreen extends StatelessWidget {
  const StudentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطالب')),
      body: Center(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'شاشة تفاصيل الطالب قيد الإنشاء...',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
