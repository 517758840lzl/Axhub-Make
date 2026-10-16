import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/intl_init.dart';
import 'theme/revolut_theme.dart';

Future<void> main() async {
  debugPrint('amake-demo push check');
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    throw UnsupportedError('loan_calculator_flutter 仅支持 iOS 与 Android，请用 iOS 模拟器或 Android 模拟器运行');
  }
  // 状态栏 / 导航栏与页面画布同色，避免灰条断层
  SystemChrome.setSystemUIOverlayStyle(revolutSystemUi);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeAppIntl();
  runApp(const LoanCalculatorApp());
}
