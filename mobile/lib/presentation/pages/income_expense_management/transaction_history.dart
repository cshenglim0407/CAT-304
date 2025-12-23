import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String accountName;
  final List<Map<String, dynamic>> transactions;
  final Function(Map<String, dynamic>) onDelete; 
  final Function(Map<String, dynamic>) onEdit; 

  const TransactionHistoryPage({
    super.key,
    required this.accountName,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      appBar: AppBar(
        title: Text(
          "${widget.accountName} History",
          style: AppTypography.headline3.copyWith(color: AppColors.getTextPrimary(context)),
        ),
        backgroundColor: AppColors.getSurface(context),
        foregroundColor: AppColors.getTextPrimary(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: widget.transactions.isEmpty
          ? Center(
              child: Text(
                "No history available",
                style: AppTypography.bodySmall.copyWith(color: AppColors.greyText),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: widget.transactions.length,
              // UPDATED: Use SizedBox instead of Divider to remove lines
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final tx = widget.transactions[index];
                final isExpense = tx['isExpense'] ?? false;
                final isRecurrent = tx['isRecurrent'] ?? false;

                return ListTile(
                  // Removes default internal padding so it aligns with your custom design
                  contentPadding: EdgeInsets.zero, 
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: isExpense 
                        ? Colors.black.withOpacity(0.05) 
                        : AppColors.success.withOpacity(0.1),
                    child: Icon(
                      tx['icon'], 
                      color: isExpense ? Colors.black : AppColors.success,
                      size: 20
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        tx['title'], 
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)
                      ),
                      if (isRecurrent) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.repeat, size: 14, color: AppColors.greyText),
                      ]
                    ],
                  ),
                  subtitle: Text(
                    tx['date'], 
                    style: AppTypography.bodySmall.copyWith(color: AppColors.greyText)
                  ),
                  trailing: Text(
                    tx['amount'],
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isExpense ? Colors.black : AppColors.success,
                    ),
                  ),
                  onTap: () => _showActionSheet(context, tx),
                );
              },
            ),
    );
  }

  void _showActionSheet(BuildContext context, Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              width: 40, height: 4, 
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Edit Transaction"),
              onTap: () {
                Navigator.pop(ctx);
                widget.onEdit(tx);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Transaction"),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDelete(tx);
                setState(() {});
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}