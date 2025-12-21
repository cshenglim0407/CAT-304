import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/auth_services.dart';
import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/utils/context_extensions.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

import 'package:cashlytics/presentation/pages/income_expense_management/home_page.dart';
import 'package:cashlytics/presentation/pages/user_management/login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final _displayName = TextEditingController();
  late final _email = TextEditingController();
  late final _password = TextEditingController();
  late final _birthdate = TextEditingController();
  String? _selectedGender;

  late final _authService = AuthService();

  bool _obscure = true;

  bool _isLoading = false; // for loading state
  bool _redirecting = false; // for redirect state
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signUpWithEmail() async {
    if (_selectedGender == null) {
      context.showSnackBar("Please select a gender.", isError: true);
      return;
    }

    await _authService.signUpWithEmail(
      displayName: _displayName.text,
      email: _email.text,
      password: _password.text,
      birthdate: _birthdate.text,
      gender: _selectedGender!,
      onLoadingStart: () {
        setState(() => _isLoading = true);
      },
      onLoadingEnd: () {
        setState(() => _isLoading = false);
        context.showSnackBar(
          'Sign up successful! Please check your email to verify your account.',
        );
        // delay to allow user to read the message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        });
      },
      onError: (message) {
        context.showSnackBar(message, isError: true);
      },
    );
  }

  Future<void> _signUpWithGoogle() async {
    await _authService.signInWithGoogle(
      rememberMe: true,
      onLoadingStart: () {
        if (mounted) setState(() => _isLoading = true);
      },
      onLoadingEnd: () {
        if (mounted) setState(() => _isLoading = false);
      },
      onError: (message) {
        if (mounted) context.showSnackBar(message, isError: true);
      },
    );
  }

  Future<void> _signUpWithFacebook() async {
    await _authService.signInWithFacebook(
      rememberMe: true,
      onLoadingStart: () {
        if (mounted) setState(() => _isLoading = true);
      },
      onLoadingEnd: () {
        if (mounted) setState(() => _isLoading = false);
      },
      onError: (message) {
        if (mounted) context.showSnackBar(message, isError: true);
      },
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdate.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn && !_redirecting) {
          if (mounted) {
            setState(() => _redirecting = true);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
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
    _authStateSubscription.cancel();
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _birthdate.dispose();
    super.dispose();
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return SocialAuthButton(label: label, icon: icon, onPressed: onPressed);
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
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo/logo.webp', height: 60),
                  const SizedBox(width: 10),
                ],
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                "Sign Up Account",
                style: AppTypography.pageTitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your personal data to create\nyour account.",
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.greyText,
                ),
              ),

              const SizedBox(height: 24),

              // Social Buttons
              Row(
                children: [
                  _socialButton(
                    label: "Google",
                    icon: const Text(
                      "G",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: _signUpWithGoogle,
                  ),
                  const SizedBox(width: 14),
                  _socialButton(
                    label: "Facebook",
                    icon: const Icon(
                      Icons.facebook,
                      color: Color(0xFF1877F2),
                      size: 22,
                    ),
                    onPressed: _signUpWithFacebook,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.greyLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "Or",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.greyText,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.greyLight)),
                ],
              ),

              const SizedBox(height: 20),

              // --- Display Name ---
              FormLabel(label: "Display Name"),
              CustomTextFormField(
                controller: _displayName,
                hint: "Display Name",
              ),

              const SizedBox(height: 16),

              // --- Email ---
              FormLabel(label: "Email Address"),
              CustomTextFormField(
                controller: _email,
                hint: "Email Address",
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // --- Password ---
              FormLabel(label: "Password"),
              CustomTextFormField(
                controller: _password,
                hint: "Password",
                obscureText: _obscure,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.greyText,
                    size: 20,
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

              const SizedBox(height: 24),

              // *** Gender Dropdown (Full Width) ***
              FormLabel(label: "Gender"),
              CustomDropdownFormField(
                value: _selectedGender,
                items: const ['Male', 'Female'],
                hint: "Select",
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // --- Date of Birth ---
              FormLabel(label: "Date of Birth"),
              CustomTextFormField(
                controller: _birthdate,
                hint: "YYYY-MM-DD",
                readOnly: true,
                onTap: _selectDate,
                suffixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: AppColors.greyText,
                ),
              ),

              const SizedBox(height: 16),

              // --- Sign Up Button ---
              PrimaryButton(
                label: "Sign Up",
                onPressed: _signUpWithEmail,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 24),

              // --- Footer ---
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.black87,
                    ),
                    children: [
                      const TextSpan(text: "Already have an account? "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Sign In",
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
