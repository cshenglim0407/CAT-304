import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart'; 
import 'package:cashlytics/presentation/widgets/account_card.dart'; 

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 1; 
  int _currentCardIndex = 0; 
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- MOCK DATA ---
  // Using a Growable list so we can remove items
  final List<Map<String, dynamic>> _myAccounts = [
    {
      'id': '1',
      'name': 'Maybank Savings',
      'type': 'BANK',
      'initial': 1000.00,
      'current': 3450.50,
      'desc': 'Primary salary account',
    },
    {
      'id': '2',
      'name': 'Touch n Go',
      'type': 'E-WALLET',
      'initial': 50.00,
      'current': 12.40,
      'desc': 'For tolls and parking',
    },
    {
      'id': '3',
      'name': 'Emergency Cash',
      'type': 'CASH',
      'initial': 500.00,
      'current': 450.00,
      'desc': 'Stashed in safe', 
    },
  ];

  final List<List<Map<String, dynamic>>> _allTransactions = [
    [
      {'title': 'Salary', 'date': '01 Mar', 'amount': '+ \$3,500', 'isExpense': false, 'icon': Icons.work},
      {'title': 'Transfer to TNG', 'date': '02 Mar', 'amount': '- \$50', 'isExpense': true, 'icon': Icons.account_balance_wallet},
      {'title': 'Netflix Sub', 'date': '28 Feb', 'amount': '- \$12', 'isExpense': true, 'icon': Icons.movie},
    ],
    [
      {'title': 'Toll Payment', 'date': '05 Mar', 'amount': '- \$4.50', 'isExpense': true, 'icon': Icons.directions_car},
      {'title': 'Reload from Bank', 'date': '02 Mar', 'amount': '+ \$50', 'isExpense': false, 'icon': Icons.add_card},
      {'title': '7-Eleven', 'date': '01 Mar', 'amount': '- \$8.20', 'isExpense': true, 'icon': Icons.local_convenience_store},
    ],
    [
      {'title': 'Lunch', 'date': 'Today', 'amount': '- \$15', 'isExpense': true, 'icon': Icons.fastfood},
      {'title': 'Found cash', 'date': 'Yesterday', 'amount': '+ \$10', 'isExpense': false, 'icon': Icons.attach_money},
    ],
  ];

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) Navigator.pushReplacementNamed(context, '/dashboard'); 
    else if (index == 2) Navigator.pushReplacementNamed(context, '/profile'); 
  }

  // --- LOGIC: Delete Account ---
  void _deleteAccount(Map<String, dynamic> account) {
    // 1. Find the index of the account to delete
    int indexToRemove = _myAccounts.indexOf(account);
    if (indexToRemove == -1) return;

    setState(() {
      // 2. Remove the account and its transactions
      _myAccounts.removeAt(indexToRemove);
      _allTransactions.removeAt(indexToRemove);

      // 3. Adjust the current card index safely
      // If we deleted the last item, move index back by one.
      // If the list is empty, index becomes 0.
      if (_currentCardIndex >= _myAccounts.length) {
        _currentCardIndex = _myAccounts.isNotEmpty ? _myAccounts.length - 1 : 0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${account['name']} deleted")),
    );
  }

  // --- LOGIC: Confirm Dialog ---
  void _confirmDelete(BuildContext context, Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text("Are you sure you want to remove '${account['name']}'? This cannot be undone."),
        actions: [
          TextButton(
            child: const Text("Cancel"), 
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(ctx); // Close Dialog
              _deleteAccount(account); // Perform Delete
            },
          ),
        ],
      ),
    );
  }

  // --- UI: Edit Menu ---
  void _showEditOptions(BuildContext context, Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                "Manage ${account['name']}",
                style: AppTypography.headline3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.blue),
                ),
                title: const Text("Edit Account", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Change name, balance, or type"),
                onTap: () {
                  Navigator.pop(context);
                  // Edit logic here
                },
              ),
              
              const Divider(),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text("Delete Account", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Remove this account permanently"),
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  _confirmDelete(context, account); // Show Confirmation
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safety check: if empty, show no transactions
    final currentTransactions = _myAccounts.isNotEmpty 
        ? _allTransactions[_currentCardIndex] 
        : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- My Accounts Header ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "My Accounts",
                            style: AppTypography.headline2.copyWith(
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Add account logic
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- SWIPEABLE CARDS ---
                    if (_myAccounts.isEmpty)
                      // EMPTY STATE
                      Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 10),
                              Text("No accounts found", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      // CARDS
                      SizedBox(
                        height: 200, 
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _myAccounts.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentCardIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final acc = _myAccounts[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: AccountCard(
                                accountName: acc['name'],
                                accountType: acc['type'],
                                initialBalance: acc['initial'],
                                currentBalance: acc['current'],
                                description: acc['desc'],
                                onTap: () {}, 
                                onEditTap: () => _showEditOptions(context, acc), 
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),
                    
                    // --- Pagination Dots ---
                    if (_myAccounts.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_myAccounts.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentCardIndex == index
                                  ? AppColors.primary
                                  : AppColors.greyLight,
                            ),
                          );
                        }),
                      ),

                    const SizedBox(height: 30),

                    // --- Transactions Header ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                        "Transactions",
                        style: AppTypography.headline2.copyWith(
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),

                    // --- Transaction List ---
                    if (_myAccounts.isEmpty || currentTransactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(child: Text("No transactions available.")),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        itemCount: currentTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = currentTransactions[index];
                          return _TransactionTile(
                            title: tx['title'],
                            subtitle: tx['date'],
                            amount: tx['amount'],
                            icon: tx['icon'],
                            isExpense: tx['isExpense'],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final bool isExpense;

  const _TransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: isExpense ? Colors.black.withOpacity(0.05) : AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: isExpense ? Colors.black : AppColors.success, 
              size: 24
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.getTextPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.labelLarge.copyWith(
              color: isExpense ? Colors.black : AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}