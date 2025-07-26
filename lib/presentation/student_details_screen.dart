// lib/presentation/student_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/data/models/student_monthly_payment.dart';
import 'package:school_contributions_app/presentation/providers/admin_dashboard_provider.dart';
import 'package:intl/intl.dart' as intl2; // For date formatting
// For debugPrint

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Map to hold local changes to monthly payments for this specific student
  final Map<String, StudentMonthlyPayment> _localMonthlyPaymentChanges = {};

  // Controllers for each month's amount field
  final Map<String, TextEditingController> _amountControllers = {};

  @override
  void initState() {
    super.initState();
    // No need to add a listener to AdminDashboardProvider here,
    // as we'll use Consumer in the build method.
    // The provider's allStudents list will be updated by its own listener.
  }

  // This method will be called to initialize controllers and local changes
  // It's called in build to ensure it reacts to provider updates.
  void _initializePaymentData(Student student) {
    // Clear existing controllers and local changes to re-initialize
    _amountControllers.forEach((key, controller) => controller.dispose());
    _amountControllers.clear();
    _localMonthlyPaymentChanges.clear();

    if (student.monthlyPayments.isNotEmpty) {
      student.monthlyPayments.forEach((monthKey, payment) {
        _localMonthlyPaymentChanges[monthKey] = payment;
        _amountControllers[monthKey] = TextEditingController(
          text: payment.amount.toStringAsFixed(2),
        );
      });
    } else {
      // If no payments exist, initialize for current month as a default
      final currentMonthKey = intl2.DateFormat(
        'yyyy-MM',
      ).format(DateTime.now());
      _localMonthlyPaymentChanges[currentMonthKey] = StudentMonthlyPayment(
        isPaid: false,
        amount: 1000.0,
      );
      _amountControllers[currentMonthKey] = TextEditingController(
        text: '1000.00',
      );
    }
  }

  void _updateLocalPaymentStatus(String monthKey, bool isPaid) {
    setState(() {
      final currentPayment = _localMonthlyPaymentChanges[monthKey];
      if (currentPayment != null) {
        _localMonthlyPaymentChanges[monthKey] = currentPayment.copyWith(
          isPaid: isPaid,
        );
      }
    });
  }

  void _updateLocalPaymentAmount(String monthKey, double amount) {
    setState(() {
      final currentPayment = _localMonthlyPaymentChanges[monthKey];
      if (currentPayment != null) {
        _localMonthlyPaymentChanges[monthKey] = currentPayment.copyWith(
          amount: amount,
        );
      }
    });
  }

  Future<void> _saveStudentPayments() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تصحيح الأخطاء في الحقول قبل الحفظ.'),
        ),
      );
      return;
    }

    final adminProvider = Provider.of<AdminDashboardProvider>(
      context,
      listen: false,
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Get the current student from the provider's list
    final student = adminProvider.allStudents.firstWhere(
      (s) => s.id == widget.studentId,
      orElse: () => throw Exception('Student not found for update.'),
    );

    // Create a new student object with updated monthly payments
    final updatedStudent = student.copyWith(
      monthlyPayments: Map.from(student.monthlyPayments)
        ..addAll(_localMonthlyPaymentChanges),
    );

    try {
      // Use the existing updateStudentData to save the whole student object
      await adminProvider.updateStudent(updatedStudent);
      if (adminProvider.errorMessage == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('تم حفظ الدفعات بنجاح!')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(adminProvider.errorMessage!)),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل حفظ الدفعات: $e')),
      );
    }
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers to prevent memory leaks
    _amountControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطالب')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<AdminDashboardProvider>(
          builder: (context, adminProvider, child) {
            if (adminProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Find the student based on studentId
            final student = adminProvider.allStudents.firstWhere(
              (s) => s.id == widget.studentId,
              orElse: () => Student(
                // Return a dummy student if not found
                id: widget.studentId,
                serialNumber: '',
                studentName: 'الطالب غير موجود',
                className: '',
                gender: '',
                section: '',
                classLeadId: '',
                classLeadName: '',
                monthlyPayments: {},
              ),
            );

            // Re-initialize payment data and controllers whenever student data changes
            // This ensures the UI is always in sync with the latest data from the provider
            _initializePaymentData(student);

            // Sort months for display (latest month first)
            final sortedMonthKeys = _localMonthlyPaymentChanges.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            if (student.id == widget.studentId &&
                student.studentName == 'الطالب غير موجود') {
              return const Center(
                child: Text(
                  'الطالب غير موجود أو تم حذفه.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return Column(
              children: [
                // Student general info card
                Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 4,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'الصف: ${student.className} - الشعبة: ${student.section}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'الجنس: ${student.gender}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'معلم الفصل: ${student.classLeadName ?? 'غير معروف'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'سجل الدفعات الشهرية:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),

                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: sortedMonthKeys.length,
                      itemBuilder: (context, index) {
                        final monthKey = sortedMonthKeys[index];
                        final payment = _localMonthlyPaymentChanges[monthKey]!;
                        final formattedMonth = intl2.DateFormat.yMMM(
                          'ar',
                        ).format(intl2.DateFormat('yyyy-MM').parse(monthKey));

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الشهر: $formattedMonth',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: payment.isPaid,
                                            onChanged: (bool? newValue) {
                                              _updateLocalPaymentStatus(
                                                monthKey,
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
                                        controller:
                                            _amountControllers[monthKey],
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
                                            _updateLocalPaymentAmount(
                                              monthKey,
                                              amount,
                                            );
                                          } else {
                                            _updateLocalPaymentAmount(
                                              monthKey,
                                              0.0,
                                            );
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _saveStudentPayments,
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ التغييرات'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
