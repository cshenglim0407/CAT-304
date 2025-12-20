import 'package:flutter/material.dart';
import '../../themes/colors.dart';
import '../../themes/typography.dart';
import '../../widgets/index.dart';
import 'otp_verification.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();

  @override
  void dispose() {
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
                subtitle: "Don't worry! It occurs. Please enter the email address linked with your account.",
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
                onPressed: () {
                  String email = _email.text;
                  
                  if (email.isNotEmpty && email.contains('@')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OtpVerificationPage(userEmail: email),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a valid email address.")),
                    );
                  }
                },
              ),

              const SizedBox(height: 30),

              // --- Footer: Back to Login ---
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
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