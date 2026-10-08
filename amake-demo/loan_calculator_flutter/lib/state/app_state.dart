import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../data/calc.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/storage_service.dart';
import '../data/tags.dart';

enum AppRoute {
  calc,
  calcResult,
  amortization,
  savings,
  savingsDetail,
  savingsNew,
  ledger,
  ledgerNew,
  ledgerCalcDetail,
  ledgerManualDetail,
  profile,
  profileSettings,
  profileData,
  profileAbout,
}

const tabRoots = [
  AppRoute.calc,
  AppRoute.savings,
  AppRoute.ledger,
  AppRoute.profile,
];

AppRoute tabRootForIndex(int i) => tabRoots[i.clamp(0, 3)];

int tabIndexForRoute(AppRoute route) {
  if (_routePrefix(route).startsWith('calc')) return 0;
  if (_routePrefix(route).startsWith('savings')) return 1;
  if (_routePrefix(route).startsWith('ledger')) return 2;
  return 3;
}

String _routePrefix(AppRoute r) => r.name;

bool showTabBarForRoute(AppRoute route) => tabRoots.contains(route);

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  final _storage = StorageService();
  bool _ready = false;
  bool get ready => _ready;

  UserProfile _profile = UserProfile(
    nickname: '借款人',
    avatar: '🧑‍💼',
    createdAt: DateTime.now().toIso8601String(),
  );
  AppSettings _settings = AppSettings(currencyCode: 'CNY', decimals: 2, theme: 'light');
  List<SavedCalculation> _calculations = [];
  List<ManualLedgerEntry> _ledgerEntries = [];
  List<SavingsGoal> _savingsGoals = [];
  CalcResult? _pendingResult;
  String? _toast;
  Timer? _toastTimer;

  final List<AppRoute> _routeStack = [AppRoute.calc];
  String? detailId;
  String? savingsPrefill;

  UserProfile get profile => _profile;
  AppSettings get settings => _settings;
  List<SavedCalculation> get calculations => _calculations;
  List<ManualLedgerEntry> get ledgerEntries => _ledgerEntries;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  CalcResult? get pendingResult => _pendingResult;
  String? get toast => _toast;
  AppRoute get route => _routeStack.last;
  int get activeTabIndex => tabIndexForRoute(route);

  String money(double n) => formatMoney(n, _settings);

  Future<void> _init() async {
    await _storage.seedIfNeeded();
    _profile = await _storage.getProfile();
    _settings = await _storage.getSettings();
    _calculations = await _storage.getCalculations();
    _ledgerEntries = await _storage.getLedgerEntries();
    _savingsGoals = await _storage.getSavingsGoals();
    _ready = true;
    notifyListeners();
  }

  void setPendingResult(CalcResult? r) {
    _pendingResult = r;
    notifyListeners();
  }

  void goTab(int index) {
    final root = tabRootForIndex(index);
    _routeStack
      ..clear()
      ..add(root);
    detailId = null;
    savingsPrefill = null;
    notifyListeners();
  }

  void push(AppRoute r, {String? id, String? prefill}) {
    _routeStack.add(r);
    if (id != null) detailId = id;
    if (prefill != null) savingsPrefill = prefill;
    notifyListeners();
  }

  void pop() {
    if (_routeStack.length <= 1) return;
    _routeStack.removeLast();
    final current = _routeStack.last;
    if (!_needsDetailId(current)) detailId = null;
    if (current != AppRoute.savingsNew) savingsPrefill = null;
    notifyListeners();
  }

  void replaceRoute(AppRoute r, {String? id, String? prefill}) {
    if (_routeStack.isNotEmpty) _routeStack.removeLast();
    _routeStack.add(r);
    detailId = id;
    if (prefill != null) savingsPrefill = prefill;
    notifyListeners();
  }

  bool _needsDetailId(AppRoute r) =>
      r == AppRoute.savingsDetail ||
      r == AppRoute.ledgerCalcDetail ||
      r == AppRoute.ledgerManualDetail;

  void showToast(String msg) {
    _toastTimer?.cancel();
    _toast = msg;
    notifyListeners();
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      _toast = null;
      notifyListeners();
    });
  }

  Future<void> updateProfile(UserProfile p) async {
    await _storage.saveProfile(p);
    _profile = p;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings s) async {
    await _storage.saveSettings(s);
    _settings = s;
    notifyListeners();
  }

  Future<void> persistCalculations(List<SavedCalculation> list) async {
    await _storage.saveCalculations(list);
    _calculations = list;
    notifyListeners();
  }

  Future<void> persistLedger(List<ManualLedgerEntry> list) async {
    await _storage.saveLedgerEntries(list);
    _ledgerEntries = list;
    notifyListeners();
  }

  Future<void> persistSavings(List<SavingsGoal> list) async {
    await _storage.saveSavingsGoals(list);
    _savingsGoals = list;
    notifyListeners();
  }

  Future<void> saveCalcToLedger(CalcResult result) async {
    final input = result.input;
    final item = SavedCalculation(
      id: uid('calc'),
      createdAt: DateTime.now().toIso8601String(),
      favorite: false,
      note: input.label ?? modeLabel(input.mode),
      tags: defaultTagsForCategory(input.category),
      result: result,
    );
    await persistCalculations([item, ..._calculations]);
    showToast('已保存到记账');
  }

  Future<void> clearBusiness() async {
    await _storage.clearBusiness();
    _calculations = [];
    _ledgerEntries = [];
    _savingsGoals = [];
    notifyListeners();
  }

  Future<void> exportData() async {
    final json = await _storage.exportAll();
    await Share.share(
      json,
      subject: 'loan-calc-backup-${DateTime.now().millisecondsSinceEpoch}.json',
    );
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
