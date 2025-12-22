import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cashlytics/core/config/detailed_constants.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:cashlytics/data/repositories/detailed_repository_impl.dart';
import 'package:cashlytics/domain/entities/detailed.dart';
import 'package:cashlytics/domain/repositories/detailed_repository.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

class EditDetailInformationPage extends StatefulWidget {
  final Detailed? currentDetails;

  const EditDetailInformationPage({super.key, this.currentDetails});

  @override
  State<EditDetailInformationPage> createState() =>
      _EditDetailInformationPageState();
}

class _EditDetailInformationPageState extends State<EditDetailInformationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final DetailedRepository _detailedRepository;
  late final AuthService _authService;

  // Controllers
  late final TextEditingController _dependentController;
  late final TextEditingController _loanController;

  // Dropdown Values
  String? _educationLevel;
  String? _employmentStatus;
  String? _maritalStatus;

  @override
  void initState() {
    super.initState();
    _detailedRepository = DetailedRepositoryImpl();
    _authService = AuthService();
    _dependentController = TextEditingController();
    _loanController = TextEditingController();
    _initializeData();
  }

  void _initializeData() {
    if (widget.currentDetails == null) return;

    final data = widget.currentDetails!;

    _dependentController.text = data.dependentNumber.toString();
    _loanController.text = data.estimatedLoan?.toStringAsFixed(2) ?? '0';

    // Convert database values to UI display values
    _educationLevel = DetailedConstants.toDisplayValue(
      data.educationLevel,
      DetailedConstants.educationMap,
    );
    _employmentStatus = DetailedConstants.toDisplayValue(
      data.employmentStatus,
      DetailedConstants.employmentMap,
    );
    _maritalStatus = DetailedConstants.toDisplayValue(
      data.maritalStatus,
      DetailedConstants.maritalMap,
    );
  }

  @override
  void dispose() {
    _dependentController.dispose();
    _loanController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Parse values
      final dependentNum = int.tryParse(_dependentController.text.trim()) ?? 0;
      final loanAmount = double.tryParse(_loanController.text.trim()) ?? 0.0;

      // Create or update Detailed entity
      // Convert UI display values to database format
      final detailed = Detailed(
        id: widget.currentDetails?.id,
        userId: currentUser.id,
        educationLevel: DetailedConstants.toDbValue(
          _educationLevel,
          DetailedConstants.educationMap,
        ),
        employmentStatus: DetailedConstants.toDbValue(
          _employmentStatus,
          DetailedConstants.employmentMap,
        ),
        maritalStatus: DetailedConstants.toDbValue(
          _maritalStatus,
          DetailedConstants.maritalMap,
        ),
        dependentNumber: dependentNum,
        estimatedLoan: loanAmount,
        createdAt: widget.currentDetails?.createdAt,
        updatedAt: widget.currentDetails?.updatedAt,
      );

      // Save to database
      final savedDetailed = await _detailedRepository.upsertDetailed(detailed);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Details updated successfully!"),
            backgroundColor: AppColors.success,
          ),
        );

        // Return the saved entity with generated fields
        Navigator.pop(context, savedDetailed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save details: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                  subtitle:
                      "Provide additional details to improve your financial insights.",
                ),

                const SizedBox(height: 32),

                // --- Education Level ---
                const FormLabel(label: "Education Level"),
                CustomDropdownFormField(
                  value: _educationLevel,
                  items: DetailedConstants.educationOptions,
                  hint: "Select Education",
                  onChanged: (val) => setState(() => _educationLevel = val),
                ),

                const SizedBox(height: 16),

                // --- Employment Status ---
                const FormLabel(label: "Employment Status"),
                CustomDropdownFormField(
                  value: _employmentStatus,
                  items: DetailedConstants.employmentOptions,
                  hint: "Select Status",
                  onChanged: (val) => setState(() => _employmentStatus = val),
                ),

                const SizedBox(height: 16),

                // --- Marital Status ---
                const FormLabel(label: "Marital Status"),
                CustomDropdownFormField(
                  value: _maritalStatus,
                  items: DetailedConstants.maritalOptions,
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                  style: AppTypography.caption.copyWith(
                    color: AppColors.greyText,
                  ),
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
