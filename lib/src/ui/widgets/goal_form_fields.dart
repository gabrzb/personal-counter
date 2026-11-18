import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/goal.dart';
import '../goal_icons.dart';

class GoalFormFields extends StatelessWidget {
  const GoalFormFields({
    super.key,
    required this.nameController,
    required this.targetController,
    required this.icon,
    required this.existingGoals,
    required this.onChanged,
    required this.onIconChanged,
    required this.saving,
    this.goal,
  });

  final TextEditingController nameController;
  final TextEditingController targetController;
  final String icon;
  final List<Goal> existingGoals;
  final Goal? goal;
  final VoidCallback onChanged;
  final ValueChanged<String> onIconChanged;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: nameController,
          autofocus: goal == null,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 20,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nome',
            hintText: 'Ex.: Leitura',
          ),
          onChanged: (_) => onChanged(),
          validator: (value) {
            final clean = value?.trim() ?? '';
            if (clean.isEmpty) return 'Dê um nome à meta';
            if (existingGoals.any(
              (g) =>
                  g.id != goal?.id &&
                  g.name.toLowerCase() == clean.toLowerCase(),
            )) {
              return 'Já existe uma meta com esse nome';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: targetController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: 'Objetivo',
            suffixText: 'dias',
            fillColor: colors.primaryContainer,
          ),
          style: TextStyle(fontSize: 28, color: colors.onSurface),
          onChanged: (_) => onChanged(),
          validator: (value) {
            final n = int.tryParse(value ?? '') ?? 0;
            if (n < 1 || n > 3650) return 'Use um número inteiro de 1 a 3650';
            if (n < (goal?.days ?? 0)) {
              return 'Mínimo de ${goal!.days} dias já registrados';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: icon,
          decoration: const InputDecoration(labelText: 'Ícone'),
          items: goalIcons.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(e.value.$1, color: colors.primary),
                      const SizedBox(width: 12),
                      Text(e.value.$2),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: saving
              ? null
              : (value) {
                  if (value != null) onIconChanged(value);
                },
        ),
      ],
    );
  }
}
