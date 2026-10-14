class FarmExpense {
  final int? id;
  final int? farmId;
  final int? cropId;
  final String title;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String paymentMethod;
  final String notes;
  final DateTime createdAt;

  const FarmExpense({
    this.id,
    this.farmId,
    this.cropId,
    required this.title,
    this.category = 'Other',
    required this.amount,
    required this.expenseDate,
    this.paymentMethod = 'Cash',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'farmId': farmId,
        'cropId': cropId,
        'title': title,
        'category': category,
        'amount': amount,
        'expenseDate': expenseDate.toIso8601String(),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FarmExpense.fromMap(Map<String, dynamic> map) {
    return FarmExpense(
      id: map['id'] as int?,
      farmId: map['farmId'] as int?,
      cropId: map['cropId'] as int?,
      title: map['title'] as String,
      category: (map['category'] as String?) ?? 'Other',
      amount: (map['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(map['expenseDate'] as String),
      paymentMethod: (map['paymentMethod'] as String?) ?? 'Cash',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
