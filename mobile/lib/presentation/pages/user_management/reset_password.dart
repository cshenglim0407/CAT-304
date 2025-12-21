import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:flutter/material.dart';

import 'package:cashlytics/core/utils/context_extensions.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final _newPassword = TextEditingController();
  late final _confirmPassword = TextEditingController();

  late final _authService = AuthService();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _handleReset() async {
    String newPass = _newPassword.text;
    String confirmPass = _confirmPassword.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      context.showSnackBar("Please fill in all fields", isError: true);
      return;
    }

    if (newPass.length < 6) {
      context.showSnackBar(
        "Password must be at least 6 characters",
        isError: true,
      );
      return;
    }

    if (newPass != confirmPass) {
      context.showSnackBar("Passwords do not match", isError: true);
      return;
    }

    await _authService.updatePassword(
      newPassword: newPass,
      onLoadingStart: () {
        if (mounted) {
          context.showSnackBar('Resetting password...');
        }
      },
      onLoadingEnd: () {
        if (mounted) {
          _showSuccessDialog();
        }
      },
      onError: (errorMessage) {
        if (mounted) {
          context.showSnackBar(errorMessage, isError: true);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Your password has been reset successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text(
              "Login Now",
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
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
              SectionSubtitle(
                subtitle: "Please enter your new password below.",
              ),

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
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
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
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.greyText,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                "Must contain at least 6 characters.",
                style: AppTypography.caption.copyWith(
                  color: AppColors.greyText,
                ),
              ),

              const SizedBox(height: 40),

              // --- Reset Button ---
              PrimaryButton(label: "Reset Password", onPressed: _handleReset),
            ],
          ),
        ),
      ),
    );
  }
}
