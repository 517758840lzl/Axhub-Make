part of 'loan_screens.dart';

class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(title: app.tr('profile.title'), subtitle: app.tr('profile.subtitle')),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => app.push(AppRoute.profileEdit),
          child: LoanCard(
            child: Row(
              children: [
                Text(app.profile.avatar, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.displayNickname(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      LoanMuted(app.tr('profile.localOnly'), fontSize: 12),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: RevolutColors.textSecondary),
              ],
            ),
          ),
        ),
        LoanStatRow(
          children: [
            LoanStatBox(
              label: app.tr('profile.savedCount'),
              value: '${app.calculations.length}',
              onTap: () => app.push(AppRoute.savedList),
            ),
            LoanStatBox(
              label: app.tr('profile.savingsCount'),
              value: '${app.savingsGoals.length}',
              onTap: () => app.goTab(1),
            ),
          ],
        ),
        LoanCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              LoanMenuItem(
                label: app.tr('profile.settings'),
                onTap: () => app.push(AppRoute.profileSettings),
              ),
              LoanMenuItem(
                label: app.tr('profile.data'),
                onTap: () => app.push(AppRoute.profileData),
              ),
              LoanMenuItem(
                label: app.tr('profile.aboutUs'),
                onTap: () => app.push(AppRoute.profileAboutUs),
              ),
              LoanMenuItem(
                label: app.tr('profile.about'),
                onTap: () => app.push(AppRoute.profileAbout),
                divider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
