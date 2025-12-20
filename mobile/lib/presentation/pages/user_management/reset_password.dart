import 'package:flutter/material.dart';
import '../../themes/colors.dart';
import '../../themes/typography.dart';
import '../../widgets/index.dart';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Your password has been reset successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text(
              "Login Now",
              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
            ),
          )
        ],
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
              AppBackButton(onPressed: () => Navigator.pop(context)),

              const SizedBox(height: 30),

              // --- Title ---
              SectionTitle(title: "Reset Password"),
              const SizedBox(height: 10),
              SectionSubtitle(subtitle: "Please enter your new password below."),

              const SizedBox(height: 32),

              // --- New Password Field ---
              FormLabel(label: "New Password"),
              CustomTextFormField(
                controller: _newPassword,
                hint: "Enter new password",
                obscureText: _obscureNew,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.greyText,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Confirm Password Field ---
              FormLabel(label: "Confirm Password"),
              CustomTextFormField(
                controller: _confirmPassword,
                hint: "Re-enter password",
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.greyText,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                "Must contain at least 6 characters.",
                style: AppTypography.caption.copyWith(color: AppColors.greyText),
              ),

              const SizedBox(height: 40),

              // --- Reset Button ---
              PrimaryButton(
                label: "Reset Password",
                onPressed: _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}