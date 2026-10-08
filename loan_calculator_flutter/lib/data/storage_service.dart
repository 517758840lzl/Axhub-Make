import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'calc.dart';
import 'models.dart';
import 'tags.dart';

const _prefix = 'loan-calc:';

class StorageService {
  static const _profile = '${_prefix}profile';
  static const _settings = '${_prefix}settings';
  static const _calculations = '${_prefix}calculations';
  static const _ledger = '${_prefix}ledger-entries';
  static const _savings = '${_prefix}savings-goals';
  static const _meta = '${_prefix}meta';

  Future<UserProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profile);
    if (raw == null) {
      return UserProfile(
        nickname: '借款人',
        avatar: '🧑‍💼',
        createdAt: DateTime.now().toIso8601String(),
      );
    }
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profile, jsonEncode(p.toJson()));
  }

  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settings);
    if (raw == null) {
      return AppSettings(currencyCode: 'CNY', decimals: 2, theme: 'light');
    }
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settings, jsonEncode(s.toJson()));
  }

  Future<List<SavedCalculation>> getCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_calculations);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) {
      final c = SavedCalculation.fromJson(e as Map<String, dynamic>);
      final tags = c.tags.isNotEmpty
          ? normalizeTagList(c.tags)
          : defaultTagsForCategory(c.result.input.category);
      return c.copyWith(tags: tags);
    }).toList();
  }

  Future<void> saveCalculations(List<SavedCalculation> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calculations, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<List<ManualLedgerEntry>> getLedgerEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ledger);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ManualLedgerEntry.fromJson(e as Map<String, dynamic>))
        .map((e) => e.copyWith(tags: normalizeTagList(e.tags)))
        .toList();
  }

  Future<void> saveLedgerEntries(List<ManualLedgerEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ledger, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savings);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSavingsGoals(List<SavingsGoal> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savings, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<bool> getSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_meta);
    if (raw == null) return false;
    return (jsonDecode(raw) as Map<String, dynamic>)['seeded'] == true;
  }

  Future<void> setSeeded(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_meta, jsonEncode({'schemaVersion': 1, 'seeded': v}));
  }

  Future<void> clearBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_calculations);
    await prefs.remove(_savings);
    await prefs.remove(_ledger);
  }

  Future<String> exportAll() async {
    return jsonEncode({
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': (await getProfile()).toJson(),
      'settings': (await getSettings()).toJson(),
      'calculations': (await getCalculations()).map((e) => e.toJson()).toList(),
      'ledgerEntries': (await getLedgerEntries()).map((e) => e.toJson()).toList(),
      'savingsGoals': (await getSavingsGoals()).map((e) => e.toJson()).toList(),
    });
  }

  Future<void> seedIfNeeded() async {
    if (await getSeeded()) return;
    final sample = computeLoan(CalcInput(
      principal: 1000000,
      annualRatePercent: 4.2,
      termMonths: 360,
      mode: RepaymentMode.equalPayment,
      category: LoanCategory.mortgage,
      label: '示例房贷',
    ));
    await saveCalculations([
      SavedCalculation(
        id: 'seed-calc-1',
        createdAt: DateTime.now().toIso8601String(),
        favorite: true,
        note: '示例房贷方案',
        tags: const ['房贷', '月供'],
        result: sample,
      ),
    ]);
    await saveLedgerEntries([
      ManualLedgerEntry(
        id: 'seed-ledger-1',
        createdAt: DateTime.now().toIso8601String(),
        title: '本月房贷预留',
        amount: 4890,
        direction: LedgerDirection.expense,
        tags: const ['房贷', '月供'],
        note: '与试算方案配套的手动记账',
      ),
      ManualLedgerEntry(
        id: 'seed-ledger-2',
        createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        title: '公积金入账',
        amount: 3200,
        direction: LedgerDirection.income,
        tags: const ['房贷'],
        note: '示例收入',
      ),
    ]);
    await saveSavingsGoals([
      SavingsGoal(
        id: 'seed-goal-1',
        name: '月供缓冲金',
        target: 15000,
        current: 5200,
        deadline: null,
        linkedCalcId: 'seed-calc-1',
        createdAt: DateTime.now().toIso8601String(),
        transactions: [
          SavingsTransaction(
            id: 'seed-tx-1',
            amount: 5200,
            type: 'deposit',
            note: '初始存入',
            at: DateTime.now().toIso8601String(),
          ),
        ],
      ),
    ]);
    await setSeeded(true);
  }
}
