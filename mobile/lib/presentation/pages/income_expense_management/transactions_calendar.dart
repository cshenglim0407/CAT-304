import 'package:cashlytics/core/utils/date_formatter.dart';
import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:flutter_neat_and_clean_calendar/flutter_neat_and_clean_calendar.dart';

class TransactionsCalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;
  final List<List<Map<String, dynamic>>> allTransactions;
  final void Function(Map<String, dynamic> tx, int accountIndex) onDelete;
  final void Function(Map<String, dynamic> tx, int accountIndex) onEdit;

  const TransactionsCalendarPage({
    super.key,
    required this.accounts,
    required this.allTransactions,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TransactionsCalendarPage> createState() =>
      _TransactionsCalendarPageState();
}

class _TransactionsCalendarPageState extends State<TransactionsCalendarPage> {
  late DateTime _selectedDate;
  late final List<NeatCleanCalendarEvent> _events;
  final List<Color> _palette = const [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _events = _buildEvents();
  }

  Color _colorForAccount(int index) => _palette[index % _palette.length];

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime? _extractDate(Map<String, dynamic> tx) {
    final raw = tx['rawDate'];
    if (raw is DateTime) return _dateOnly(raw);
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return _dateOnly(parsed);
    }

    final dateStr = (tx['date'] ?? '').toString();
    if (dateStr.isEmpty) return null;

    final now = DateTime.now();
    final today = _dateOnly(now);

    if (dateStr.toLowerCase() == 'today') return today;
    if (dateStr.toLowerCase() == 'yesterday') {
      return today.subtract(const Duration(days: 1));
    }

    if (dateStr.contains('/')) {
      final parts = dateStr.split('/');
      if (parts.length >= 2) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = parts.length >= 3 ? int.tryParse(parts[2]) : now.year;
        if (day != null && month != null && year != null) {
          return _dateOnly(DateTime(year, month, day));
        }
      }
    }
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Map<String, dynamic>> _transactionsForSelectedDate() {
    final DateTime target = _dateOnly(_selectedDate);
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < widget.allTransactions.length; i++) {
      final txList = widget.allTransactions[i];
      for (final tx in txList) {
        final txDate = _extractDate(tx);
        if (txDate != null && _isSameDay(txDate, target)) {
          final merged = Map<String, dynamic>.from(tx);
          merged['accountIndex'] = i;
          merged['accountName'] = widget.accounts[i]['name'];
          result.add(merged);
        }
      }
    }
    return result;
  }

  double _parseAmount(Map<String, dynamic> tx) {
    final raw = tx['rawAmount'];
    if (raw is num) return raw.toDouble();
    final amtStr = (tx['amount'] ?? '').toString();
    final cleaned = amtStr.replaceAll(RegExp(r"[^0-9\.-]"), "");
    return double.tryParse(cleaned) ?? 0.0;
  }

  double _sumBy(bool isExpense) {
    final items = _transactionsForSelectedDate().where(
      (tx) => (tx['isExpense'] ?? false) == isExpense,
    );
    double total = 0.0;
    for (final tx in items) {
      total += _parseAmount(tx);
    }
    return total;
  }

  List<NeatCleanCalendarEvent> _buildEvents() {
    final List<NeatCleanCalendarEvent> events = [];
    for (int i = 0; i < widget.allTransactions.length; i++) {
      final color = _colorForAccount(i);
      final txList = widget.allTransactions[i];
      for (final tx in txList) {
        final date = _extractDate(tx);
        if (date == null) continue;
        events.add(
          NeatCleanCalendarEvent(
            tx['title']?.toString() ?? 'Transaction',
            description: (tx['amount'] ?? '').toString(),
            startTime: date,
            endTime: date.add(const Duration(minutes: 1)),
            color: color,
            isAllDay: true,
          ),
        );
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final dayTransactions = _transactionsForSelectedDate();
    final expenseTotal = _sumBy(true);
    final incomeTotal = _sumBy(false);

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      appBar: AppBar(
        title: Text(
          "Transactions Calendar",
          style: AppTypography.headline3.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.getSurface(context),
        foregroundColor: AppColors.getTextPrimary(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              color: AppColors.greyLight.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Calendar(
                  startOnMonday: false,
                  initialDate: _selectedDate,
                  isExpanded: true,
                  selectedColor: AppColors.primary,
                  todayColor: AppColors.primary.withValues(alpha: 0.2),
                  eventDoneColor: AppColors.primary,
                  eventsList: _events,
                  locale: 'en_US',
                  dayOfWeekStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.getTextPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                  onDateSelected: (date) =>
                      setState(() => _selectedDate = date),
                  eventListBuilder: (_, _) => const SizedBox.shrink(),
                  dayBuilder: (BuildContext context, DateTime day) {
                    final isSelected = _isSameDay(day, _selectedDate);
                    final dayEvents = _events
                        .where((event) => _isSameDay(event.startTime, day))
                        .toList();
                    return Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: isSelected
                          ? BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.getTextPrimary(context),
                            ),
                          ),
                          if (dayEvents.isNotEmpty) const SizedBox(height: 2.0),
                          if (dayEvents.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: dayEvents.take(4).map((event) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  width: 5.0,
                                  height: 5.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white
                                        : event.color,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.formatDateDDMMYYYY(_selectedDate),
                  style: AppTypography.headline2.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                Row(
                  children: [
                    _SummaryChip(
                      label: "+ ${MathFormatter.formatCurrency(incomeTotal)}",
                      color: AppColors.success.withValues(alpha: 0.12),
                      textColor: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _SummaryChip(
                      label: "- ${MathFormatter.formatCurrency(expenseTotal)}",
                      color: Colors.black.withValues(alpha: 0.06),
                      textColor: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: dayTransactions.isEmpty
                ? Center(
                    child: Text(
                      "No transactions on this day",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.greyText,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: dayTransactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final tx = dayTransactions[index];
                      final isExpense = tx['isExpense'] ?? false;
                      final isRecurrent = tx['isRecurrent'] ?? false;
                      final accIdx = tx['accountIndex'] as int? ?? 0;
                      final accColor = _colorForAccount(accIdx);
                      final accName =
                          tx['accountName']?.toString() ?? 'Account';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: isExpense
                              ? Colors.black.withValues(alpha: 0.05)
                              : AppColors.success.withValues(alpha: 0.1),
                          child: Icon(
                            tx['icon'],
                            color: isExpense ? Colors.black : AppColors.success,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            // account color dot
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: accColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              tx['title'],
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isRecurrent) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.repeat,
                                size: 14,
                                color: AppColors.greyText,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              tx['date'],
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.greyText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _SummaryChip(
                              label: accName,
                              color: accColor.withValues(alpha: 0.12),
                              textColor: accColor,
                            ),
                          ],
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
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Edit Transaction"),
              onTap: () {
                Navigator.pop(ctx);
                final idx = (tx['accountIndex'] as int?) ?? 0;
                widget.onEdit(tx, idx);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Transaction"),
              onTap: () {
                Navigator.pop(ctx);
                final idx = (tx['accountIndex'] as int?) ?? 0;
                widget.onDelete(tx, idx);
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

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
