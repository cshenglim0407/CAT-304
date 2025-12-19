import 'package:flutter/material.dart';
import 'otpverification.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _email = TextEditingController();

  // Your specific Green color
  static const Color kPrimary = Color(0xFF2E604B);
  static const Color kGreyColor = Color(0xFFEAEAEA);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  // Reuse your input decoration for consistency
  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                onTap: () => Navigator.pop(context), // Go back to Login
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGreyColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 30),
              
              const SizedBox(height: 40),

              // --- Title & Description ---
              const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w700, 
                  color: kPrimary
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Don't worry! It occurs. Please enter the email address linked with your account.",
                style: TextStyle(
                  fontSize: 14, 
                  color: Color(0xFF9E9E9E), 
                  height: 1.5
                ),
              ),

              const SizedBox(height: 32),

              // --- Email Input ---
              const Text(
                "Email Address",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(hint: "Enter your email"),
              ),

              const SizedBox(height: 32),

              // --- Send Code Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String email = _email.text;
                    
                    if (email.isNotEmpty && email.contains('@')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtpVerification(userEmail: email),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid email address.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, // <--- This sets the button to your Green color
                    foregroundColor: Colors.white, // This makes the text White
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Send Code",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- Footer: Back to Login ---
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      const TextSpan(text: "Remember Password? "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w700,
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