import 'i18n.dart';
import 'models.dart';

double _round2(double n) => (n * 100).roundToDouble() / 100;

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
  var monthly = 0.0;
  if (r == 0) {
    monthly = p / n;
  } else {
    final pow = _pow1p(r, n);
    monthly = (p * r * pow) / (pow - 1);
  }
  monthly = _round2(monthly);

  final schedule = <AmortizationRow>[];
  var balance = p;
  var totalInterest = 0.0;

  for (var period = 1; period <= n; period++) {
    final interest = r == 0 ? 0.0 : _round2(balance * r);
    var principalPart = _round2(monthly - interest);
    if (period == n) principalPart = _round2(balance);
    final payment = _round2(principalPart + interest);
    balance = _round2(balance - principalPart);
    if (balance < 0) balance = 0;
    totalInterest += interest;
    schedule.add(AmortizationRow(
      period: period,
      payment: payment,
      principal: principalPart,
      interest: interest,
      balance: balance,
    ));
  }

  return CalcResult(
    input: input,
    monthlyPayment: monthly,
    firstMonthPayment: schedule.first.payment,
    lastMonthPayment: schedule.last.payment,
    totalInterest: _round2(totalInterest),
    totalPayment: _round2(p + totalInterest),
    schedule: schedule,
  );
}

CalcResult _equalPrincipal(double p, double r, int n, CalcInput input) {
  final monthlyPrincipal = p / n;
  final schedule = <AmortizationRow>[];
  var balance = p;
  var totalInterest = 0.0;

  for (var period = 1; period <= n; period++) {
    final interest = r == 0 ? 0.0 : _round2(balance * r);
    final principalPart = _round2(period == n ? balance : monthlyPrincipal);
    final payment = _round2(principalPart + interest);
    balance = _round2(balance - principalPart);
    if (balance < 0) balance = 0;
    totalInterest += interest;
    schedule.add(AmortizationRow(
      period: period,
      payment: payment,
      principal: principalPart,
      interest: interest,
      balance: balance,
    ));
  }

  return CalcResult(
    input: input,
    monthlyPayment: schedule.first.payment,
    firstMonthPayment: schedule.first.payment,
    lastMonthPayment: schedule.last.payment,
    totalInterest: _round2(totalInterest),
    totalPayment: _round2(p + totalInterest),
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
