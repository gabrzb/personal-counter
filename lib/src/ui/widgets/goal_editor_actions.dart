import 'package:flutter/material.dart';

class GoalEditorActions extends StatelessWidget {
  const GoalEditorActions({
    super.key,
    required this.saving,
    required this.creating,
    required this.onCancel,
    required this.onSave,
    this.onReset,
    this.onDelete,
  });

  final bool saving;
  final bool creating;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback? onReset;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (onDelete != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: saving ? null : onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: saving ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: saving ? null : onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(creating ? 'Criar meta' : 'Salvar'),
            ),
          ),
        ],
      ),
    ],
  );
}
