import 'package:flutter/material.dart';

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
