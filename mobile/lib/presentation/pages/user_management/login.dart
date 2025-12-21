import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/main.dart';
import 'package:cashlytics/core/services/supabase/auth_services.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

import 'package:cashlytics/presentation/pages/user_management/forgot_password.dart';
import 'package:cashlytics/presentation/pages/income_expense_management/home_page.dart';
import 'package:cashlytics/presentation/pages/user_management/sign_up.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Logic Variables
  late final _email = TextEditingController();
  late final _password = TextEditingController();

  late final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _obscure = true;
  bool _isLoading = false;
  bool _redirecting = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signInWithEmail() async {
    await _authService.signInWithEmail(
      email: _email.text,
      password: _password.text,
      rememberMe: _rememberMe,
      onLoadingStart: () {
        if (mounted) {
          setState(() => _isLoading = true);
        }
      },
      onLoadingEnd: () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      onError: (message) {
        if (mounted) {
          context.showSnackBar(message, isError: true);
        }
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    await _authService.signInWithGoogle(
      rememberMe: _rememberMe,
      onLoadingStart: () {
        if (mounted) {
          setState(() => _isLoading = true);
        }
      },
      onLoadingEnd: () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      onError: (message) {
        if (mounted) {
          context.showSnackBar(message, isError: true);
        }
      },
    );
  }

  Future<void> _signInWithFacebook() async {
    await _authService.signInWithFacebook(
      rememberMe: _rememberMe,
      onLoadingStart: () {
        if (mounted) {
          setState(() => _isLoading = true);
        }
      },
      onLoadingEnd: () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      onError: (message) {
        if (mounted) {
          context.showSnackBar(message, isError: true);
        }
      },
    );
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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.3), 
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Logo ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo/logo_without_word.webp', height: 75),
                      const SizedBox(width: 10),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- Header ---
                  const SectionTitle(title: "Welcome Back!"),
                  const SizedBox(height: 6),
                  const SectionSubtitle(subtitle: "Enter your login information"),

                  const SizedBox(height: 26),

                  // --- Email Input ---
                  const FormLabel(label: "Email Address"),
                  CustomTextFormField(
                    controller: _email,
                    hint: "Email Address",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      if (!value.contains('@')) return 'Invalid email address';
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // --- Password Input ---
                  const FormLabel(label: "Password"),
                  CustomTextFormField(
                    controller: _password,
                    hint: "Password",
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.greyText,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  // --- Remember Me & Forgot Password ---
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          activeColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.greyHint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Text("Remember me", style: AppTypography.bodyMedium),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Sign In Button ---
                  PrimaryButton(
                    label: "Sign In",
                    isLoading: _isLoading,
                    onPressed: _signInWithEmail,
                  ),

                  const SizedBox(height: 24),

                  // --- Divider ---
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.greyLight, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("Or", style: AppTypography.bodySmall.copyWith(color: AppColors.greyText)),
                      ),
                      const Expanded(child: Divider(color: AppColors.greyLight, thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Social Buttons (Minimalist Version) ---
                  Row(
                    children: [
                      SocialAuthButton(
                        // No Label = Minimalist Mode
                        icon: const Text("G", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
                        onPressed: _signInWithGoogle,
                      ),
                      const SizedBox(width: 14),
                      SocialAuthButton(
                        // No Label = Minimalist Mode
                        icon: const Icon(Icons.facebook, color: AppColors.facebook, size: 28),
                        onPressed: _signInWithFacebook,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- Sign Up Link ---
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => const SignUpPage())
                                );
                              },
                              child: Text(
                                "Sign Up",
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
        ),
      ),
    );
  }
}