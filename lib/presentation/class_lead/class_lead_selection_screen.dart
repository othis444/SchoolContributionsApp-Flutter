// lib/presentation/class_lead/class_lead_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl2;
import 'package:provider/provider.dart';
import 'package:school_contributions_app/core/constants/routes.dart';
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
// import 'package:school_contributions_app/presentation/providers/class_lead_provider.dart'; // هذا الاستيراد غير ضروري هنا

class ClassLeadSelectionScreen extends StatefulWidget {
  const ClassLeadSelectionScreen({super.key});

  @override
  State<ClassLeadSelectionScreen> createState() =>
      _ClassLeadSelectionScreenState();
}

class _ClassLeadSelectionScreenState extends State<ClassLeadSelectionScreen> {
  int _selectedYear = DateTime.now().year;
  String? _selectedMonthKey;
  String? _selectedClass; // الصف الذي سيختاره المعلم

  // <--- تم التعديل هنا: قائمة بجميع الفصول المتاحة (بالأرقام)
  final List<String> _availableClasses = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
  ];

  @override
  void initState() {
    super.initState();
    // تهيئة الشهر الافتراضي إلى الشهر الحالي
    _selectedMonthKey = intl2.DateFormat('yyyy-MM').format(DateTime.now());
  }

  // دالة لعرض منتقي السنة
  Future<void> _selectYear(BuildContext context) async {
    final DateTime now = DateTime.now();
    final int? pickedYear = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر السنة'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 1),
              selectedDate: DateTime(_selectedYear),
              onChanged: (DateTime newDate) {
                setState(() {
                  _selectedYear = newDate.year;
                });
                Navigator.pop(context, newDate.year);
              },
            ),
          ),
        );
      },
    );

    if (pickedYear != null && pickedYear != _selectedYear) {
      setState(() {
        _selectedYear = pickedYear;
        // إعادة تعيين الشهر عند تغيير السنة
        _selectedMonthKey = intl2.DateFormat(
          'yyyy-MM',
        ).format(DateTime(_selectedYear, DateTime.now().month));
      });
    }
  }

  // دالة لعرض نافذة اختيار الصف
  void _showClassSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('اختر الصف'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _availableClasses.map((className) {
                  return ListTile(
                    title: Text(
                      'الصف $className',
                    ), // عرض "الصف 1" بدلاً من "1" فقط
                    onTap: () {
                      setState(() {
                        _selectedClass = className;
                      });
                      Navigator.of(dialogContext).pop(); // إغلاق مربع الحوار
                      _navigateToDashboard(); // الانتقال بعد اختيار الصف
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDashboard() {
    if (_selectedMonthKey != null && _selectedClass != null) {
      context.push(
        '${AppRoutes.classLeadDashboard}/$_selectedMonthKey/$_selectedClass',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الشهر والصف.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String? userName = authProvider.currentUser?.email?.split('@').first;

    return Scaffold(
      appBar: AppBar(
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'أهلاً بك يا ${userName ?? 'معلم'}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _selectYear(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'السنة: $_selectedYear',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'اختر الشهر لعرض الدفعات:',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // شبكة من الأزرار للأشهر
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 3 أعمدة
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio:
                                  1.2, // نسبة العرض إلى الارتفاع للأزرار
                            ),
                        itemCount: 12, // 12 شهرًا
                        itemBuilder: (context, index) {
                          final month = index + 1; // 1 = يناير, 12 = ديسمبر
                          final monthDate = DateTime(_selectedYear, month);
                          final monthKey = intl2.DateFormat(
                            'yyyy-MM',
                          ).format(monthDate);
                          final monthName = intl2.DateFormat.MMMM(
                            'ar',
                          ).format(monthDate);

                          return ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedMonthKey = monthKey;
                              });
                              _showClassSelectionDialog(); // عرض مربع حوار اختيار الصف بعد اختيار الشهر
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedMonthKey == monthKey
                                  ? Colors.blue.shade700
                                  : Colors.blue.shade100,
                              foregroundColor: _selectedMonthKey == monthKey
                                  ? Colors.white
                                  : Colors.blue.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: Colors.blue.shade200,
                            ),
                            child: Text(
                              monthName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
