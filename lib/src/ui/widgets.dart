import 'package:flutter/material.dart';

import '../state/goal_store.dart';
import 'theme.dart';

const goalIcons = <String, (IconData, String)>{
  'flag': (Icons.flag_outlined, 'Bandeira'),
  'book': (Icons.menu_book_rounded, 'Leitura'),
  'fitness': (Icons.fitness_center_rounded, 'Treino'),
  'meditation': (Icons.self_improvement_rounded, 'Meditação'),
  'water': (Icons.water_drop_outlined, 'Água'),
  'school': (Icons.school_outlined, 'Estudo'),
  'sleep': (Icons.bedtime_outlined, 'Sono'),
  'savings': (Icons.savings_outlined, 'Poupança'),
  'run': (Icons.directions_run_rounded, 'Corrida'),
  'health': (Icons.favorite_border_rounded, 'Saúde'),
};

void notice(
  BuildContext context,
  String text, {
  Future<void> Function()? undo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 94),
      content: Text(text),
      duration: Duration(seconds: undo == null ? 4 : 7),
      action: undo == null
          ? null
          : SnackBarAction(
              label: 'Desfazer',
              onPressed: () async {
                try {
                  await undo();
                  if (context.mounted) notice(context, 'Ação desfeita');
                } catch (error) {
                  if (context.mounted) showError(context, error);
                }
              },
            ),
    ),
  );
}

void showError(BuildContext context, Object error) => notice(
  context,
  error is FormatException ? error.message : 'Não foi possível salvar. Seus dados foram preservados. Tente novamente.',
);

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
  String action,
) async =>
    await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

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

class GoalSymbol extends StatelessWidget {
  const GoalSymbol(this.name, {super.key, this.size = 32});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hues = <String, Color>{
      'fitness': const Color(0xFF6945A2),
      'school': const Color(0xFF6945A2),
      'water': const Color(0xFF24699C),
      'meditation': const Color(0xFF327359),
      'sleep': const Color(0xFF4E5899),
      'savings': const Color(0xFF875115),
      'run': const Color(0xFF875115),
    };
    final hue = isIOS(context) ? hues[name] ?? colors.primary : colors.primary;
    final foreground = isDark(context)
        ? Color.lerp(hue, Colors.white, .55)!
        : hue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isIOS(context)
            ? foreground.withValues(alpha: .12)
            : colors.primaryContainer,
        borderRadius: BorderRadius.circular(isIOS(context) ? 10 : size),
      ),
      child: Icon(
        goalIcons[name]?.$1 ?? Icons.flag_outlined,
        size: size * .58,
        color: foreground,
      ),
    );
  }
}
