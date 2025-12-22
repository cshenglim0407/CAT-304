import 'package:flutter/material.dart';

// Income category -> Icon
IconData getIncomeIcon(String? category) {
  switch (category?.toUpperCase()) {
    case 'SALARY':
      return Icons.attach_money;
    case 'BUSINESS':
      return Icons.business;
    case 'GIFT':
      return Icons.card_giftcard;
    case 'INVESTMENT':
      return Icons.trending_up;
    default:
      return Icons.add_circle; // generic income
  }
}

// Expense category -> Icon
IconData getExpenseIcon(String? category) {
  switch (category?.toUpperCase()) {
    case 'FOOD':
      return Icons.restaurant;
    case 'TRANSPORT':
      return Icons.directions_car;
    case 'ENTERTAINMENT':
      return Icons.movie;
    case 'UTILITIES':
      return Icons.electric_bolt;
    case 'HEALTHCARE':
      return Icons.local_hospital;
    case 'SHOPPING':
      return Icons.shopping_bag;
    case 'TRAVEL':
      return Icons.flight_takeoff;
    case 'EDUCATION':
      return Icons.school;
    case 'RENT':
      return Icons.home;
    default:
      return Icons.remove_circle; // generic expense
  }
}

// Account type -> Icon
IconData getAccountTypeIcon(String accountType) {
  switch (accountType.toUpperCase()) {
    case 'CASH':
      return Icons.payments_rounded;
    case 'BANK':
      return Icons.account_balance_rounded;
    case 'E-WALLET':
      return Icons.account_balance_wallet_rounded;
    case 'CREDIT CARD':
      return Icons.credit_card_rounded;
    case 'INVESTMENT':
      return Icons.trending_up_rounded;
    case 'LOAN':
      return Icons.money_off_rounded;
    default:
      return Icons.account_box_rounded;
  }
}
