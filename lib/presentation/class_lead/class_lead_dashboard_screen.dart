// lib/presentation/class_lead/class_lead_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl2; // لاستخدام DateFormat لتنسيق التاريخ
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
import 'package:school_contributions_app/presentation/providers/class_lead_provider.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/data/models/student_monthly_payment.dart';

class ClassLeadDashboardScreen extends StatefulWidget {
  const ClassLeadDashboardScreen({super.key});

  @override
  State<ClassLeadDashboardScreen> createState() =>
      _ClassLeadDashboardScreenState();
}

class _ClassLeadDashboardScreenState extends State<ClassLeadDashboardScreen> {
  // مفتاح FormState للتحقق من صحة حقول الإدخال إذا لزم الأمر
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // هنا يمكننا جلب بيانات المعلم (مثل الصفوف المخصصة) إذا لم تكن موجودة في AuthProvider
    // ولكن ClassLeadProvider يستمع بالفعل لتغيرات المصادقة ويقوم بجلب الطلاب.
  }

  // دالة لعرض منتقي الشهر والسنة
  Future<void> _selectMonth(
    BuildContext context,
    ClassLeadProvider provider,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = intl2.DateFormat(
      'yyyy-MM',
    ).parse(provider.selectedMonthKey);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5), // 5 سنوات سابقة
      lastDate: DateTime(now.year + 1), // سنة قادمة
      initialEntryMode:
          DatePickerEntryMode.calendarOnly, // لإجبار عرض التقويم فقط
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl, // لضمان اتجاه RTL في منتقي التاريخ
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setSelectedMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع إلى AuthProvider للحصول على معلومات المستخدم (مثل الدور واسم المستخدم)
    final authProvider = Provider.of<AuthProvider>(context);
    // الاستماع إلى ClassLeadProvider لجلب وعرض بيانات الطلاب
    final classLeadProvider = Provider.of<ClassLeadProvider>(context);

    // الحصول على اسم المستخدم الحالي (المعلم)
    final String? userName = authProvider.currentUser?.email
        ?.split('@')
        .first; // مثال: استخدام جزء من البريد الإلكتروني كاسم

    return Scaffold(
      appBar: AppBar(
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'لوحة تحكم مسؤول الفصل - ${userName ?? 'المعلم'}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              // GoRouter سيتعامل مع إعادة التوجيه إلى شاشة تسجيل الدخول
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // محدد الشهر
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () {
                          final currentMonth = intl2.DateFormat(
                            'yyyy-MM',
                          ).parse(classLeadProvider.selectedMonthKey);
                          classLeadProvider.setSelectedMonth(
                            DateTime(currentMonth.year, currentMonth.month - 1),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () => _selectMonth(context, classLeadProvider),
                        child: Row(
                          children: [
                            Text(
                              intl2.DateFormat.yMMM('ar').format(
                                intl2.DateFormat(
                                  'yyyy-MM',
                                ).parse(classLeadProvider.selectedMonthKey),
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 20),
                        onPressed: () {
                          final currentMonth = intl2.DateFormat(
                            'yyyy-MM',
                          ).parse(classLeadProvider.selectedMonthKey);
                          classLeadProvider.setSelectedMonth(
                            DateTime(currentMonth.year, currentMonth.month + 1),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // رسالة الخطأ أو التحميل
            if (classLeadProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else if (classLeadProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  classLeadProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            else if (classLeadProvider.classStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'لا يوجد طلاب مسجلون لهذا الفصل حتى الآن.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              // قائمة الطلاب
              Expanded(
                child: Form(
                  // استخدام Form لتجميع حقول الإدخال
                  key: _formKey,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: classLeadProvider.classStudents.length,
                    itemBuilder: (context, index) {
                      final student = classLeadProvider.classStudents[index];
                      // الحصول على تفاصيل الدفعة للشهر المحدد، أو إنشاء دفعة افتراضية
                      final currentPayment =
                          student.monthlyPayments[classLeadProvider
                              .selectedMonthKey] ??
                          StudentMonthlyPayment(
                            isPaid: false,
                            amount: 1000.0,
                            notes: '',
                          );

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
                                          value: currentPayment.isPaid,
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
                                      initialValue: currentPayment.amount
                                          .toString(),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        labelText: 'المبلغ',
                                        suffixText: 'ريال', // عملة افتراضية
                                        isDense: true, // لتقليل الارتفاع
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        classLeadProvider
                                            .updateStudentPaymentAmountLocally(
                                              student.id,
                                              double.tryParse(value) ?? 0.0,
                                            );
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'مطلوب';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'رقم غير صالح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: currentPayment.notes,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  labelText: 'ملاحظات',
                                  hintText: 'أضف أي ملاحظات...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                ),
                                onChanged: (value) {
                                  classLeadProvider
                                      .updateStudentPaymentNotesLocally(
                                        student.id,
                                        value,
                                      );
                                },
                                maxLines: 2,
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
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await classLeadProvider.saveAllChanges();
                          if (classLeadProvider.errorMessage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حفظ التغييرات بنجاح!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(classLeadProvider.errorMessage!),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.save),
                label: classLeadProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ جميع التغييرات'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // زر بعرض كامل
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
    );
  }
}
