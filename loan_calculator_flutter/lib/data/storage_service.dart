import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'calc.dart';
import 'currencies.dart';
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
        nickname: '',
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
      return AppSettings(currencyCode: defaultCurrencyCode, decimals: 2, theme: 'light');
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
    await prefs.setString(_meta, jsonEncode({'schemaVersion': 2, 'seeded': v}));
  }

  Future<void> clearBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_calculations);
    await prefs.remove(_savings);
    await prefs.remove(_ledger);
  }

  Future<void> relabelExampleSavings() async {
    const storedName = '示例月供缓冲金';
    const legacyNames = {'月供缓冲金', 'Payment buffer', 'Colchón de cuota'};
    final goals = await getSavingsGoals();
    var changed = false;
    final next = goals.map((g) {
      if (g.id != 'seed-goal-1' || !legacyNames.contains(g.name)) return g;
      changed = true;
      return g.copyWith(name: storedName);
    }).toList();
    if (changed) await saveSavingsGoals(next);
  }

  Future<void> seedIfNeeded() async {
    if (await getSeeded()) {
      await relabelExampleSavings();
      return;
    }
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
    await saveSavingsGoals([
      SavingsGoal(
        id: 'seed-goal-1',
        name: '示例月供缓冲金',
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
