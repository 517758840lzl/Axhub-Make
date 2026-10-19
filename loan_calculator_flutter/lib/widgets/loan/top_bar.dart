import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/revolut_theme.dart';

class LoanTopBar extends StatelessWidget {
  const LoanTopBar({
    super.key,
    this.onBack,
    required this.title,
    this.subtitle,
    this.leadingOnlyTitle = false,
  });

  final VoidCallback? onBack;
  final String title;
  final String? subtitle;
  final bool leadingOnlyTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            LoanBackButton(onPressed: onBack!),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 13, color: RevolutColors.textSecondary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoanBackButton extends StatelessWidget {
  const LoanBackButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: const SizedBox(
        width: 28,
        height: 28,
        child: Icon(LucideIcons.arrowLeft, size: 22, color: RevolutColors.text),
      ),
    );
  }
}
