part of 'loan_screens.dart';

// --- Saved ---

/// Lucide star polygon, filled. The icon font only ships the outline.
class _FilledStar extends StatelessWidget {
  const _FilledStar({this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _FilledStarPainter(RevolutColors.brandSolid),
    );
  }
}

class _FilledStarPainter extends CustomPainter {
  const _FilledStarPainter(this.color);

  final Color color;

  static const _pts = <Offset>[
    Offset(12, 2),
    Offset(15.09, 8.26),
    Offset(22, 9.27),
    Offset(17, 14.14),
    Offset(18.18, 21.02),
    Offset(12, 17.77),
    Offset(5.82, 21.02),
    Offset(7, 14.14),
    Offset(2, 9.27),
    Offset(8.91, 8.26),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()..moveTo(_pts[0].dx * s, _pts[0].dy * s);
    for (var i = 1; i < _pts.length; i++) {
      path.lineTo(_pts[i].dx * s, _pts[i].dy * s);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FilledStarPainter oldDelegate) => oldDelegate.color != color;
}

class SavedListScreen extends StatelessWidget {
  const SavedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.calculations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: app.tr('saved.title'),
        ),
        if (list.isEmpty)
          LoanEmpty(
            icon: const Icon(LucideIcons.bookmark, size: 40, color: RevolutColors.brandSolid),
            message: app.tr('saved.empty'),
            action: LoanPrimaryButton(
              label: app.tr('saved.goCalc'),
              onPressed: () => app.goTab(0),
            ),
          )
        else
          ...list.map((c) {
            final inCompare = app.compareIds.contains(c.id);
            return LoanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      app.setPendingResult(c.result, savedId: c.id);
                      app.push(AppRoute.savedDetail, id: c.id);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _savedTitle(c.note, c.result, app),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (inCompare) ...[
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => app.push(AppRoute.compare),
                                child: LoanChip(app.tr('saved.inCompare')),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (c.favorite) const _FilledStar(size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LoanMuted(
                          app.tr('saved.meta', {
                            'principal': app.money(c.result.input.principal),
                            'rate': '${c.result.input.annualRatePercent}',
                            'months': '${c.result.input.termMonths}',
                          }),
                          fontSize: 12,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          app.tr('compare.perMonth', {'amount': app.money(c.result.monthlyPayment)}),
                          style: monoStyle(context, size: 16, w: FontWeight.w700)
                              .copyWith(color: RevolutColors.brandSolid),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      LoanQuickChip(
                        label: c.favorite ? app.tr('saved.unfav') : app.tr('saved.fav'),
                        onTap: () {
                          app.persistCalculations(
                            app.calculations
                                .map((x) => x.id == c.id ? x.copyWith(favorite: !x.favorite) : x)
                                .toList(),
                          );
                        },
                      ),
                      LoanQuickChip(
                        label: app.tr('saved.compare'),
                        onTap: () => app.addToCompare(c.id),
                      ),
                      LoanQuickChip(
                        label: app.tr('saved.delete'),
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(app.tr('saved.deleteTitle')),
                              content: Text(app.tr('saved.deleteConfirm')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(app.tr('common.back')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(app.tr('saved.delete')),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          app.removeFromCompare(c.id);
                          await app.persistCalculations(
                            app.calculations.where((x) => x.id != c.id).toList(),
                          );
                          app.showToast(app.tr('saved.deleted'));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
