import 'package:meta/meta.dart';

@immutable
class ExpenseItem {
  const ExpenseItem({
    required this.transactionId,
    required this.itemId,
    this.itemName,
    this.quantity = 1,
    this.unitPrice = 0,
    this.price = 0,
  });

  final String transactionId;
  final int itemId;
  final String? itemName;
  final int quantity;
  final double unitPrice;
  final double price;

  ExpenseItem copyWith({
    String? transactionId,
    int? itemId,
    String? itemName,
    int? quantity,
    double? unitPrice,
    double? price,
  }) {
    return ExpenseItem(
      transactionId: transactionId ?? this.transactionId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseItem &&
        other.transactionId == transactionId &&
        other.itemId == itemId &&
        other.itemName == itemName &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(
        transactionId,
        itemId,
        itemName,
        quantity,
        unitPrice,
        price,
      );
}
