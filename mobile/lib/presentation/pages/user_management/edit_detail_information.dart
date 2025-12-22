import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

class EditDetailInformationPage extends StatefulWidget {
  final Map<String, dynamic>? currentDetails;

  const EditDetailInformationPage({super.key, this.currentDetails});

  @override
  State<EditDetailInformationPage> createState() => _EditDetailInformationPageState();
}

class _EditDetailInformationPageState extends State<EditDetailInformationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _dependentController;
  late final TextEditingController _loanController;

  // Dropdown Values
  String? _educationLevel;
  String? _employmentStatus;
  String? _maritalStatus;

  // Dropdown Options
  final List<String> _educationOptions = [
    'High School',
    'Diploma',
    "Bachelor's Degree",
    "Master's Degree",
    'PhD',
    'Other'
  ];

  final List<String> _employmentOptions = [
    'Employed',
    'Self-Employed',
    'Unemployed',
    'Student',
    'Retired'
  ];

  // CHANGED: Replaced 'Widowed' with 'Preferred not to say'
  final List<String> _maritalOptions = [
    'Single',
    'Married',
    'Divorced',
    'Preferred not to say', 
  ];

  @override
  void initState() {
    super.initState();
    _dependentController = TextEditingController();
    _loanController = TextEditingController();
    _initializeData();
  }

  void _initializeData() {
    if (widget.currentDetails == null) return;

    final data = widget.currentDetails!;

    _dependentController.text = data['dependent_number'] ?? '';
    
    String loan = data['estimated_loan'] ?? '';
    _loanController.text = loan.replaceAll('RM ', '').replaceAll(',', '');

    _educationLevel = _educationOptions.contains(data['education_level'])
        ? data['education_level']
        : null;
    
    _employmentStatus = _employmentOptions.contains(data['employment_status'])
        ? data['employment_status']
        : null;
    
    _maritalStatus = _maritalOptions.contains(data['marital_status'])
        ? data['marital_status']
        : null;
  }

  @override
  void dispose() {
    _dependentController.dispose();
    _loanController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() => _isLoading = false);
        
        final loanValue = _loanController.text.trim();
        final formattedLoan = loanValue.isNotEmpty ? "RM $loanValue" : "";

        final updatedData = {
          'education_level': _educationLevel,
          'employment_status': _employmentStatus,
          'marital_status': _maritalStatus,
          'dependent_number': _dependentController.text.trim(),
          'estimated_loan': formattedLoan,
        };

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Details updated successfully!"),
            backgroundColor: AppColors.success,
          ),
        );
        
        Navigator.pop(context, updatedData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
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

                const SectionTitle(title: "Edit Detailed Info"),
                const SizedBox(height: 8),
                const SectionSubtitle(
                  subtitle: "Provide additional details to improve your financial insights.",
                ),

                const SizedBox(height: 32),

                // --- Education Level ---
                const FormLabel(label: "Education Level"),
                CustomDropdownFormField(
                  value: _educationLevel,
                  items: _educationOptions,
                  hint: "Select Education",
                  onChanged: (val) => setState(() => _educationLevel = val),
                ),

                const SizedBox(height: 16),

                // --- Employment Status ---
                const FormLabel(label: "Employment Status"),
                CustomDropdownFormField(
                  value: _employmentStatus,
                  items: _employmentOptions,
                  hint: "Select Status",
                  onChanged: (val) => setState(() => _employmentStatus = val),
                ),

                const SizedBox(height: 16),

                // --- Marital Status ---
                const FormLabel(label: "Marital Status"),
                CustomDropdownFormField(
                  value: _maritalStatus,
                  items: _maritalOptions,
                  hint: "Select Status",
                  onChanged: (val) => setState(() => _maritalStatus = val),
                ),

                const SizedBox(height: 16),

                // --- Dependent Number ---
                const FormLabel(label: "Number of Dependents"),
                CustomTextFormField(
                  controller: _dependentController,
                  hint: "e.g. 0, 2, 4",
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // --- Estimated Loan ---
                const FormLabel(label: "Estimated Loan (RM)"),
                CustomTextFormField(
                  controller: _loanController,
                  hint: "e.g. 12000",
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return "Please enter a valid amount";
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                Text(
                  "Total estimated value of current loans (Car, House, PTPTN, etc.)",
                  style: AppTypography.caption.copyWith(color: AppColors.greyText),
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