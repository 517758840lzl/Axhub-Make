import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/loan_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nick;
  late TextEditingController _avatar;
  late String _gender;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _nick = TextEditingController(text: app.profile.nickname);
    _gender = app.profile.gender;
    _avatar = TextEditingController(text: resolvedAvatar(app.profile.avatar, _gender));
  }

  @override
  void dispose() {
    _nick.dispose();
    _avatar.dispose();
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
              LoanInput(controller: _avatar, emoji: true, onChanged: (_) {}),
              LoanLabel(app.tr('profile.gender'), marginTop: 12),
              LoanSegment(
                options: [
                  ('male', app.tr('profile.gender.male')),
                  ('female', app.tr('profile.gender.female')),
                  ('private', app.tr('profile.gender.private')),
                ],
                selected: _gender,
                onSelect: (v) {
                  setState(() {
                    if (isDefaultAvatar(_avatar.text)) _avatar.text = defaultAvatarFor(v);
                    _gender = v;
                  });
                },
              ),
            ],
          ),
        ),
        LoanPrimaryButton(
          label: app.tr('settings.save'),
          onPressed: () async {
            await app.updateProfile(UserProfile(
              nickname: _nick.text.trim(),
              avatar: resolvedAvatar(_avatar.text, _gender),
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
