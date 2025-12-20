import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Your Primary Color
  static const Color kPrimary = Color(0xFF2E604B);
  static const Color kBgColor = Color(0xFFF8F8F8);

  int _selectedIndex = 1;

  // --- User Data ---
  final String _dobString = "2003-08-24"; 
  final String _gender = "Male";
  final String _timezone = "GMT+8";
  final String _currency = "MYR";
  final String _themePref = "Light";

  // --- Helper to calculate Age ---
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

  // --- Helper Widget: Menu Item ---
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isLogout ? Colors.red : Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UPDATED Helper Widget: Information Row ---
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimary), 
          const SizedBox(width: 14),
          
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const Spacer(),
          
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  // --- PROFILE AVATAR ---
                  // Container(
                  //   padding: const EdgeInsets.all(4),
                  //   decoration: BoxDecoration(
                  //     shape: BoxShape.circle,
                  //     border: Border.all(color: kPrimary, width: 2),
                  //   ),
                  //   child: const CircleAvatar(
                  //     radius: 45,
                  //     backgroundImage: AssetImage('assets/avatar_placeholder.png'),
                  //   ),
                  // ),
                  const SizedBox(height: 12),
                  const Text(
                    "JSmith",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "jonathansmith123@gmail.com",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  const Text(
                    "Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  _buildInfoRow("Date of Birth", _getFormattedDob(_dobString), Icons.calendar_today_rounded),
                  _buildInfoRow("Gender", _gender, Icons.person_outline_rounded),
                  _buildInfoRow("Timezone", _timezone, Icons.access_time_rounded),
                  _buildInfoRow("Currency", _currency, Icons.attach_money_rounded),
                  _buildInfoRow("Theme", _themePref, Icons.brightness_6_outlined),
                ],
              ),
            ),

            const SizedBox(height: 30),

            _buildMenuItem(
              icon: Icons.edit_note_rounded,
              text: "Edit Details",
              onTap: () {},
            ),
             _buildMenuItem(
              icon: Icons.credit_card_rounded,
              text: "Payment Methods",
              onTap: () {},
            ),
             _buildMenuItem(
              icon: Icons.help_outline_rounded,
              text: "Help Center",
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              text: "Logout",
              iconColor: Colors.red,
              isLogout: true,
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kPrimary,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_rounded, color: kPrimary),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}