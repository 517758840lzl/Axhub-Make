import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/revolut_theme.dart';
import '../widgets/brand_logo.dart';

/// 全屏启动动画；[onComplete] 在动画结束且 [AppState.ready] 后调用
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _pulse;
  late final Animation<double> _ring;
  late final Animation<double> _scale;
  late final Animation<double> _fadeIn;
  late final Animation<double> _textFade;
  late final Animation<double> _exitFade;

  bool _minTimeDone = false;
  bool _animDone = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    _ring = CurvedAnimation(parent: _master, curve: const Interval(0, 0.45, curve: Curves.easeOutCubic));
    _scale = CurvedAnimation(parent: _master, curve: const Interval(0.15, 0.55, curve: Curves.elasticOut));
    _fadeIn = CurvedAnimation(parent: _master, curve: const Interval(0.1, 0.4, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _master, curve: const Interval(0.45, 0.75, curve: Curves.easeOut));
    _exitFade = CurvedAnimation(parent: _master, curve: const Interval(0.82, 1, curve: Curves.easeIn));

    unawaited(_master.forward());
    Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _minTimeDone = true);
    });
    _master.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _animDone = true);
        _tryFinish();
      }
    });
  }

  void _tryFinish() {
    if (_finished || !_minTimeDone || !_animDone) return;
    final app = context.read<AppState>();
    if (!app.ready) return;
    _finished = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _master.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryFinish());

    return AnimatedBuilder(
      animation: Listenable.merge([_master, _pulse]),
      builder: (context, _) {
        final glow = 0.35 + _pulse.value * 0.25;
        final opacity = (1 - _exitFade.value).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Material(
            color: RevolutColors.canvas,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    RevolutColors.canvas,
                    RevolutColors.brandSolid.withValues(alpha: 0.07),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _fadeIn,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.82, end: 1).animate(_scale),
                          child: BrandLogo(
                            size: 112,
                            ringProgress: _ring.value,
                            glow: glow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            Text(
                              '贷款计算器',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: RevolutColors.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '智能试算 · 本地隐私 · 储蓄规划',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: RevolutColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      FadeTransition(
                        opacity: _textFade,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: RevolutColors.brandSolid.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
