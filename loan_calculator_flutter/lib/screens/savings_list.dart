part of 'loan_screens.dart';

// --- Savings ---

class _SavingsInsightLine extends StatelessWidget {
  const _SavingsInsightLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.muted,
    this.marginBottom = 8,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool muted;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: muted ? RevolutColors.textSecondary : RevolutColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SavingsListScreen extends StatelessWidget {
  const SavingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final goals = app.savingsGoals;

    if (goals.isEmpty) {
      return Column(
        children: [
          LoanTopBar(title: app.tr('savings.title'), subtitle: app.tr('savings.subtitle')),
          LoanEmpty(
            icon: const Icon(LucideIcons.piggyBank, size: 40, color: RevolutColors.brandSolid),
            message: app.tr('savings.empty'),
            action: LoanPrimaryButton(label: app.tr('savings.new'), onPressed: () => app.push(AppRoute.savingsNew)),
          ),
        ],
      );
    }

    final totalSaved = goals.fold<double>(0, (s, g) => s + g.current);
    final totalTarget = goals.fold<double>(0, (s, g) => s + g.target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          title: app.tr('savings.title'),
          subtitle: app.tr('savings.inProgress', {'n': '${goals.length}'}),
        ),
        LoanStatRow(
          children: [
            LoanStatBox(label: app.tr('savings.savedTotal'), value: app.money(totalSaved)),
            LoanStatBox(label: app.tr('savings.targetTotal'), value: app.money(totalTarget)),
          ],
        ),
        if (app.calculations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LoanMuted(
              app.tr('savings.linkedHint', {'n': '${app.calculations.length}'}),
              fontSize: 12,
            ),
          ),
        ...goals.map((g) {
          final pct = g.target > 0 ? (g.current / g.target * 100).clamp(0, 100) : 0.0;
          final left = (g.target - g.current).clamp(0, double.infinity);
          final name = _savingsName(g.name, app);
          return LoanCard(
            onTap: () => app.push(AppRoute.savingsDetail, id: g.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    LoanChip('${pct.toStringAsFixed(0)}%'),
                  ],
                ),
                Center(
                  child: DonutChart(
                    size: 120,
                    stroke: 10,
                    animate: false,
                    segments: [
                      DonutSegment(
                        value: g.current,
                        color: RevolutColors.brandStart,
                        label: app.tr('savings.done'),
                        amountText: app.money(g.current),
                      ),
                      DonutSegment(
                        value: left.toDouble(),
                        color: RevolutColors.donutTrack,
                        label: app.tr('savings.todo'),
                        amountText: app.money(left.toDouble()),
                      ),
                    ],
                    centerLabel: '${pct.toStringAsFixed(0)}%',
                    centerSub: app.tr('savings.progress'),
                  ),
                ),
                // 提示挂在对应目标卡片内，多目标时不会混淆
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LoanCard.savingsInsightGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RevolutColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoanLabel(
                        app.tr('savings.insightsFor', {'name': name}),
                        marginBottom: 10,
                      ),
                      _SavingsInsightLine(
                        icon: LucideIcons.clock3,
                        iconColor: RevolutColors.text,
                        text: savingsEtaLine(g, app.money, app.tr),
                        muted: false,
                      ),
                      _SavingsInsightLine(
                        icon: LucideIcons.shield,
                        iconColor: RevolutColors.textSecondary,
                        text: savingsBufferLine(g, app.calculations, app.money, app.tr),
                        muted: true,
                        marginBottom: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
