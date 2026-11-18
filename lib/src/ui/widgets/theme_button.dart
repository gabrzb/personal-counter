import 'package:flutter/material.dart';

import '../../state/goal_store.dart';
import '../theme.dart';
import '../feedback.dart';

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key, required this.store});
  final GoalStore store;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: isDark(context) ? 'Ativar tema claro' : 'Ativar tema escuro',
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.primary,
      minimumSize: const Size(48, 48),
    ),
    onPressed: () async {
      try {
        await store.toggleTheme(isDark(context));
      } catch (error) {
        if (context.mounted) showError(context, error);
      }
    },
    icon: AnimatedSwitcher(
      duration: motion(context),
      child: Icon(
        isDark(context) ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        key: ValueKey(isDark(context)),
      ),
    ),
  );
}
