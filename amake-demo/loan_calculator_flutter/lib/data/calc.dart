import 'models.dart';

double _round2(double n) => (n * 100).roundToDouble() / 100;

CalcResult computeLoan(CalcInput input) {
  final p = input.principal;
  final n = input.termMonths;
  final r = input.annualRatePercent / 100 / 12;
  if (p <= 0 || n <= 0) throw ArgumentError('invalid');
  if (input.mode == RepaymentMode.equalPayment) {
    return _equalPayment(p, r, n, input);
  }
  return _equalPrincipal(p, r, n, input);
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

String modeLabel(RepaymentMode mode) =>
    mode == RepaymentMode.equalPayment ? '等额本息' : '等额本金';

String categoryLabel(LoanCategory c) => switch (c) {
      LoanCategory.mortgage => '房贷',
      LoanCategory.auto => '车贷',
      LoanCategory.personal => '消费',
      LoanCategory.other => '其他',
    };
