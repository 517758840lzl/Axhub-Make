import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loan_calculator_flutter/app.dart';
import 'package:loan_calculator_flutter/data/intl_init.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('启动后进入计算页', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeAppIntl();

    await tester.pumpWidget(const LoanCalculatorApp());
    await tester.pump();
    // 跳过启动动画
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(find.text('智能贷款试算'), findsOneWidget);
    expect(find.text('计算'), findsWidgets);
  });
}
