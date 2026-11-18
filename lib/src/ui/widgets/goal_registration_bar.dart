import 'package:flutter/material.dart';

import '../../state/goal_store.dart';
import 'theme_button.dart';

class GoalRegistrationBar extends StatelessWidget {
  const GoalRegistrationBar({
    super.key,
    required this.store,
    required this.registered,
    required this.complete,
    required this.onRegister,
  });

  final GoalStore store;
  final bool registered;
  final bool complete;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
    child: Row(
      children: [
        ThemeButton(store: store),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton.icon(
            onPressed: store.busy || registered || complete ? null : onRegister,
            icon: Icon(
              registered || complete ? Icons.check_rounded : Icons.add,
            ),
            label: Text(
              registered
                  ? 'Dia registrado'
                  : complete
                  ? 'Meta concluída'
                  : 'Registrar dia',
            ),
          ),
        ),
      ],
    ),
  );
}
