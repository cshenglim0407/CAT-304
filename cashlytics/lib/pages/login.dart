import 'package:flutter/material.dart';

import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;

  static const Color kPrimary = Color(0xFF2E604B);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
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
        child: Align( 
          alignment: const Alignment(0, -0.7),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.webp',
                      height: 75,
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 60),

                const Text(
                  "Welcome Back!",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E604B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Enter your LoginPage information",
                  style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                ),

                const SizedBox(height: 22),

                // Google / Facebook buttons
                Row(
                  children: [
                    // --- Google Button ---
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFEAEAEA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("G",
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            SizedBox(width: 8),
                            Text("Google",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // --- Facebook Button ---
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFEAEAEA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.facebook,
                                color: Color(0xFF1877F2), size: 20),
                            SizedBox(width: 8),
                            Text("Facebook",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Divider with "Or"
                Row(
                  children: const [
                    Expanded(
                        child: Divider(color: Color(0xFFEAEAEA), thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Or",
                          style: TextStyle(color: Color(0xFF9E9E9E))),
                    ),
                    Expanded(
                        child: Divider(color: Color(0xFFEAEAEA), thickness: 1)),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  "Email Address",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(hint: "Email Address"),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Password",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: _inputDecoration(
                    hint: "Password",
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                        activeColor: kPrimary,
                        side: const BorderSide(color: Color(0xFFBDBDBD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text("Remember me",
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to Forgot Password Page
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const ForgotPasswordPage())
                        );
                      },
                      // ... rest of your style code
                      child: const Text("Forgot Password?"),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
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
                      "Sign In",
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Bottom sign up text
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 13),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/signup'),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.w700,
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
    );
  }
}
