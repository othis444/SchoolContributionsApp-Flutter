// lib/presentation/class_lead/class_lead_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
import 'package:school_contributions_app/presentation/providers/class_lead_provider.dart'; // <--- استيراد مزود مسؤول الفصل
import 'package:school_contributions_app/data/models/student.dart'; // <--- استيراد نموذج الطالب
import 'package:intl/intl.dart' as intl2; // لتنسيق التاريخ
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint
import 'package:school_contributions_app/data/models/student_monthly_payment.dart'; // استيراد StudentMonthlyPayment

class ClassLeadDashboardScreen extends StatefulWidget {
  final String monthKey; // مفتاح الشهر (YYYY-MM)
  final String className; // اسم الصف

  const ClassLeadDashboardScreen({
    super.key,
    required this.monthKey,
    required this.className,
  });

  @override
  State<ClassLeadDashboardScreen> createState() =>
      _ClassLeadDashboardScreenState();
}

class _ClassLeadDashboardScreenState extends State<ClassLeadDashboardScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedSectionFilter;

  final List<String> _availableSectionsFilter = ['أ', 'ب', 'ج', 'د', 'هـ'];

  @override
  void initState() {
    super.initState();
    // جلب الطلاب عند تهيئة الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClassLeadProvider>(
        context,
        listen: false,
      ).fetchStudentsForClassAndMonth(widget.className, widget.monthKey);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // دالة للتحقق من صحة البيانات قبل الحفظ
  Future<void> _validateAndSave() async {
    final classLeadProvider = Provider.of<ClassLeadProvider>(
      context,
      listen: false,
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // التحقق من صحة حقول Form (مثل حقول المبلغ)
    if (!_formKey.currentState!.validate()) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('الرجاء تصحيح الأخطاء في الحقول قبل الحفظ.'),
        ),
      );
      return;
    }

    if (classLeadProvider.localPaymentChanges.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('لا توجد تغييرات لحفظها.')),
      );
      return;
    }

    // إذا كانت جميع البيانات سليمة، قم بالحفظ
    await classLeadProvider.saveAllChanges();
    if (classLeadProvider.errorMessage == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم حفظ التغييرات بنجاح!')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(classLeadProvider.errorMessage!)),
      );
    }
  }
  // نهاية دالة التحقق والحفظ --->

  // دالة لفلترة الطلاب بناءً على الشعبة
  List<Student> _getFilteredStudents(List<Student> students) {
    if (_selectedSectionFilter == null) {
      return students;
    }
    return students
        .where((student) => student.section == _selectedSectionFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final classLeadProvider = Provider.of<ClassLeadProvider>(
      context,
    ); // الاستماع لتغييرات الطلاب

    final String? userName = authProvider.currentUser?.email?.split('@').first;

    // تنسيق الشهر للعرض
    final monthDate = intl2.DateFormat('yyyy-MM').parse(widget.monthKey);
    final formattedMonth = intl2.DateFormat.yMMM('ar').format(monthDate);

    final filteredStudents = _getFilteredStudents(
      classLeadProvider.classStudents,
    );

    return Scaffold(
      appBar: AppBar(
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة تحكم مسؤول الفصل - ${userName ?? 'المعلم'}',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'الصف: ${widget.className} - الشهر: $formattedMonth',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
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
        child: Column(
          children: [
            // فلتر الشعبة
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedSectionFilter,
                decoration: const InputDecoration(
                  labelText: 'فلتر الشعبة',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                hint: const Text('جميع الشعب'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('جميع الشعب'),
                  ),
                  ..._availableSectionsFilter.map((section) {
                    return DropdownMenuItem(
                      value: section,
                      child: Text(section),
                    );
                  }),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSectionFilter = newValue;
                  });
                },
              ),
            ),

            // رسالة الخطأ أو التحميل
            if (classLeadProvider.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (classLeadProvider.errorMessage != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      classLeadProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (filteredStudents.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'لا يوجد طلاب مسجلون لهذا الصف/الشهر أو لا تملك صلاحية عرضهم.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              // قائمة الطلاب
              Expanded(
                child: Form(
                  key: _formKey, // <--- ربط FormKey هنا
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      // جلب حالة الدفع المحلية للطالب لهذا الشهر
                      final payment =
                          classLeadProvider.localPaymentChanges[student.id];

                      if (payment == null) {
                        // هذا لا ينبغي أن يحدث إذا كان fetchStudentsForClassAndMonth يعمل بشكل صحيح
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${student.studentName} (${student.serialNumber})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              Text(
                                'الصف: ${student.className} - الشعبة: ${student.section}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const Divider(height: 20, thickness: 1),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: payment.isPaid,
                                          onChanged: (bool? newValue) {
                                            classLeadProvider
                                                .updateStudentPaymentStatusLocally(
                                                  student.id,
                                                  newValue ?? false,
                                                );
                                          },
                                          activeColor: Colors.green,
                                        ),
                                        const Text('تم الدفع'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: payment.amount.toStringAsFixed(
                                        2,
                                      ), // <--- استخدام toStringAsFixed(2) لضمان تنسيق الرقم
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        labelText: 'المبلغ',
                                        suffixText: 'ريال',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final amount = double.tryParse(value);
                                        if (amount != null) {
                                          classLeadProvider
                                              .updateStudentPaymentAmountLocally(
                                                student.id,
                                                amount,
                                              );
                                        } else {
                                          // إذا كان الإدخال غير صالح، يمكننا تعيينه إلى 0 أو عرض رسالة خطأ
                                          classLeadProvider
                                              .updateStudentPaymentAmountLocally(
                                                student.id,
                                                0.0,
                                              ); // تعيين قيمة افتراضية أو التعامل مع الخطأ
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'مطلوب';
                                        }
                                        final amount = double.tryParse(value);
                                        if (amount == null ||
                                            amount.isNaN ||
                                            amount.isInfinite) {
                                          return 'رقم غير صالح';
                                        }
                                        if (amount < 0) {
                                          return 'يجب أن يكون موجباً';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // زر حفظ التغييرات
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: classLeadProvider.isLoading
                    ? null
                    : _validateAndSave, // <--- تم التعديل هنا لاستدعاء دالة التحقق الجديدة
                icon: const Icon(Icons.save),
                label: classLeadProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ جميع التغييرات'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // <--- جديد: زر عائم لتحديد/إلغاء تحديد الكل
        onPressed: () {
          final newStatus = !classLeadProvider.areAllStudentsPaid;
          classLeadProvider.toggleAllPaymentsStatus(newStatus);
        },
        backgroundColor: Colors.blueAccent,
        tooltip: classLeadProvider.areAllStudentsPaid
            ? 'إلغاء تحديد الكل'
            : 'تحديد الكل',
        child: Icon(
          classLeadProvider.areAllStudentsPaid
              ? Icons.check_box_outline_blank
              : Icons.check_box,
          color: Colors.white,
        ),
      ),
    );
  }
}
