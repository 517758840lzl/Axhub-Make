part of 'loan_screens.dart';

class SavingsNewScreen extends StatefulWidget {
  const SavingsNewScreen({super.key});

  @override
  State<SavingsNewScreen> createState() => _SavingsNewScreenState();
}

class _SavingsNewScreenState extends State<SavingsNewScreen> {
  late final TextEditingController _name;
  late final TextEditingController _target;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _name = TextEditingController(text: app.tr('savings.defaultName'));
    _target = TextEditingController(
      text: app.savingsPrefill?.isNotEmpty == true ? app.savingsPrefill : '15000',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr('savings.create')),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(app.tr('savings.name')),
              LoanInput(controller: _name, onChanged: (_) {}),
              LoanLabel(app.tr('savings.target'), marginTop: 12),
              LoanInput(
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        LoanPrimaryButton(
          label: app.tr('savings.createCta'),
          onPressed: () async {
            final target = double.tryParse(_target.text);
            if (_name.text.trim().isEmpty || target == null || target <= 0) return;
            final goal = SavingsGoal(
              id: uid('goal'),
              name: _name.text.trim(),
              target: target,
              current: 0,
              deadline: null,
              linkedCalcId: null,
              transactions: [],
              createdAt: DateTime.now().toIso8601String(),
            );
            await app.persistSavings([goal, ...app.savingsGoals]);
            app.showToast(app.tr('savings.created'));
            app.replaceRoute(AppRoute.savings);
          },
        ),
      ],
    );
  }
}
