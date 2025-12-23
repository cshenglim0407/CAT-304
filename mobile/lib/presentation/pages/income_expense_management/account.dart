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

  final List<String> _accountTypes = ['BANK', 'CASH', 'E-WALLET', 'CREDIT CARD', 'INVESTMENT', 'LOAN'];

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

  // --- DATA ---
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

  // --- LOGIC: Add Account ---
  void _addAccount(BuildContext context) {
    // 1. Setup Controllers
    final nameController = TextEditingController();
    final balanceController = TextEditingController(); // Only one controller needed now
    final descController = TextEditingController();
    String selectedType = _accountTypes[0]; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    
                    Center(child: Text("Add New Account", style: AppTypography.headline3.copyWith(fontSize: 18))),
                    const SizedBox(height: 20),

                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Account Name", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: _accountTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (value) => setSheetState(() => selectedType = value!),
                      decoration: const InputDecoration(labelText: "Account Type", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Single Balance Input
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(labelText: "Balance", border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Description (Optional)", border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 24),

                    // ADD Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (nameController.text.isEmpty) return; 

                          // Get the single balance input
                          final double startBalance = double.tryParse(balanceController.text) ?? 0.0;

                          setState(() {
                            _myAccounts.add({
                              'id': DateTime.now().toString(),
                              'name': nameController.text,
                              'type': selectedType,
                              'current': startBalance, // Set current
                              'initial': startBalance, // Set initial to same value
                              'desc': descController.text,
                            });
                            _allTransactions.add([]); 

                            _currentCardIndex = _myAccounts.length - 1;
                          });

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                             if (_pageController.hasClients) {
                               _pageController.jumpToPage(_currentCardIndex);
                             }
                          });

                          Navigator.pop(ctx); 
                        },
                        child: const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- LOGIC: Edit Account ---
  void _editAccount(BuildContext context, Map<String, dynamic> account) {
    final nameController = TextEditingController(text: account['name']);
    final currentBalController = TextEditingController(text: account['current'].toString());
    final initialBalController = TextEditingController(text: account['initial'].toString());
    final descController = TextEditingController(text: account['desc']);
    String selectedType = account['type']; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Center(child: Text("Edit Account", style: AppTypography.headline3.copyWith(fontSize: 18))),
                    const SizedBox(height: 20),

                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Account Name", border: OutlineInputBorder())),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _accountTypes.contains(selectedType) ? selectedType : _accountTypes[0],
                      items: _accountTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (value) => setSheetState(() => selectedType = value!),
                      decoration: const InputDecoration(labelText: "Account Type", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: TextField(controller: currentBalController, decoration: const InputDecoration(labelText: "Current Balance", border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: initialBalController, decoration: const InputDecoration(labelText: "Initial Balance", border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(controller: descController, decoration: const InputDecoration(labelText: "Description (Optional)", border: OutlineInputBorder()), maxLines: 2),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          setState(() {
                            account['name'] = nameController.text;
                            account['type'] = selectedType;
                            account['current'] = double.tryParse(currentBalController.text) ?? 0.0;
                            account['initial'] = double.tryParse(initialBalController.text) ?? 0.0;
                            account['desc'] = descController.text;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- LOGIC: Delete ---
  void _deleteAccount(Map<String, dynamic> account) {
    int indexToRemove = _myAccounts.indexOf(account);
    if (indexToRemove == -1) return;

    setState(() {
      _myAccounts.removeAt(indexToRemove);
      _allTransactions.removeAt(indexToRemove);
      if (_currentCardIndex >= _myAccounts.length) {
        _currentCardIndex = _myAccounts.isNotEmpty ? _myAccounts.length - 1 : 0;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${account['name']} deleted")));
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text("Are you sure you want to remove '${account['name']}'?"),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(ctx)),
          TextButton(child: const Text("Delete", style: TextStyle(color: Colors.red)), onPressed: () { Navigator.pop(ctx); _deleteAccount(account); }),
        ],
      ),
    );
  }

  // --- UI: Options Menu ---
  void _showEditOptions(BuildContext context, Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text("Manage ${account['name']}", style: AppTypography.headline3.copyWith(fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.blue)),
                title: const Text("Edit Account", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Change name, balance, or type"),
                onTap: () { Navigator.pop(context); _editAccount(context, account); },
              ),
              const Divider(),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete, color: Colors.red)),
                title: const Text("Delete Account", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Remove this account permanently"),
                onTap: () { Navigator.pop(context); _confirmDelete(context, account); },
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
    final currentTransactions = _myAccounts.isNotEmpty ? _allTransactions[_currentCardIndex] : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: _selectedIndex, onTap: _onNavBarTap),
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
                    // --- Header ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("My Account", style: AppTypography.headline2.copyWith(color: AppColors.getTextPrimary(context))),
                          GestureDetector(
                            onTap: () => _addAccount(context), // <--- CONNECTED HERE
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.add, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Cards ---
                    if (_myAccounts.isEmpty)
                      Container(
                        height: 180,
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.3))),
                        child: const Center(child: Text("No accounts found", style: TextStyle(color: Colors.grey))),
                      )
                    else
                      SizedBox(
                        height: 220, 
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _myAccounts.length,
                          onPageChanged: (index) {
                            setState(() { _currentCardIndex = index; });
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
                    
                    if (_myAccounts.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_myAccounts.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8, height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _currentCardIndex == index ? AppColors.primary : AppColors.greyLight),
                          );
                        }),
                      ),

                    const SizedBox(height: 30),

                    // --- Transactions ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text("Transactions", style: AppTypography.headline2.copyWith(color: AppColors.getTextPrimary(context))),
                    ),
                    const SizedBox(height: 10),

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

  const _TransactionTile({required this.title, required this.subtitle, required this.amount, required this.icon, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            height: 50, width: 50,
            decoration: BoxDecoration(color: isExpense ? Colors.black.withOpacity(0.05) : AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: isExpense ? Colors.black : AppColors.success, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.greyText)),
              ],
            ),
          ),
          Text(amount, style: AppTypography.labelLarge.copyWith(color: isExpense ? Colors.black : AppColors.success, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}