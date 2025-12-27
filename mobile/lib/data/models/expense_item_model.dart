import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/domain/entities/expense_item.dart';

/// Data model for individual expense items on a receipt.
class ExpenseItemModel extends ExpenseItem {
  const ExpenseItemModel({
    required super.transactionId,
    required super.itemId,
    super.itemName,
    super.quantity = 1,
    super.unitPrice = 0,
    super.price = 0,
  });

  factory ExpenseItemModel.fromEntity(ExpenseItem entity) {
    return ExpenseItemModel(
      transactionId: entity.transactionId,
      itemId: entity.itemId,
      itemName: entity.itemName,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      price: entity.price,
    );
  }

  factory ExpenseItemModel.fromMap(Map<String, dynamic> map) {
    return ExpenseItemModel(
      transactionId: map['transaction_id'] as String? ?? '',
      itemId: map['item_id'] as int? ?? 0,
      itemName: map['item_name'] as String?,
      quantity: map['qty'] as int? ?? 1,
      unitPrice: MathFormatter.parseDouble(map['unit_price']) ?? 0.0,
      price: MathFormatter.parseDouble(map['price']) ?? 0.0,
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'transaction_id': transactionId,
      'item_id': itemId,
      'item_name': itemName,
      'qty': quantity,
      'unit_price': unitPrice,
      'price': price,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();
}
