import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.greyText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          // Index 0: Home
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          
          // Index 1: Account (NEW ADDITION)
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Account',
          ),

          // Index 2: Profile
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}