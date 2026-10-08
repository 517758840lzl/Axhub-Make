import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/intl_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    throw UnsupportedError('loan_calculator_flutter 仅支持 iOS 与 Android，请用 iOS 模拟器或 Android 模拟器运行');
  }
  await initializeAppIntl();
  runApp(const LoanCalculatorApp());
}
