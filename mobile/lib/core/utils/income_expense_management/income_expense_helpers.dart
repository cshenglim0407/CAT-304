class IncomeExpenseHelpers {
  /// Formats a currency amount as a string with a sign prefix.
  /// Expenses are prefixed with '- ' and income with '+ '.
  static String formatCurrency(double amount, bool isExpense) {
    final sign = isExpense ? '- ' : '+ ';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }
}
