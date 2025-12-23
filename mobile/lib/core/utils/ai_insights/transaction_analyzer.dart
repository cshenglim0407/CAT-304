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

    // Exclude transfers from income/expense math
    final nonTransferTx =
        transactions.where((t) => (t.category ?? '').toLowerCase() != 'transfer').toList();

    // Calculate totals
    final income = nonTransferTx
        .where((t) => !t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final expense = nonTransferTx
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

    // Normalize transfers (merge paired in/out and label category)
    final normalized = _mergeTransfers(displayed);

    // Group by category for better analysis
    final categorized = <String, List<_DisplayTx>>{};
    for (final tx in normalized) {
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
        (sum, t) => sum + t.signedAmount,
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

        final sign = tx.signedAmount >= 0 ? '+' : '-';
        final date = DateFormatter.formatDate(tx.date);
        buffer.writeln(
          '  $sign\$${tx.absAmount.toStringAsFixed(2)} - ${tx.title} ($date)',
        );
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

    // Exclude transfers from spending breakdown
    final categorized = <String, double>{};
    for (final tx in transactions) {
      final category = tx.category ?? 'Uncategorized';
      if (category.toLowerCase() == 'transfer') continue;
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

  /// Merge paired transfers (outgoing + incoming) into a single descriptive row
  static List<_DisplayTx> _mergeTransfers(List<AccountTransactionView> txns) {
    final transfers = txns
        .where((t) => (t.category ?? '').toLowerCase() == 'transfer')
        .toList();
    final nonTransfers = txns
        .where((t) => (t.category ?? '').toLowerCase() != 'transfer')
        .map(_DisplayTx.fromTx)
        .toList();

    final outgoing = <AccountTransactionView>[];
    final incoming = <AccountTransactionView>[];
    for (final t in transfers) {
      if (t.isExpense) {
        outgoing.add(t);
      } else {
        incoming.add(t);
      }
    }

    final merged = <_DisplayTx>[];
    final usedIncoming = <int>{};
    final usedOutgoing = <int>{};

    for (int outIdx = 0; outIdx < outgoing.length; outIdx++) {
      final out = outgoing[outIdx];
      final matchIndex = incoming.indexWhere((inn) {
        final innIdx = incoming.indexOf(inn);
        if (usedIncoming.contains(innIdx)) return false;
        final sameAmount = (inn.amount - out.amount).abs() < 0.01;
        final withinDay = inn.date.difference(out.date).inDays.abs() <= 1;
        return sameAmount && withinDay;
      });

      if (matchIndex != -1) {
        final inn = incoming[matchIndex];
        usedIncoming.add(matchIndex);
        usedOutgoing.add(outIdx);

        final fromName = _extractName(inn.title, 'Transfer from ');
        final toName = _extractName(out.title, 'Transfer to ');

        merged.add(
          _DisplayTx(
            title: 'Transfer from $fromName to $toName',
            date: inn.date.isAfter(out.date) ? inn.date : out.date,
            signedAmount: 0,
            category: 'Transfer',
          ),
        );
      }
    }

    // Any leftover transfers that couldn't be paired
    for (int i = 0; i < incoming.length; i++) {
      if (usedIncoming.contains(i)) continue;
      merged.add(_DisplayTx.fromTx(incoming[i]));
    }
    for (int i = 0; i < outgoing.length; i++) {
      if (usedOutgoing.contains(i)) continue;
      merged.add(_DisplayTx.fromTx(outgoing[i]));
    }

    return [...nonTransfers, ...merged]..sort((a, b) => b.date.compareTo(a.date));
  }

  static String _extractName(String title, String prefix) {
    if (title.startsWith(prefix)) {
      return title.substring(prefix.length).trim().isEmpty
          ? 'Account'
          : title.substring(prefix.length).trim();
    }
    return title;
  }
}

class _DisplayTx {
  _DisplayTx({
    required this.title,
    required this.date,
    required this.signedAmount,
    this.category,
  });

  final String title;
  final DateTime date;
  final double signedAmount;
  final String? category;

  double get absAmount => signedAmount.abs();

  static _DisplayTx fromTx(AccountTransactionView tx) {
    final amount = tx.isExpense ? -tx.amount : tx.amount;
    return _DisplayTx(
      title: tx.title,
      date: tx.date,
      signedAmount: amount,
      category: tx.category,
    );
  }
}
