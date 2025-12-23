import 'package:cashlytics/domain/entities/account_transaction_view.dart';
import 'package:cashlytics/core/utils/date_formatter.dart';

/// Analyzes and formats transactions for the Gemini prompt
class TransactionAnalyzer {
  /// Format transactions summary for Gemini prompt
  static String formatTransactionsSummary(
    List<AccountTransactionView> transactions,
  ) {
    if (transactions.isEmpty) {
      return 'No transactions in the period.';
    }

    // Calculate totals
    final income = transactions
        .where((t) => !t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final expense = transactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final netBalance = income - expense;
    final savingsRate = income > 0 ? (netBalance / income) * 100 : 0;

    final buffer = StringBuffer();

    buffer.writeln('**FINANCIAL SUMMARY:**');
    buffer.writeln('Total Income: \$${income.toStringAsFixed(2)}');
    buffer.writeln('Total Expenses: \$${expense.toStringAsFixed(2)}');
    buffer.writeln('Net Balance: \$${netBalance.toStringAsFixed(2)}');
    buffer.writeln('Savings Rate: ${savingsRate.toStringAsFixed(1)}%');
    buffer.writeln();

    return buffer.toString();
  }

  /// Format detailed transaction list for Gemini prompt
  static String formatTransactionsList(
    List<AccountTransactionView> transactions, {
    int maxTransactions = 50,
  }) {
    if (transactions.isEmpty) {
      return 'No transactions in the period.';
    }

    // Sort by date descending (most recent first)
    final sorted = List<AccountTransactionView>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Limit to maxTransactions to avoid token overflow
    final displayed = sorted.take(maxTransactions).toList();

    // Group by category for better analysis
    final categorized = <String, List<AccountTransactionView>>{};
    for (final tx in displayed) {
      final category = tx.category ?? 'Uncategorized';
      (categorized[category] ??= []).add(tx);
    }

    final buffer = StringBuffer();

    buffer.writeln('**TRANSACTIONS (Last $maxTransactions):**');
    buffer.writeln();

    // Group by category
    for (final category in categorized.keys) {
      final txns = categorized[category]!;
      final categoryTotal = txns.fold<double>(
        0,
        (sum, t) => sum + (t.isExpense ? -t.amount : t.amount),
      );

      buffer.writeln('$category - Total: \$${categoryTotal.toStringAsFixed(2)}');

      // List individual transactions in this category
      for (final (index, tx) in txns.indexed) {
        if (index >= 5) {
          // Limit per category for brevity
          if (txns.length > 5) {
            buffer.writeln('  ... and ${txns.length - 5} more');
          }
          break;
        }

        final sign = tx.isExpense ? '-' : '+';
        final date = DateFormatter.formatDate(tx.date);
        buffer.writeln('  $sign\$${tx.amount.toStringAsFixed(2)} - ${tx.title} ($date)');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get category breakdown summary
  static String getCategoryBreakdown(List<AccountTransactionView> transactions) {
    if (transactions.isEmpty) {
      return 'No category data available.';
    }

    final categorized = <String, double>{};
    for (final tx in transactions) {
      final category = tx.category ?? 'Uncategorized';
      categorized[category] = (categorized[category] ?? 0) + (tx.isExpense ? tx.amount : 0);
    }

    final sorted = categorized.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    buffer.writeln('**SPENDING BY CATEGORY:**');

    for (final entry in sorted) {
      buffer.writeln('- ${entry.key}: \$${entry.value.toStringAsFixed(2)}');
    }

    return buffer.toString();
  }
}
