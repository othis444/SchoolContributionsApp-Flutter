// lib/data/models/student_monthly_payment.dart

class StudentMonthlyPayment {
  final bool isPaid; // هل تم الدفع؟
  final double amount; // مبلغ الدفع
  final String? notes; // ملاحظات حول الدفعة

  StudentMonthlyPayment({
    required this.isPaid,
    this.amount = 1000.0, // القيمة الافتراضية
    this.notes,
  });

  // Factory constructor لتحويل البيانات من JSON/Map إلى كائن StudentMonthlyPayment
  factory StudentMonthlyPayment.fromJson(Map<String, dynamic> json) {
    return StudentMonthlyPayment(
      isPaid: json['isPaid'] as bool? ?? false,
      amount: (json['amount'] as num?)?.toDouble() ?? 1000.0,
      notes: json['notes'] as String?,
    );
  }

  // دالة لتحويل كائن StudentMonthlyPayment إلى JSON/Map لحفظه في Firestore
  Map<String, dynamic> toJson() {
    return {'isPaid': isPaid, 'amount': amount, 'notes': notes};
  }
}
