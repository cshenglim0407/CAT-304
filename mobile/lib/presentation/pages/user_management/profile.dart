import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'edit_personal_info.dart';
import '../../widgets/index.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 1; // Default to Profile tab

  // --- User Data ---
  final String _dobString = "2003-08-24"; 
  final String _gender = "Male";
  final String _timezone = "GMT+8";
  final String _currency = "MYR";
  final String _themePref = "Light";

  // --- Age Calculation ---
  String _getFormattedDob(String dateStr) {
    try {
      DateTime birthDate = DateTime.parse(dateStr);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || 
         (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return "$dateStr ($age)"; 
    } catch (e) {
      return dateStr;
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      debugPrint("Navigate to Home");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kBgColor = Color(0xFFF8F8F8);
    
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            children: [
              // --- Back button + Title ---
              Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Profile",
                  style: AppTypography.headline2.copyWith(color: Colors.black87),
                ),
              ),
              const SizedBox(height: 10),
              
              // --- Profile Header ---
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      "JSmith",
                      style: AppTypography.headline3.copyWith(color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "jonathansmith123@gmail.com",
                      style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- INFORMATION CARD ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Information",
                      style: AppTypography.headline3.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    InfoRow(label: "Date of Birth", value: _getFormattedDob(_dobString), icon: Icons.calendar_today_rounded),
                    InfoRow(label: "Gender", value: _gender, icon: Icons.person_outline_rounded),
                    InfoRow(label: "Timezone", value: _timezone, icon: Icons.access_time_rounded),
                    InfoRow(label: "Currency", value: _currency, icon: Icons.attach_money_rounded),
                    InfoRow(label: "Theme", value: _themePref, icon: Icons.brightness_6_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- Menu Items ---
              AppMenuItem(
                icon: Icons.edit_note_rounded,
                label: "Edit Personal Information",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditPersonalInformationPage(),
                    ),
                  );
                },
              ),
              AppMenuItem(
                icon: Icons.logout_rounded,
                label: "Logout",
                isDestructive: true,
                onTap: () {},
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}