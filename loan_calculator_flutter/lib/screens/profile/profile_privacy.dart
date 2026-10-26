import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../state/app_state.dart';
import '../../theme/revolut_theme.dart';
import '../../widgets/loan_widgets.dart';

class ProfilePrivacyScreen extends StatefulWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  State<ProfilePrivacyScreen> createState() => _ProfilePrivacyScreenState();
}

class _ProfilePrivacyScreenState extends State<ProfilePrivacyScreen> with WidgetsBindingObserver {
  static const _policyUrl = 'https://www.ligacaovital.com/privacy-policy.html';

  late final WebViewController _controller;
  var _loading = true;
  var _shown = false;
  var _mainFrameFailed = false;
  var _leftForGrant = false;
  var _reloadQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(RevolutColors.canvas)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _mainFrameFailed = false;
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (!mounted || _mainFrameFailed) {
              if (mounted) setState(() => _loading = false);
              return;
            }
            setState(() {
              _loading = false;
              _shown = true;
            });
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            _mainFrameFailed = true;
            _shown = false;
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final scheme = Uri.tryParse(request.url)?.scheme.toLowerCase() ?? '';
            if (scheme == 'http' ||
                scheme == 'https' ||
                scheme == 'about' ||
                scheme == 'data' ||
                scheme == 'file') {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );
    _openPolicy();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _leftForGrant = !_shown;
      return;
    }
    if (state == AppLifecycleState.resumed && _leftForGrant && !_shown) {
      _leftForGrant = false;
      _reloadAfterGrant();
    }
  }

  void _reloadAfterGrant() {
    if (_reloadQueued || _shown) return;
    _reloadQueued = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _reloadQueued = false;
      if (!mounted || _shown) return;
      _openPolicy();
    });
  }

  void _openPolicy() {
    _mainFrameFailed = false;
    if (mounted && !_loading) {
      setState(() => _loading = true);
    }
    _controller.loadRequest(Uri.parse(_policyUrl));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: LoanTopBar(onBack: () => app.pop(), title: app.tr('about.title')),
        ),
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: RevolutColors.brandSolid),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
