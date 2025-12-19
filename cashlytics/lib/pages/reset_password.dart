import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Your App Theme Colors
  static const Color kPrimary = Color(0xFF2E604B);
  static const Color kGreyColor = Color(0xFFEAEAEA);

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _handleReset() {
    String newPass = _newPassword.text;
    String confirmPass = _confirmPassword.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both fields")),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    // Success Logic here (e.g., API call)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Your password has been reset successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate back to Login and remove all previous routes
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text("Login Now", style: TextStyle(color: kPrimary)),
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kGreyColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kGreyColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Back Button ---
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGreyColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
              ),

              const SizedBox(height: 30),

              // --- Title ---
              const Text(
                "Reset Password",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kPrimary),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please enter your new password below.",
                style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), height: 1.5),
              ),

              const SizedBox(height: 32),

              // --- New Password Field ---
              const Text("New Password", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _newPassword,
                obscureText: _obscureNew,
                decoration: _inputDecoration(
                  hint: "Enter new password",
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Confirm Password Field ---
              const Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPassword,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration(
                  hint: "Re-enter password",
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                "Must contain at least 6 characters.",
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              ),

              const SizedBox(height: 40),

              // --- Reset Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Reset Password",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}