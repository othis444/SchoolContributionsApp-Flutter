// lib/data/models/student_monthly_payment.dart

class StudentMonthlyPayment {
  final bool isPaid;
  final double amount;
  // final String? notes; // <--- تم إزالة حقل الملاحظات

  StudentMonthlyPayment({
    required this.isPaid,
    required this.amount,
    // this.notes, // <--- تم إزالة حقل الملاحظات من المُنشئ
  });

  // Factory constructor لتحويل البيانات من JSON/Map إلى كائن StudentMonthlyPayment
  factory StudentMonthlyPayment.fromJson(Map<String, dynamic> json) {
    return StudentMonthlyPayment(
      isPaid: json['isPaid'] as bool,
      amount: (json['amount'] as num)
          .toDouble(), // قد يكون int أو double في Firestore
      // notes: json['notes'] as String?, // <--- تم إزالة قراءة حقل الملاحظات
    );
  }

  // دالة لتحويل كائن StudentMonthlyPayment إلى JSON/Map لحفظه في Firestore
  Map<String, dynamic> toJson() {
    return {
      'isPaid': isPaid,
      'amount': amount,
      // 'notes': notes, // <--- تم إزالة حفظ حقل الملاحظات
    };
  }

  // دالة copyWith
  StudentMonthlyPayment copyWith({
    bool? isPaid,
    double? amount,
    // String? notes, // <--- تم إزالة حقل الملاحظات من copyWith
  }) {
    return StudentMonthlyPayment(
      isPaid: isPaid ?? this.isPaid,
      amount: amount ?? this.amount,
      // notes: notes ?? this.notes, // <--- تم إزالة حقل الملاحظات من copyWith
    );
  }
}
