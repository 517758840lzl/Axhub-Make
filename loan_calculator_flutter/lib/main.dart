import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/intl_init.dart';
import 'theme/revolut_theme.dart';

Future<void> main() async {
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  if (kIsWeb) {
    throw UnsupportedError('loan_calculator_flutter runs on iOS and Android. Use an iOS or Android device.');
  }
  // Status and navigation bars use the page canvas color.
  SystemChrome.setSystemUIOverlayStyle(revolutSystemUi);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeAppIntl();
  runApp(const LoanCalculatorApp());
}
