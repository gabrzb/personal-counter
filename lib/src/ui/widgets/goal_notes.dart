import 'package:flutter/material.dart';

class GoalNotes extends StatelessWidget {
  const GoalNotes({super.key, required this.notes, this.onEdit});

  final String notes;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Observações',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Editar observações',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_note_rounded),
          ),
        ],
      ),
      InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            notes.isEmpty ? 'Adicionar observação' : notes,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    ],
  );
}
