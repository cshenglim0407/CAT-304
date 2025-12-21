import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/auth_services.dart';
import 'package:cashlytics/core/services/supabase/auth_state_listener.dart';
import 'package:cashlytics/core/utils/context_extensions.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

import 'package:cashlytics/presentation/pages/income_expense_management/home_page.dart';
import 'package:cashlytics/presentation/pages/user_management/login.dart';
// import 'package:cashlytics/presentation/pages/user_management/otp_verification.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final _email = TextEditingController();

  bool _isLoading = false; // for loading state
  bool _redirecting = false; // for redirecting state
  StreamSubscription<AuthState>? _authStateSubscription;

  Future<void> _forgotPassword() async {
    String email = _email.text;

    if (email.isNotEmpty && email.contains('@')) {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => OtpVerificationPage(userEmail: email),
      //   ),
      // );
      await AuthService().resetPassword(
        email: email,
        onLoadingStart: () {
          if (mounted) {
            context.showSnackBar(
              'Sending password reset email...',
              isError: false,
            );
            setState(() => _isLoading = true);
          }
        },
        onLoadingEnd: () {
          if (mounted) {
            context.showSnackBar(
              'Password reset email sent. Please check your inbox.',
              isError: false,
            );
            setState(() => _isLoading = false);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            });
          }
        },
        onError: (msg) {
          if (mounted) {
            setState(() => _isLoading = false);
            context.showSnackBar('Error: $msg', isError: true);
          }
        },
      );
    } else {
      context.showSnackBar(
        "Please enter a valid email address.",
        isError: true,
      );
      return;
    }
  }

  @override
  void initState() {
    _authStateSubscription = listenForSignedInRedirect(
      shouldRedirect: () => !_redirecting,
      onRedirect: () {
        if (!mounted) return;
        setState(() => _redirecting = true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      },
      onError: (error) {
        if (mounted) {
          context.showSnackBar('Authentication error: $error', isError: true);
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _email.dispose();
    super.dispose();
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

              const SizedBox(height: 40),

              // --- Title & Description ---
              SectionTitle(title: "Forgot Password?"),
              const SizedBox(height: 10),
              SectionSubtitle(
                subtitle:
                    "Don't worry! It occurs. Please enter the email address linked with your account.",
              ),

              const SizedBox(height: 32),

              // --- Email Input ---
              FormLabel(label: "Email Address"),
              CustomTextFormField(
                controller: _email,
                hint: "Enter your email",
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 32),

              // --- Send Code Button ---
              PrimaryButton(
                label: "Send Code",
                onPressed: _forgotPassword,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 30),

              // --- Footer: Back to Login ---
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.black87,
                    ),
                    children: [
                      const TextSpan(text: "Remember Password? "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Login",
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
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
