import 'package:cashlytics/domain/entities/account.dart';
import 'package:flutter/foundation.dart';

import 'package:cashlytics/core/services/gemini/gemini_client.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:cashlytics/core/utils/ai_insights/profile_context_builder.dart';
import 'package:cashlytics/core/utils/ai_insights/transaction_analyzer.dart';
import 'package:cashlytics/data/models/ai_insight_response.dart';
import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/data/repositories/ai_report_repository_impl.dart';
import 'package:cashlytics/domain/entities/ai_report.dart';
import 'package:cashlytics/domain/entities/account_transaction_view.dart';
import 'package:cashlytics/domain/entities/detailed.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/usecases/accounts/get_account_transactions.dart';
import 'package:cashlytics/data/repositories/detailed_repository_impl.dart';

/// Orchestrates AI insight generation: fetches data → calls Gemini → saves report
class AiInsightsService {
  final AuthService _authService = AuthService();
  late final GetAccounts _getAccounts;
  late final GetAccountTransactions _getAccountTransactions;
  final AiReportRepositoryImpl _aiReportRepository = AiReportRepositoryImpl();
  final DetailedRepositoryImpl _detailedRepository = DetailedRepositoryImpl();
  late final GeminiClient _geminiClient;

  AiInsightsService() {
    _getAccounts = GetAccounts(AccountRepositoryImpl());
    _getAccountTransactions = GetAccountTransactions(AccountRepositoryImpl());
    try {
      _geminiClient = GeminiClient();
    } catch (e) {
      debugPrint('[AiInsightsService] Warning: Gemini not initialized: $e');
      rethrow;
    }
  }

  /// Generate AI insights for current user's last 30 days of transactions
  ///
  /// Returns: AiReport with health score, suggestions, and insights
  /// Throws: Exception if user not authenticated or API fails
  Future<AiReport> generateInsights({bool forceRefresh = false}) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint(
        '[AiInsightsService] Starting insight generation for user: ${user.id}',
      );

      // Determine period
      final now = DateTime.now();
      final monthKey =
          '${now.month.toString().padLeft(2, '0')}-${now.year}'; // Changed from YYYY-MM to MM-YYYY

      // Check if report already exists for this month (unless forced refresh)
      if (!forceRefresh) {
        final existing = await _aiReportRepository.getLatestReport(user.id);
        if (existing != null && existing.month == monthKey) {
          debugPrint('[AiInsightsService] Using cached report for $monthKey');
          return existing;
        }
      }

      // 1. Fetch user accounts
      final accounts = await _getAccounts(user.id);
      debugPrint('[AiInsightsService] Fetched ${accounts.length} accounts');

      if (accounts.isEmpty) {
        throw Exception('No accounts found for user');
      }

      // 2. Calculate total assets
      final totalAssets = accounts.fold<double>(
        0,
        (sum, acc) => sum + acc.currentBalance,
      );

      // 3. Fetch all transactions from last 30 days
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final allTransactions = <AccountTransactionView>[];

      for (final account in accounts) {
        final txns = await _getAccountTransactions(account.id!);
        final filtered = txns
            .where((t) => t.date.isAfter(thirtyDaysAgo))
            .toList();
        allTransactions.addAll(filtered);
      }

      debugPrint(
        '[AiInsightsService] Fetched ${allTransactions.length} transactions',
      );

      // 4. Fetch optional detailed profile information
      Detailed? detailed;
      try {
        detailed = await _detailedRepository.getDetailedByUserId(user.id);
      } catch (e) {
        debugPrint('[AiInsightsService] No detailed profile found: $e');
      }

      // 5. Build Gemini prompt
      final prompt = _buildGeminiPrompt(
        user: user,
        accountCount: accounts.length,
        totalAssets: totalAssets,
        accounts: accounts,
        transactions: allTransactions,
        detailed: detailed,
        period: monthKey,
      );

      debugPrint(
        '[AiInsightsService] Sending prompt to Gemini (${prompt.length} chars)',
      );
      debugPrint(prompt);

      // 6. Call Gemini API
      final geminiResponse = await _geminiClient.generateInsights(prompt);

      // 7. Extract and parse response
      final responseText = GeminiClient.extractResponseText(geminiResponse);
      debugPrint('[AiInsightsService] Gemini response received');
      debugPrint(responseText);

      final aiInsight = AiInsightResponse.fromJson(responseText);

      // 8. Create and save AI Report
      final report = AiReport(
        userId: user.id,
        title: 'Financial Insights - ${_getMonthName(now.month)} ${now.year}',
        description: 'AI-generated financial health analysis',
        body: responseText,
        month: monthKey,
        healthScore: aiInsight.healthScore,
        createdAt: now,
      );

      final saved = await _aiReportRepository.upsertAiReport(report);
      debugPrint('[AiInsightsService] Report saved with ID: ${saved.id}');

      return saved;
    } catch (e) {
      debugPrint('[AiInsightsService] Error: $e');
      rethrow;
    }
  }

  /// Build the complete Gemini prompt
  String _buildGeminiPrompt({
    required dynamic user,
    required int accountCount,
    required double totalAssets,
    required List<Account> accounts,
    required List<AccountTransactionView> transactions,
    Detailed? detailed,
    required String period,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      'You are a financial advisor with expertise in personal finance, budgeting, and wealth management.',
    );
    buffer.writeln(
      'Analyze this user\'s financial profile and transactions for the period: $period',
    );
    buffer.writeln('Provide actionable insights and specific recommendations.');
    buffer.writeln();

    // Profile section
    buffer.write(
      ProfileContextBuilder.buildProfileSection(
        user: user,
        accountCount: accountCount,
        totalAssets: totalAssets,
        accounts: accounts,
        detailed: detailed,
      ),
    );

    // Transaction analysis
    buffer.write(TransactionAnalyzer.formatTransactionsSummary(transactions));

    // Detailed transactions
    if (transactions.isNotEmpty) {
      buffer.write(
        TransactionAnalyzer.formatTransactionsList(
          transactions,
          maxTransactions: 50,
        ),
      );
      buffer.write(TransactionAnalyzer.getCategoryBreakdown(transactions));
    }

    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(
      'Based on this analysis, provide a JSON response with the following structure:',
    );
    buffer.writeln('{');
    buffer.writeln('  "healthScore": <integer 0-100>,');
    buffer.writeln(
      '  "insights": "<brief paragraph about financial patterns and health>",',
    );
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "title": "<suggestion title>",');
    buffer.writeln('      "body": "<detailed explanation>",');
    buffer.writeln(
      '      "category": "<category like spending, savings, budgeting>"',
    );
    buffer.writeln('    }');
    buffer.writeln('    ... (provide exactly 3 suggestions)');
    buffer.writeln('  ],');
    buffer.writeln(
      '  "recommendations": ["<action 1>", "<action 2>", "<action 3>"]',
    );
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('Return ONLY valid JSON, no markdown formatting.');

    return buffer.toString();
  }

  /// Get month name from month number
  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
