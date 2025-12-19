import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _birthdate = TextEditingController();

  // REMOVED: final _age = TextEditingController();

  String? _selectedGender; 
  bool _obscure = true;

  static const Color kPrimary = Color(0xFF2E604B); 
  static const Color kGreyColor = Color(0xFFEAEAEA);

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
              primary: kPrimary, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kPrimary),
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
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
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

  Widget _label(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _socialButton({required String label, required Widget icon}) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: kGreyColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
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
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.webp', height: 60),
                  const SizedBox(width: 10),
                ],
              ),
              
              const SizedBox(height: 24),

              // Title
              const Text("Sign Up Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF2E604B))),
              const SizedBox(height: 8),
              const Text("Enter your personal data to create\nyour account.", style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), height: 1.4)),

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
                children: const [
                  Expanded(child: Divider(color: kGreyColor)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Or", style: TextStyle(color: Color(0xFF9E9E9E)))),
                  Expanded(child: Divider(color: kGreyColor)),
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

              // *** MODIFIED: Gender Dropdown (Full Width now) ***
              _label("Gender"),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text("Select", style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 14)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9E9E9E)),
                decoration: _inputDecoration(hint: ""), 
                items: ['Male', 'Female'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),

              const SizedBox(height: 16),

              // --- Date of Birth ---
              _label("Date of Birth"),
              TextField(
                controller: _birthdate,
                readOnly: true, 
                onTap: _selectDate, 
                decoration: _inputDecoration(
                  hint: "YYYY-MM-DD",
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF9E9E9E)),
                ),
              ),

              const SizedBox(height: 16),

              // --- Email ---
              _label("Email Address"),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(hint: "Email Address"),
              ),

              const SizedBox(height: 16),

              // --- Password ---
              _label("Password"),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: _inputDecoration(
                  hint: "Password",
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF9E9E9E),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text("Must contain at least 6 characters.", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),

              const SizedBox(height: 24),

              // --- Sign Up Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 24),

              // --- Footer ---
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      const TextSpan(text: "Already have an account? "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text("Sign In", style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
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