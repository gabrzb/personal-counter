import 'package:flutter/material.dart';

import '../../state/goal_store.dart';
import '../feedback.dart';
import '../theme.dart';
import 'theme_button.dart';

class GoalsHeader extends StatelessWidget {
  const GoalsHeader({
    super.key,
    required this.store,
    required this.sorting,
    required this.onToggleSorting,
    required this.onCreate,
  });

  final GoalStore store;
  final bool sorting;
  final VoidCallback onToggleSorting;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ios = isIOS(context);
    final requested = store.columns ?? (ios ? 2 : 4);
    final actions = <Widget>[
      IconButton(
        tooltip: sorting ? 'Concluir reordenação' : 'Reordenar metas',
        onPressed: store.goals.isEmpty ? null : onToggleSorting,
        icon: Icon(sorting ? Icons.check_rounded : Icons.swap_vert_rounded),
      ),
      if (ios) ThemeButton(store: store),
      if (ios)
        IconButton.filledTonal(
          tooltip: 'Nova meta',
          onPressed: onCreate,
          icon: const Icon(Icons.add),
        ),
      PopupMenuButton<int>(
        tooltip: 'Disposição dos cards',
        icon: const Icon(Icons.grid_view_rounded),
        initialValue: requested,
        onSelected: (value) async {
          try {
            await store.setColumns(value);
          } catch (error) {
            if (context.mounted) showError(context, error);
          }
        },
        itemBuilder: (_) => [
          for (final n in const [2, 3, 4])
            CheckedPopupMenuItem(
              value: n,
              checked: requested == n,
              child: Text('$n colunas'),
            ),
        ],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ios)
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(children: actions),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                sorting ? 'Reordenar metas' : 'Minhas metas',
                style: TextStyle(
                  fontSize: ios ? 34 : 28,
                  height: 1.15,
                  fontWeight: ios ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -.8,
                ),
              ),
            ),
            if (!ios) ...actions,
          ],
        ),
        if (sorting)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Segure e arraste para mover',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
