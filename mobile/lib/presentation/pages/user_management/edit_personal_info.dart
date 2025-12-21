import 'package:flutter/material.dart';

import 'package:cashlytics/core/utils/profile_constants.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

class EditPersonalInformationPage extends StatefulWidget {
  const EditPersonalInformationPage({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  State<EditPersonalInformationPage> createState() =>
      _EditPersonalInformationPageState();
}

class _EditPersonalInformationPageState
    extends State<EditPersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _birthdateController;

  // Dropdown State Variables
  String? _selectedGender;
  String? _selectedTimezone;
  String? _selectedCurrency;
  String? _selectedTheme;

  bool _isLoading = false;

  String? _findTimezoneItemFromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final needle = "(UTC$code)"; // "+08:00" -> "(UTC+08:00)"
    try {
      return ProfileConstants.timezones.firstWhere(
        (tz) => tz.startsWith(needle),
      );
    } catch (_) {
      return null;
    }
  }

  String? _findCurrencyItemFromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final upper = code.toUpperCase();
    try {
      return ProfileConstants.currencies.firstWhere(
        (c) => c.startsWith("$upper "),
      );
    } catch (_) {
      return null;
    }
  }

  String? _normalizeTheme(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final t = raw.toLowerCase();
    if (t == 'light' || t == 'dark' || t == 'system') {
      return t[0].toUpperCase() + t.substring(1);
    }
    return null;
  }

  String? _normalizeGender(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final g = raw.toLowerCase();
    if (g == 'male' || g == 'm') return 'Male';
    if (g == 'female' || g == 'f') return 'Female';
    if (g == 'other') return 'Other';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _birthdateController = TextEditingController();

    // Sensible defaults that exist in items
    _selectedGender = "Male";
    _selectedTimezone =
        _findTimezoneItemFromCode("+08:00") ??
        "(UTC+08:00) Kuala Lumpur, Singapore, Beijing, Perth";
    _selectedCurrency = "MYR - Malaysian Ringgit";
    _selectedTheme = "Light";

    _seedFromProfile();
  }

  void _seedFromProfile() {
    final data = widget.profile;
    if (data == null) return;

    _usernameController.text =
        (data['display_name'] ?? _usernameController.text).toString();
    _emailController.text = (data['email'] ?? _emailController.text).toString();

    final dob = data['date_of_birth'] as String?;
    if (dob != null && dob.isNotEmpty) {
      _birthdateController.text = dob;
    }

    _selectedGender =
        _normalizeGender(data['gender'] as String?) ?? _selectedGender;
    _selectedTimezone =
        _findTimezoneItemFromCode(data['timezone'] as String?) ??
        _selectedTimezone;
    _selectedCurrency =
        _findCurrencyItemFromCode(data['currency_pref'] as String?) ??
        _selectedCurrency;
    _selectedTheme =
        _normalizeTheme(data['theme_pref'] as String?) ?? _selectedTheme;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final initial =
        DateTime.tryParse(_birthdateController.text) ?? DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
        _birthdateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile settings updated successfully!"),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBackButton(onPressed: () => Navigator.pop(context)),

                const SizedBox(height: 30),

                const SectionTitle(title: "Edit Profile"),
                const SizedBox(height: 8),
                const SectionSubtitle(
                  subtitle: "Update your personal details and preferences.",
                ),

                const SizedBox(height: 32),

                // --- Personal Information ---
                Text(
                  "Personal Info",
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                const FormLabel(label: "Username"),
                CustomTextFormField(
                  controller: _usernameController,
                  hint: "Enter username",
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Username is required";
                    if (value.length < 3)
                      return "Username must be at least 3 chars";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                const FormLabel(label: "Email Address"),
                CustomTextFormField(
                  controller: _emailController,
                  hint: "Email Address",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Email is required";
                    if (!value.contains('@')) return "Invalid email";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                const FormLabel(label: "Gender"),
                CustomDropdownFormField(
                  value: _selectedGender,
                  items: const ['Male', 'Female', 'Other'],
                  hint: "Select Gender",
                  onChanged: (newValue) =>
                      setState(() => _selectedGender = newValue),
                ),

                const SizedBox(height: 16),

                const FormLabel(label: "Date of Birth"),
                CustomTextFormField(
                  controller: _birthdateController,
                  hint: "YYYY-MM-DD",
                  readOnly: true,
                  onTap: _selectDate,
                  suffixIcon: const Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: AppColors.greyText,
                  ),
                ),

                const SizedBox(height: 32),

                // --- App Preferences ---
                Text(
                  "Preferences",
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Timezone
                const FormLabel(label: "Timezone"),
                CustomDropdownFormField(
                  value: _selectedTimezone,
                  items: ProfileConstants.timezones,
                  hint: "Select Timezone",
                  onChanged: (newValue) =>
                      setState(() => _selectedTimezone = newValue),
                  // Parses "(UTC+08:00) City" -> "(UTC+08:00)"
                  selectedItemTransformer: (val) {
                    if (val.contains(')')) {
                      return "${val.split(')').first})";
                    }
                    return val;
                  },
                ),

                const SizedBox(height: 16),

                // Currency
                const FormLabel(label: "Currency"),
                CustomDropdownFormField(
                  value: _selectedCurrency,
                  items: ProfileConstants.currencies,
                  hint: "Select Currency",
                  onChanged: (newValue) =>
                      setState(() => _selectedCurrency = newValue),
                  // Parses "MYR - Malaysian Ringgit" -> "MYR"
                  selectedItemTransformer: (val) {
                    if (val.contains(' - ')) {
                      return val.split(' - ').first;
                    }
                    return val;
                  },
                ),

                const SizedBox(height: 16),

                const FormLabel(label: "App Theme"),
                CustomDropdownFormField(
                  value: _selectedTheme,
                  items: const ['Light', 'Dark', 'System'],
                  hint: "Select Theme",
                  onChanged: (newValue) =>
                      setState(() => _selectedTheme = newValue),
                ),

                const SizedBox(height: 40),

                PrimaryButton(
                  label: "Save Changes",
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
