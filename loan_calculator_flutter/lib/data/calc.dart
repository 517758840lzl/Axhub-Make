import 'i18n.dart';
import 'models.dart';

double _round2(double n) => (n * 100).roundToDouble() / 100;

/// 首页实时摘要。舍入与 [computeLoan] 相同，但不生成逐期明细。
class LoanSummary {
  const LoanSummary({
    required this.input,
    required this.monthlyPayment,
    required this.firstMonthPayment,
    required this.totalInterest,
    required this.totalPayment,
  });

  final CalcInput input;
  final double monthlyPayment;
  final double firstMonthPayment;
  final double totalInterest;
  final double totalPayment;
}

CalcResult computeLoan(CalcInput input) {
  if (input.category == LoanCategory.dual && input.parts?.length == 2) {
    return computeDualLoan(input);
  }

  final p = input.principal;
  final n = input.termMonths;
  final r = input.annualRatePercent / 100 / 12;
  if (p <= 0 || n <= 0) throw ArgumentError('invalid');
  if (input.mode == RepaymentMode.equalPayment) {
    return _equalPayment(p, r, n, input);
  }
  return _equalPrincipal(p, r, n, input);
}

CalcInput _partToInput(DualLoanPart part, int index) => CalcInput(
      principal: part.principal,
      annualRatePercent: part.annualRatePercent,
      termMonths: part.termMonths,
      mode: part.mode,
      category: LoanCategory.other,
      label: part.label ?? 'Loan ${index + 1}',
    );

CalcResult computeDualLoan(CalcInput input) {
  final parts = input.parts;
  if (parts == null || parts.length != 2) throw ArgumentError('invalid dual');
  final a = computeLoan(_partToInput(parts[0], 0));
  final b = computeLoan(_partToInput(parts[1], 1));
  final principal = _round2(parts[0].principal + parts[1].principal);
  final totalInterest = _round2(a.totalInterest + b.totalInterest);
  final longer = a.schedule.length >= b.schedule.length ? a : b;

  return CalcResult(
    input: CalcInput(
      principal: principal,
      annualRatePercent: parts[0].annualRatePercent,
      termMonths: parts[0].termMonths > parts[1].termMonths
          ? parts[0].termMonths
          : parts[1].termMonths,
      mode: parts[0].mode,
      category: LoanCategory.dual,
      label: input.label,
      parts: parts,
    ),
    monthlyPayment: _round2(a.monthlyPayment + b.monthlyPayment),
    firstMonthPayment: _round2(a.firstMonthPayment + b.firstMonthPayment),
    lastMonthPayment: _round2(
      (a.schedule.isEmpty ? 0 : a.schedule.last.payment) +
          (b.schedule.isEmpty ? 0 : b.schedule.last.payment),
    ),
    totalInterest: totalInterest,
    totalPayment: _round2(principal + totalInterest),
    schedule: longer.schedule,
    partsResults: [a, b],
  );
}

CalcResult _equalPayment(double p, double r, int n, CalcInput input) {
  final monthly = _monthlyInstallment(p, r, n);
  final schedule = <AmortizationRow>[];
  final walked = _walkEqualPayment(p, r, n, monthly, schedule);
  return CalcResult(
    input: input,
    monthlyPayment: monthly,
    firstMonthPayment: walked.first,
    lastMonthPayment: walked.last,
    totalInterest: _round2(walked.interest),
    totalPayment: _round2(p + walked.interest),
    schedule: schedule,
  );
}

CalcResult _equalPrincipal(double p, double r, int n, CalcInput input) {
  final schedule = <AmortizationRow>[];
  final walked = _walkEqualPrincipal(p, r, n, schedule);
  return CalcResult(
    input: input,
    monthlyPayment: walked.first,
    firstMonthPayment: walked.first,
    lastMonthPayment: walked.last,
    totalInterest: _round2(walked.interest),
    totalPayment: _round2(p + walked.interest),
    schedule: schedule,
  );
}

double _pow1p(double r, int n) {
  var v = 1.0;
  for (var i = 0; i < n; i++) {
    v *= (1 + r);
  }
  return v;
}

String modeLabel(RepaymentMode mode, AppLocale locale) =>
    t(locale, mode == RepaymentMode.equalPayment ? 'mode.equalPayment' : 'mode.equalPrincipal');

String categoryLabel(LoanCategory c, AppLocale locale) => switch (c) {
      LoanCategory.mortgage => t(locale, 'cat.mortgage'),
      LoanCategory.auto => t(locale, 'cat.auto'),
      LoanCategory.personal => t(locale, 'cat.personal'),
      LoanCategory.dual => t(locale, 'cat.dual'),
      LoanCategory.other => t(locale, 'cat.other'),
    };

/// Fingerprint for duplicate-save detection (matches Web intent).
LoanSummary summarizeLoan(CalcInput input) {
  if (input.category == LoanCategory.dual && input.parts?.length == 2) {
    return _summarizeDual(input);
  }
  final p = input.principal;
  final n = input.termMonths;
  final r = input.annualRatePercent / 100 / 12;
  if (p <= 0 || n <= 0) throw ArgumentError('invalid');
  if (input.mode == RepaymentMode.equalPayment) {
    final monthly = _monthlyInstallment(p, r, n);
    final walked = _walkEqualPayment(p, r, n, monthly, null);
    return LoanSummary(
      input: input,
      monthlyPayment: monthly,
      firstMonthPayment: walked.first,
      totalInterest: _round2(walked.interest),
      totalPayment: _round2(p + walked.interest),
    );
  }
  final walked = _walkEqualPrincipal(p, r, n, null);
  return LoanSummary(
    input: input,
    monthlyPayment: walked.first,
    firstMonthPayment: walked.first,
    totalInterest: _round2(walked.interest),
    totalPayment: _round2(p + walked.interest),
  );
}

LoanSummary _summarizeDual(CalcInput input) {
  final parts = input.parts;
  if (parts == null || parts.length != 2) throw ArgumentError('invalid dual');
  final a = summarizeLoan(_partToInput(parts[0], 0));
  final b = summarizeLoan(_partToInput(parts[1], 1));
  final principal = _round2(parts[0].principal + parts[1].principal);
  final totalInterest = _round2(a.totalInterest + b.totalInterest);
  return LoanSummary(
    input: CalcInput(
      principal: principal,
      annualRatePercent: parts[0].annualRatePercent,
      termMonths: parts[0].termMonths > parts[1].termMonths
          ? parts[0].termMonths
          : parts[1].termMonths,
      mode: parts[0].mode,
      category: LoanCategory.dual,
      label: input.label,
      parts: parts,
    ),
    monthlyPayment: _round2(a.monthlyPayment + b.monthlyPayment),
    firstMonthPayment: _round2(a.firstMonthPayment + b.firstMonthPayment),
    totalInterest: totalInterest,
    totalPayment: _round2(principal + totalInterest),
  );
}

({double first, double last, double interest}) _walkEqualPayment(
  double p,
  double r,
  int n,
  double monthly,
  List<AmortizationRow>? schedule,
) {
  var balance = p;
  var totalInterest = 0.0;
  var first = monthly;
  var last = monthly;
  for (var period = 1; period <= n; period++) {
    final interest = r == 0 ? 0.0 : _round2(balance * r);
    var principalPart = _round2(monthly - interest);
    if (period == n) principalPart = _round2(balance);
    final payment = _round2(principalPart + interest);
    balance = _round2(balance - principalPart);
    if (balance < 0) balance = 0;
    totalInterest += interest;
    if (period == 1) first = payment;
    last = payment;
    schedule?.add(AmortizationRow(
      period: period,
      payment: payment,
      principal: principalPart,
      interest: interest,
      balance: balance,
    ));
  }
  return (first: first, last: last, interest: totalInterest);
}

({double first, double last, double interest}) _walkEqualPrincipal(
  double p,
  double r,
  int n,
  List<AmortizationRow>? schedule,
) {
  final monthlyPrincipal = p / n;
  var balance = p;
  var totalInterest = 0.0;
  var first = 0.0;
  var last = 0.0;
  for (var period = 1; period <= n; period++) {
    final interest = r == 0 ? 0.0 : _round2(balance * r);
    final principalPart = _round2(period == n ? balance : monthlyPrincipal);
    final payment = _round2(principalPart + interest);
    balance = _round2(balance - principalPart);
    if (balance < 0) balance = 0;
    totalInterest += interest;
    if (period == 1) first = payment;
    last = payment;
    schedule?.add(AmortizationRow(
      period: period,
      payment: payment,
      principal: principalPart,
      interest: interest,
      balance: balance,
    ));
  }
  return (first: first, last: last, interest: totalInterest);
}

double _monthlyInstallment(double p, double r, int n) {
  var monthly = 0.0;
  if (r == 0) {
    monthly = p / n;
  } else {
    final pow = _pow1p(r, n);
    monthly = (p * r * pow) / (pow - 1);
  }
  return _round2(monthly);
}

String calcFingerprint(CalcResult r) {
  final i = r.input;
  final parts = i.parts
          ?.map((p) =>
              '${p.principal}|${p.annualRatePercent}|${p.termMonths}|${p.mode.name}')
          .join(';') ??
      '';
  return [
    i.category.name,
    i.principal,
    i.annualRatePercent,
    i.termMonths,
    i.mode.name,
    i.vehiclePrice ?? '',
    i.downPayment ?? '',
    parts,
    r.monthlyPayment,
    r.totalInterest,
  ].join('|');
}
