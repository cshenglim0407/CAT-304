import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';
import 'package:cashlytics/presentation/widgets/account_card.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/usecases/accounts/get_account_transactions.dart';
import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/entities/account_transaction_view.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 1;
  int _currentCardIndex = 0;
  late PageController _pageController;

  bool _isLoadingAccounts = true;
  bool _isLoadingTransactions = true;
  List<Account> _myAccounts = [];
  List<AccountTransactionView> _currentTransactions = [];

  late final AccountRepository _accountRepository;
  late final GetAccounts _getAccounts;
  late final GetAccountTransactions _getAccountTransactions;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _accountRepository = AccountRepositoryImpl();
    _getAccounts = GetAccounts(_accountRepository);
    _getAccountTransactions = GetAccountTransactions(_accountRepository);
    _authService = AuthService();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoadingAccounts = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final accounts = await _getAccounts(user.id);
      setState(() {
        _myAccounts = accounts;
        _isLoadingAccounts = false;
        _currentCardIndex = 0;
      });

      // Load transactions for the first account if available
      if (accounts.isNotEmpty) {
        await _loadTransactions(accounts[0].id!);
      }
    } catch (e) {
      debugPrint('Error loading accounts: $e');
      setState(() {
        _isLoadingAccounts = false;
        _myAccounts = [];
      });
    }
  }

  Future<void> _loadTransactions(String accountId) async {
    setState(() => _isLoadingTransactions = true);

    try {
      final transactions = await _getAccountTransactions(accountId);
      setState(() {
        _currentTransactions = transactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isLoadingTransactions = false;
        _currentTransactions = [];
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  // --- LOGIC: Confirm Dialog ---
  void _confirmDelete(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text("Are you sure you want to remove '${account.name}'? This cannot be undone."),
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
  void _showEditOptions(BuildContext context, Account account) {
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
                "Manage ${account.name}",
                style: AppTypography.headline3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
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
                    color: Colors.red.withValues(alpha: 0.1),
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

  // --- LOGIC: Delete Account ---
  Future<void> _deleteAccount(Account account) async {
    try {
      await AccountRepositoryImpl().deleteAccount(account.id!);
      
      setState(() {
        _myAccounts.removeWhere((acc) => acc.id == account.id);

        // Adjust the current card index safely
        if (_currentCardIndex >= _myAccounts.length) {
          _currentCardIndex = _myAccounts.isNotEmpty ? _myAccounts.length - 1 : 0;
        }

        // Load transactions for the new current account
        if (_myAccounts.isNotEmpty) {
          _loadTransactions(_myAccounts[_currentCardIndex].id!);
        } else {
          _currentTransactions = [];
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${account.name} deleted")),
        );
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete account: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              // Add account logic - to be implemented
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- ACCOUNTS LOADING / EMPTY / CARDS ---
                    if (_isLoadingAccounts)
                      Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_myAccounts.isEmpty)
                      // EMPTY STATE
                      Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
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
                            _loadTransactions(_myAccounts[index].id!);
                          },
                          itemBuilder: (context, index) {
                            final acc = _myAccounts[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: AccountCard(
                                accountName: acc.name,
                                accountType: acc.type,
                                initialBalance: acc.initialBalance,
                                currentBalance: acc.currentBalance,
                                description: acc.description ?? '',
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

                    // --- Transaction List / Loading / Empty ---
                    if (_myAccounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(child: Text("No transactions available.")),
                      )
                    else if (_isLoadingTransactions)
                      const Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_currentTransactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(child: Text("No transactions for this account.")),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        itemCount: _currentTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = _currentTransactions[index];
                          return _TransactionTile(
                            title: tx.title,
                            subtitle: _formatDate(tx.date),
                            amount: _formatCurrency(tx.amount, tx.isExpense),
                            isExpense: tx.isExpense,
                            icon: tx.icon,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_monthName(date.month)}';
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatCurrency(double amount, bool isExpense) {
    final sign = isExpense ? '- ' : '+ ';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;
  final IconData? icon;

  const _TransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    this.icon,
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
              color: isExpense
                  ? Colors.black.withValues(alpha: 0.05)
                  : AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? (isExpense ? Icons.remove : Icons.add),
              color: isExpense ? Colors.black : AppColors.success,
              size: 24,
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
