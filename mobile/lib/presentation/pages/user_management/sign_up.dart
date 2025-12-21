import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _birthdate = TextEditingController();

  String? _selectedGender; 
  bool _obscure = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _birthdate.dispose();
    // REMOVED: _age.dispose();
    super.dispose();
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
        _birthdate.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.greyHint, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.greyBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.greyBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  Widget _label(String label) {
    return FormLabel(label: label);
  }

  Widget _socialButton({required String label, required Widget icon}) {
    return SocialAuthButton(
      label: label,
      icon: icon,
      onPressed: () {},
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
              Text("Sign Up Account", style: AppTypography.pageTitle.copyWith(color: AppColors.primary)),
              const SizedBox(height: 8),
              Text("Enter your personal data to create\nyour account.", style: AppTypography.subtitle.copyWith(color: AppColors.greyText)),

              const SizedBox(height: 24),

              // Social Buttons
              Row(
                children: [
                  _socialButton(label: "Google", icon: const Text("G", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                  const SizedBox(width: 14),
                  _socialButton(label: "Facebook", icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22)),
                ],
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.greyLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Or", style: AppTypography.bodySmall.copyWith(color: AppColors.greyText)),
                  ),
                  const Expanded(child: Divider(color: AppColors.greyLight)),
                ],
              ),

              const SizedBox(height: 20),

              // --- First & Last Name ---
              Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("First Name"),
                        TextField(controller: _firstName, decoration: _inputDecoration(hint: "First Name")),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("Last Name"),
                        TextField(controller: _lastName, decoration: _inputDecoration(hint: "Last Name")),
                    ]),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // *** Gender Dropdown (Full Width) ***
              FormLabel(label: "Gender"),
              CustomDropdownFormField(
                value: _selectedGender,
                items: const ['Male', 'Female'],
                hint: "Select",
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue;
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
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.greyText),
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
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.greyText,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text("Must contain at least 6 characters.", style: AppTypography.caption.copyWith(color: AppColors.greyText)),

              const SizedBox(height: 24),

              // --- Sign Up Button ---
              PrimaryButton(
                label: "Sign Up",
                onPressed: () {},
              ),

              const SizedBox(height: 24),

              // --- Footer ---
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
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