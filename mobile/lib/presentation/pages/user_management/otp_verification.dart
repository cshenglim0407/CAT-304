import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'reset_password.dart';

class OtpVerificationPage extends StatefulWidget {
  final String userEmail; // Pass the email from the previous screen

  const OtpVerificationPage({super.key, required this.userEmail});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  // Your specific Green color
  static const Color kPrimary = Color(0xFF2E604B);
  static const Color kGreyColor = Color(0xFFEAEAEA);

  // Controllers and FocusNodes for the 4 OTP digits
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  int _secondsRemaining = 59;
  bool _enableResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 59;
      _enableResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _enableResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _resendCode() {
    // Logic to resend OTP to email goes here
    _startTimer();
  }

  void _verifyOtp() {
    String otp = _controllers.map((e) => e.text).join();

    if (otp.length == 4) {
      // ---------------------------------------------
      // SUCCESS! Navigate to Reset Password Page here
      // ---------------------------------------------
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
      );
      
    } else {
      // Show error if code is incomplete
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all 4 digits")),
      );
    }
  }

  Widget _otpField({required int index}) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _focusNodes[index].hasFocus ? kPrimary : kGreyColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 3) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
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
              
              const SizedBox(height: 40),

              // --- Title & Description ---
              const Text(
                "Enter OTP Code",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kPrimary),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), height: 1.5),
                  children: [
                    const TextSpan(text: "Check your Email! We've sent a one-time verification code to "),
                    TextSpan(
                      text: widget.userEmail, // Display the email
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ". Enter the code below to verify your account."),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- OTP Input Fields ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _otpField(index: index)),
              ),

              const SizedBox(height: 40),

              // --- Timer & Resend ---
              Center(
                child: _enableResend
                    ? TextButton(
                        onPressed: _resendCode,
                        child: const Text(
                          "Resend code",
                          style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                          children: [
                            const TextSpan(text: "You can resend the code in "),
                            TextSpan(
                              text: "$_secondsRemaining seconds",
                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 40),

              // --- Verify Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
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
                    "Verify",
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