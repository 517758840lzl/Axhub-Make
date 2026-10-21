import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/revolut_theme.dart';
import '../../widgets/loan_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nick;
  late String _gender;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _nick = TextEditingController(text: app.profile.nickname);
    _gender = app.profile.gender;
  }

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr('profile.editTitle')),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(app.tr('settings.nickname')),
              LoanInput(controller: _nick, onChanged: (_) {}),
              LoanLabel(app.tr('settings.avatar'), marginTop: 12),
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: RevolutColors.surface2,
                  shape: BoxShape.circle,
                ),
                child: Text(defaultAvatarFor(_gender), style: const TextStyle(fontSize: 32)),
              ),
              LoanLabel(app.tr('profile.gender'), marginTop: 12),
              LoanSegment(
                options: [
                  ('male', app.tr('profile.gender.male')),
                  ('female', app.tr('profile.gender.female')),
                  ('private', app.tr('profile.gender.private')),
                ],
                selected: _gender,
                onSelect: (v) => setState(() => _gender = v),
              ),
            ],
          ),
        ),
        LoanPrimaryButton(
          label: app.tr('settings.save'),
          onPressed: () async {
            await app.updateProfile(UserProfile(
              nickname: _nick.text.trim(),
              avatar: defaultAvatarFor(_gender),
              createdAt: app.profile.createdAt,
              gender: _gender,
            ));
            app.showToast(app.tr('toast.savedProfile'));
            app.pop();
          },
        ),
      ],
    );
  }
}
