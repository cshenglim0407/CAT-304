import 'package:flutter/material.dart';

@immutable
class AccountTransactionView {
  const AccountTransactionView({
    required this.transactionId,
    required this.title,
    required this.date,
    required this.amount,
    required this.isExpense,
    this.icon,
    this.category,
    this.description,
  });

  final String transactionId;
  final String title;
  final DateTime date;
  final double amount;
  final bool isExpense;
  final IconData? icon;
  final String? category;
  final String? description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountTransactionView &&
        other.transactionId == transactionId &&
        other.title == title &&
        other.date == date &&
        other.amount == amount &&
        other.isExpense == isExpense &&
        other.icon == icon &&
        other.category == category &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(transactionId, title, date, amount, isExpense, icon, category, description);
  }

  @override
  String toString() {
    return 'AccountTransactionView(id: $transactionId, title: $title, amount: $amount, isExpense: $isExpense)';
  }
}
