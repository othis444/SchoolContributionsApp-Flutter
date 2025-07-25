// lib/presentation/student_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl2; // لاستخدام DateFormat لتنسيق التاريخ
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/presentation/providers/admin_dashboard_provider.dart'; // يمكن استخدام هذا المزود لجلب الطلاب
import 'package:school_contributions_app/data/models/student_monthly_payment.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String studentId; // ID الطالب الذي سيتم عرض تفاصيله

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Student? _student;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // نستخدم AdminDashboardProvider لجلب قائمة الطلاب، ثم نبحث عن الطالب المحدد
      final provider = Provider.of<AdminDashboardProvider>(
        context,
        listen: false,
      );

      // ننتظر قليلاً إذا كانت البيانات لا تزال قيد التحميل في المزود
      // أو يمكننا استخدام StreamBuilder في الـ build method للاستماع للتغييرات
      // ولكن للتبسيط، سنفترض أن البيانات ستكون متاحة قريباً.
      // الطريقة الأفضل هي أن يكون لدى المزود دالة 'getStudentById'
      // حالياً، سنبحث في القائمة الموجودة.

      // بما أن AdminDashboardProvider يقوم بالاستماع للطلاب، يمكننا ببساطة
      // البحث في قائمة allStudents الخاصة به.
      // إذا لم يكن الطالب موجودًا فورًا، يمكننا إضافة منطق لإعادة المحاولة أو عرض رسالة.

      // يمكننا أيضاً الاستماع إلى تغييرات allStudents في المزود
      // ولكن لضمان أننا نحصل على أحدث البيانات فورًا، يمكننا إعادة جلبها أو الاعتماد على Stream
      // For simplicity, we'll try to find it directly after a short delay if needed.

      // A more robust way would be to have a direct method in StudentRepository
      // or AdminDashboardProvider to get a single student by ID,
      // and potentially listen to it. For now, we'll search the existing list.

      // We'll add a listener to the provider to react to changes in allStudents
      // and update our local _student variable.
      provider.addListener(_onProviderChange);
      _onProviderChange(); // Call once initially
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل جلب تفاصيل الطالب: $e';
        _isLoading = false;
      });
    }
  }

  void _onProviderChange() {
    final provider = Provider.of<AdminDashboardProvider>(
      context,
      listen: false,
    );
    final foundStudent = provider.allStudents.firstWhere(
      (s) => s.id == widget.studentId,
      orElse: () => Student(
        id: '',
        serialNumber: '',
        studentName: '',
        className: '',
        gender: '',
        section: '',
        classLeadId: '',
      ), // Return a dummy student if not found
    );

    if (foundStudent.id.isNotEmpty && foundStudent.id == widget.studentId) {
      setState(() {
        _student = foundStudent;
        _isLoading = false;
        _errorMessage = null;
      });
    } else if (!provider.isLoading &&
        provider.errorMessage != null &&
        _student == null) {
      setState(() {
        _errorMessage = provider.errorMessage;
        _isLoading = false;
      });
    } else if (!provider.isLoading && _student == null) {
      setState(() {
        _errorMessage = 'لم يتم العثور على الطالب.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // إزالة المستمع لتجنب تسرب الذاكرة
    Provider.of<AdminDashboardProvider>(
      context,
      listen: false,
    ).removeListener(_onProviderChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطالب')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطالب')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطالب')),
        body: const Center(
          child: Text(
            'لا يمكن عرض تفاصيل الطالب. البيانات غير متوفرة.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // فرز الدفعات حسب الشهر (من الأحدث إلى الأقدم)
    final sortedPaymentsKeys = _student!.monthlyPayments.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // فرز تنازلي (أحدث شهر أولاً)

    return Scaffold(
      appBar: AppBar(
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Text('تفاصيل الطالب: ${_student!.studentName}'),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
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
                        'معلومات الطالب',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(height: 20, thickness: 1),
                      _buildInfoRow('الرقم التسلسلي:', _student!.serialNumber),
                      _buildInfoRow('اسم الطالب:', _student!.studentName),
                      _buildInfoRow(
                        'الصف:',
                        '${_student!.className} - الشعبة: ${_student!.section}',
                      ),
                      _buildInfoRow('الجنس:', _student!.gender),
                      _buildInfoRow(
                        'معلم الفصل:',
                        _student!.classLeadName ?? 'غير معروف',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'سجل الدفعات الشهرية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 20, thickness: 1),
              if (sortedPaymentsKeys.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'لا توجد دفعات مسجلة لهذا الطالب حتى الآن.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true, // مهم داخل SingleChildScrollView
                  physics:
                      const NeverScrollableScrollPhysics(), // لمنع التمرير المزدوج
                  itemCount: sortedPaymentsKeys.length,
                  itemBuilder: (context, index) {
                    final monthKey = sortedPaymentsKeys[index];
                    final payment = _student!.monthlyPayments[monthKey]!;

                    // تحويل مفتاح الشهر (YYYY-MM) إلى تنسيق عربي قابل للقراءة
                    final monthDate = intl2.DateFormat(
                      'yyyy-MM',
                    ).parse(monthKey);
                    final formattedMonth = intl2.DateFormat.yMMM(
                      'ar',
                    ).format(monthDate);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedMonth,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPaymentRow(
                              'حالة الدفع:',
                              payment.isPaid ? 'مدفوع' : 'غير مدفوع',
                              payment.isPaid ? Colors.green : Colors.red,
                            ),
                            _buildPaymentRow(
                              'المبلغ:',
                              '${payment.amount.toStringAsFixed(2)} ريال',
                              Colors.deepPurple,
                            ),
                            if (payment.notes != null &&
                                payment.notes!.isNotEmpty)
                              _buildPaymentRow(
                                'الملاحظات:',
                                payment.notes!,
                                Colors.grey.shade700,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء صفوف المعلومات
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء صفوف الدفعات
  Widget _buildPaymentRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 15, color: color)),
          ),
        ],
      ),
    );
  }
}
