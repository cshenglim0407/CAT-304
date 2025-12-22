import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

import 'package:cashlytics/presentation/pages/user_management/reset_password.dart';

class OtpVerificationPage extends StatefulWidget {
  final String userEmail;

  const OtpVerificationPage({super.key, required this.userEmail});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all 4 digits")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
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
              SectionTitle(title: "Enter OTP Code"),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: AppTypography.subtitle.copyWith(color: AppColors.greyText),
                  children: [
                    const TextSpan(text: "Check your Email! We've sent a one-time verification code to "),
                    TextSpan(
                      text: widget.userEmail,
                      style: AppTypography.labelLarge.copyWith(color: Colors.black87),
                    ),
                    const TextSpan(text: ". Enter the code below to verify your account."),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- OTP Input Fields ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) => OtpInputField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) {
                      if (value.length == 1 && index < 3) {
                        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Timer & Resend ---
              TimerText(
                secondsRemaining: _secondsRemaining,
                enableResend: _enableResend,
                onResendTap: _resendCode,
              ),

              const SizedBox(height: 40),

              // --- Verify Button ---
              PrimaryButton(
                label: "Verify",
                onPressed: _verifyOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Local OTP input field (inlined for this page)
class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: focusNode.hasFocus ? AppColors.primary : AppColors.greyBorder,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: AppTypography.headline3,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// Timer + Resend widget (inlined for this page)
class TimerText extends StatelessWidget {
  final int secondsRemaining;
  final bool enableResend;
  final VoidCallback onResendTap;

  const TimerText({
    super.key,
    required this.secondsRemaining,
    required this.enableResend,
    required this.onResendTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: enableResend
          ? TextButton(
              onPressed: onResendTap,
              child: Text(
                "Resend code",
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            )
          : RichText(
              text: TextSpan(
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.greyText,
                ),
                children: [
                  const TextSpan(text: "You can resend the code in "),
                  TextSpan(
                    text: "$secondsRemaining seconds",
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}