import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/entities/detailed.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds the profile section of the Gemini prompt with user and optional detailed information
class ProfileContextBuilder {
  /// Build comprehensive profile section for Gemini prompt
  static String buildProfileSection({
    required User user,
    required int accountCount,
    required double totalAssets,
    required List<Account> accounts,
    Detailed? detailed,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('**USER PROFILE:**');
    buffer.writeln('Email: ${user.email ?? 'N/A'}');
    buffer.writeln(
      'Member Since: ${_formatDate(DateTime.parse(user.createdAt))}',
    );
    buffer.writeln();

    buffer.writeln('**FINANCIAL PROFILE:**');
    buffer.writeln('Total Accounts: $accountCount');
    buffer.writeln('Total Assets: \$${totalAssets.toStringAsFixed(2)}');

    // Include estimated loan if provided
    if (detailed?.estimatedLoan != null && detailed!.estimatedLoan! > 0) {
      buffer.writeln(
        'Outstanding Loans: \$${detailed.estimatedLoan!.toStringAsFixed(2)}',
      );
    }

    buffer.writeln();

    // Add account breakdown
    if (accounts.isNotEmpty) {
      buffer.writeln('**ACCOUNT BREAKDOWN:**');
      for (final account in accounts) {
        final balance = account.currentBalance;
        buffer.writeln(
          '- ${account.name} (${account.type}): \$${balance.toStringAsFixed(2)}',
        );
      }
      buffer.writeln();
    }

    // Optional personal details section
    if (detailed != null && _hasDetailedData(detailed)) {
      buffer.writeln('**PERSONAL DETAILS:**');

      if (detailed.employmentStatus != null &&
          detailed.employmentStatus!.isNotEmpty) {
        buffer.writeln('Employment: ${detailed.employmentStatus}');
      }
      if (detailed.educationLevel != null &&
          detailed.educationLevel!.isNotEmpty) {
        buffer.writeln('Education: ${detailed.educationLevel}');
      }
      if (detailed.maritalStatus != null &&
          detailed.maritalStatus!.isNotEmpty) {
        buffer.writeln('Marital Status: ${detailed.maritalStatus}');
      }
      if (detailed.dependentNumber != null && detailed.dependentNumber! > 0) {
        buffer.writeln('Dependents: ${detailed.dependentNumber}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Check if Detailed entity has any meaningful data
  static bool _hasDetailedData(Detailed detailed) {
    return (detailed.employmentStatus != null &&
            detailed.employmentStatus!.isNotEmpty) ||
        (detailed.educationLevel != null &&
            detailed.educationLevel!.isNotEmpty) ||
        (detailed.maritalStatus != null &&
            detailed.maritalStatus!.isNotEmpty) ||
        (detailed.dependentNumber != null && detailed.dependentNumber! > 0) ||
        (detailed.estimatedLoan != null && detailed.estimatedLoan! > 0);
  }

  /// Format DateTime for display
  static String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
