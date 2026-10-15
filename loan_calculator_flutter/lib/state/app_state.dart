import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../data/calc.dart';
import '../data/format.dart';
import '../data/i18n.dart';
import '../data/models.dart';
import '../data/storage_service.dart';
import '../data/tags.dart';

export '../data/format.dart' show uid;

enum AppRoute {
  calc,
  calcResult,
  amortization,
  compare,
  savings,
  savingsDetail,
  savingsNew,
  profile,
  profileSettings,
  profileData,
  profileAbout,
  savedList,
  savedDetail,
}

const tabRoots = [
  AppRoute.calc,
  AppRoute.savings,
  AppRoute.profile,
];

AppRoute tabRootForIndex(int i) => tabRoots[i.clamp(0, 2)];

int tabIndexForRoute(AppRoute route) {
  final name = route.name;
  if (name.startsWith('calc') || name == 'amortization' || name == 'compare') {
    return 0;
  }
  if (name.startsWith('savings')) return 1;
  return 2;
}

bool showTabBarForRoute(AppRoute route) => tabRoots.contains(route);

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  final _storage = StorageService();
  bool _ready = false;
  bool get ready => _ready;

  UserProfile _profile = UserProfile(
    nickname: '',
    avatar: '🧑‍💼',
    createdAt: DateTime.now().toIso8601String(),
  );
  AppSettings _settings = AppSettings(currencyCode: 'CNY', decimals: 2, theme: 'light');
  List<SavedCalculation> _calculations = [];
  List<ManualLedgerEntry> _ledgerEntries = [];
  List<SavingsGoal> _savingsGoals = [];
  CalcResult? _pendingResult;
  String? _pendingSavedId;
  final List<String> _compareIds = [];
  String? _toast;
  Timer? _toastTimer;

  final List<AppRoute> _routeStack = [AppRoute.calc];
  String? detailId;
  String? savingsPrefill;

  UserProfile get profile => _profile;
  AppSettings get settings => _settings;
  AppLocale get locale => _settings.locale;
  List<SavedCalculation> get calculations => _calculations;
  List<ManualLedgerEntry> get ledgerEntries => _ledgerEntries;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  CalcResult? get pendingResult => _pendingResult;
  String? get pendingSavedId => _pendingSavedId;
  List<String> get compareIds => List.unmodifiable(_compareIds);
  String? get toast => _toast;
  AppRoute get route => _routeStack.last;
  int get activeTabIndex => tabIndexForRoute(route);

  String money(double n) => formatMoney(n, _settings);
  String tr(String key, [Map<String, String>? params]) => t(locale, key, params);

  String displayNickname() => _profile.displayNickname(locale);

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

  void setPendingResult(CalcResult? r, {String? savedId}) {
    _pendingResult = r;
    _pendingSavedId = savedId;
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
      r == AppRoute.savingsDetail || r == AppRoute.savedDetail;

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

  bool isDuplicateSave(CalcResult result) {
    final fp = calcFingerprint(result);
    return _calculations.any((c) => calcFingerprint(c.result) == fp);
  }

  Future<void> saveCalc(CalcResult result) async {
    if (isDuplicateSave(result)) {
      showToast(tr('toast.alreadySaved'));
      return;
    }
    final input = result.input;
    final item = SavedCalculation(
      id: uid('calc'),
      createdAt: DateTime.now().toIso8601String(),
      favorite: false,
      note: input.label?.trim().isNotEmpty == true
          ? input.label!
          : modeLabel(input.mode, locale),
      tags: defaultTagsForCategory(input.category),
      result: result,
    );
    await persistCalculations([item, ..._calculations]);
    _pendingSavedId = item.id;
    showToast(tr('toast.savedProfile'));
  }

  void addToCompare(String id) {
    if (_compareIds.contains(id)) {
      showToast(tr('compare.added'));
      return;
    }
    if (_compareIds.length >= 3) {
      showToast(tr('compare.max'));
      return;
    }
    _compareIds.add(id);
    notifyListeners();
    showToast(tr('compare.added'));
  }

  void addPendingToCompare() {
    final r = _pendingResult;
    if (r == null) return;
    var id = _pendingSavedId;
    if (id == null) {
      final fp = calcFingerprint(r);
      for (final c in _calculations) {
        if (calcFingerprint(c.result) == fp) {
          id = c.id;
          break;
        }
      }
    }
    if (id != null) {
      addToCompare(id);
      return;
    }
    final tempId = 'pending:${calcFingerprint(r)}';
    if (_compareIds.contains(tempId)) {
      showToast(tr('compare.added'));
      return;
    }
    if (_compareIds.length >= 3) {
      showToast(tr('compare.max'));
      return;
    }
    _compareIds.add(tempId);
    notifyListeners();
    showToast(tr('compare.added'));
  }

  void removeFromCompare(String id) {
    _compareIds.remove(id);
    notifyListeners();
  }

  CalcResult? resultForCompareId(String id) {
    if (id.startsWith('pending:')) {
      return _pendingResult;
    }
    for (final c in _calculations) {
      if (c.id == id) return c.result;
    }
    return null;
  }

  Future<void> clearBusiness() async {
    await _storage.clearBusiness();
    _calculations = [];
    _ledgerEntries = [];
    _savingsGoals = [];
    _compareIds.clear();
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
