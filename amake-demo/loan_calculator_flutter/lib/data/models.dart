enum RepaymentMode { equalPayment, equalPrincipal }

enum LoanCategory { mortgage, auto, personal, other }

enum LedgerDirection { expense, income }

class CalcInput {
  CalcInput({
    required this.principal,
    required this.annualRatePercent,
    required this.termMonths,
    required this.mode,
    required this.category,
    this.label,
  });

  final double principal;
  final double annualRatePercent;
  final int termMonths;
  final RepaymentMode mode;
  final LoanCategory category;
  final String? label;

  Map<String, dynamic> toJson() => {
        'principal': principal,
        'annualRatePercent': annualRatePercent,
        'termMonths': termMonths,
        'mode': mode == RepaymentMode.equalPayment ? 'equal-payment' : 'equal-principal',
        'category': category.name,
        'label': label,
      };

  factory CalcInput.fromJson(Map<String, dynamic> j) => CalcInput(
        principal: (j['principal'] as num).toDouble(),
        annualRatePercent: (j['annualRatePercent'] as num).toDouble(),
        termMonths: j['termMonths'] as int,
        mode: (j['mode'] as String?) == 'equal-principal'
            ? RepaymentMode.equalPrincipal
            : RepaymentMode.equalPayment,
        category: LoanCategory.values.byName(j['category'] as String? ?? 'mortgage'),
        label: j['label'] as String?,
      );
}

class AmortizationRow {
  AmortizationRow({
    required this.period,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });

  final int period;
  final double payment;
  final double principal;
  final double interest;
  final double balance;

  Map<String, dynamic> toJson() => {
        'period': period,
        'payment': payment,
        'principal': principal,
        'interest': interest,
        'balance': balance,
      };

  factory AmortizationRow.fromJson(Map<String, dynamic> j) => AmortizationRow(
        period: j['period'] as int,
        payment: (j['payment'] as num).toDouble(),
        principal: (j['principal'] as num).toDouble(),
        interest: (j['interest'] as num).toDouble(),
        balance: (j['balance'] as num).toDouble(),
      );
}

class CalcResult {
  CalcResult({
    required this.input,
    required this.monthlyPayment,
    required this.firstMonthPayment,
    required this.lastMonthPayment,
    required this.totalInterest,
    required this.totalPayment,
    required this.schedule,
  });

  final CalcInput input;
  final double monthlyPayment;
  final double firstMonthPayment;
  final double lastMonthPayment;
  final double totalInterest;
  final double totalPayment;
  final List<AmortizationRow> schedule;

  Map<String, dynamic> toJson() => {
        'input': input.toJson(),
        'monthlyPayment': monthlyPayment,
        'firstMonthPayment': firstMonthPayment,
        'lastMonthPayment': lastMonthPayment,
        'totalInterest': totalInterest,
        'totalPayment': totalPayment,
        'schedule': schedule.map((e) => e.toJson()).toList(),
      };

  factory CalcResult.fromJson(Map<String, dynamic> j) => CalcResult(
        input: CalcInput.fromJson(j['input'] as Map<String, dynamic>),
        monthlyPayment: (j['monthlyPayment'] as num).toDouble(),
        firstMonthPayment: (j['firstMonthPayment'] as num).toDouble(),
        lastMonthPayment: (j['lastMonthPayment'] as num).toDouble(),
        totalInterest: (j['totalInterest'] as num).toDouble(),
        totalPayment: (j['totalPayment'] as num).toDouble(),
        schedule: (j['schedule'] as List)
            .map((e) => AmortizationRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SavedCalculation {
  SavedCalculation({
    required this.id,
    required this.createdAt,
    required this.favorite,
    required this.note,
    required this.tags,
    required this.result,
  });

  final String id;
  final String createdAt;
  final bool favorite;
  final String note;
  final List<String> tags;
  final CalcResult result;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt,
        'favorite': favorite,
        'note': note,
        'tags': tags,
        'result': result.toJson(),
      };

  factory SavedCalculation.fromJson(Map<String, dynamic> j) => SavedCalculation(
        id: j['id'] as String,
        createdAt: j['createdAt'] as String,
        favorite: j['favorite'] as bool? ?? false,
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        result: CalcResult.fromJson(j['result'] as Map<String, dynamic>),
      );

  SavedCalculation copyWith({bool? favorite, List<String>? tags, String? note}) =>
      SavedCalculation(
        id: id,
        createdAt: createdAt,
        favorite: favorite ?? this.favorite,
        note: note ?? this.note,
        tags: tags ?? this.tags,
        result: result,
      );
}

class ManualLedgerEntry {
  ManualLedgerEntry({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.amount,
    required this.direction,
    required this.tags,
    required this.note,
  });

  final String id;
  final String createdAt;
  final String title;
  final double amount;
  final LedgerDirection direction;
  final List<String> tags;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt,
        'title': title,
        'amount': amount,
        'direction': direction.name,
        'tags': tags,
        'note': note,
      };

  factory ManualLedgerEntry.fromJson(Map<String, dynamic> j) => ManualLedgerEntry(
        id: j['id'] as String,
        createdAt: j['createdAt'] as String,
        title: j['title'] as String,
        amount: (j['amount'] as num).toDouble(),
        direction: (j['direction'] as String?) == 'income'
            ? LedgerDirection.income
            : LedgerDirection.expense,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        note: j['note'] as String? ?? '',
      );

  ManualLedgerEntry copyWith({List<String>? tags, String? note}) => ManualLedgerEntry(
        id: id,
        createdAt: createdAt,
        title: title,
        amount: amount,
        direction: direction,
        tags: tags ?? this.tags,
        note: note ?? this.note,
      );
}

class SavingsTransaction {
  SavingsTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.note,
    required this.at,
  });

  final String id;
  final double amount;
  final String type;
  final String note;
  final String at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'note': note,
        'at': at,
      };

  factory SavingsTransaction.fromJson(Map<String, dynamic> j) => SavingsTransaction(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        type: j['type'] as String,
        note: j['note'] as String? ?? '',
        at: j['at'] as String,
      );
}

class SavingsGoal {
  SavingsGoal({
    required this.id,
    required this.name,
    required this.target,
    required this.current,
    required this.deadline,
    required this.linkedCalcId,
    required this.transactions,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double target;
  final double current;
  final String? deadline;
  final String? linkedCalcId;
  final List<SavingsTransaction> transactions;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'current': current,
        'deadline': deadline,
        'linkedCalcId': linkedCalcId,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
        id: j['id'] as String,
        name: j['name'] as String,
        target: (j['target'] as num).toDouble(),
        current: (j['current'] as num).toDouble(),
        deadline: j['deadline'] as String?,
        linkedCalcId: j['linkedCalcId'] as String?,
        transactions: (j['transactions'] as List?)
                ?.map((e) => SavingsTransaction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: j['createdAt'] as String,
      );

  SavingsGoal copyWith({
    double? current,
    List<SavingsTransaction>? transactions,
  }) =>
      SavingsGoal(
        id: id,
        name: name,
        target: target,
        current: current ?? this.current,
        deadline: deadline,
        linkedCalcId: linkedCalcId,
        transactions: transactions ?? this.transactions,
        createdAt: createdAt,
      );
}

class UserProfile {
  UserProfile({required this.nickname, required this.avatar, required this.createdAt});

  final String nickname;
  final String avatar;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'avatar': avatar,
        'createdAt': createdAt,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        nickname: j['nickname'] as String? ?? '借款人',
        avatar: j['avatar'] as String? ?? '🧑‍💼',
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );
}

class AppSettings {
  AppSettings({
    required this.currencyCode,
    required this.decimals,
    required this.theme,
  });

  final String currencyCode;
  final int decimals;
  final String theme;

  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        'decimals': decimals,
        'theme': theme,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        currencyCode: j['currencyCode'] as String? ?? 'CNY',
        decimals: j['decimals'] as int? ?? 2,
        theme: j['theme'] as String? ?? 'light',
      );
}
