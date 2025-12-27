class RecurrentIncomeItem {
  const RecurrentIncomeItem({
    required this.transactionId,
    required this.accountId,
    required this.accountName,
    required this.title,
    required this.amount,
    required this.isRecurrent,
    required this.createdAt,
    this.category,
    this.description,
  });

  final String transactionId;
  final String accountId;
  final String accountName;
  final String title;
  final double amount;
  final bool isRecurrent;
  final DateTime createdAt;
  final String? category;
  final String? description;

  RecurrentIncomeItem copyWith({bool? isRecurrent}) {
    return RecurrentIncomeItem(
      transactionId: transactionId,
      accountId: accountId,
      accountName: accountName,
      title: title,
      amount: amount,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      createdAt: createdAt,
      category: category,
      description: description,
    );
  }
}
