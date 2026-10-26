import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loan_calculator_flutter/app.dart';
import 'package:loan_calculator_flutter/data/intl_init.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens the calc page after launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeAppIntl();

    await tester.pumpWidget(const LoanCalculatorApp());
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(find.text('LoanCalcWise'), findsWidgets);
    expect(find.text('Calc'), findsWidgets);
  });
}
