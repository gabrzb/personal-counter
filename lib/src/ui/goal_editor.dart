import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/goal.dart';
import '../state/goal_store.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> showGoalEditor(
  BuildContext context,
  GoalStore store, {
  Goal? goal,
  bool notesOnly = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  useSafeArea: true,
  builder: (_) => GoalEditor(store: store, goal: goal, notesOnly: notesOnly),
);

class GoalEditor extends StatefulWidget {
  const GoalEditor({
    super.key,
    required this.store,
    this.goal,
    this.notesOnly = false,
  });
  final GoalStore store;
  final Goal? goal;
  final bool notesOnly;
  @override
  State<GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<GoalEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.goal?.name ?? '');
  late final target = TextEditingController(
    text: '${widget.goal?.target ?? 30}',
  );
  late final notes = TextEditingController(text: widget.goal?.notes ?? '');
  late String icon = widget.goal?.icon ?? 'flag';
  bool saving = false;
  bool allowPop = false;
  String? error;
  bool get dirty =>
      name.text != (widget.goal?.name ?? '') ||
      target.text != '${widget.goal?.target ?? 30}' ||
      notes.text != (widget.goal?.notes ?? '') ||
      icon != (widget.goal?.icon ?? 'flag');

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (saving) return;
    if (dirty &&
        !await confirm(
          context,
          'Descartar alterações?',
          'As alterações ainda não foram salvas.',
          'Descartar',
        )) {
      return;
    }
    if (mounted) {
      setState(() => allowPop = true);
      Navigator.pop(context);
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.store.change(
        () => widget.store.repository.save(
          previous: widget.goal,
          name: name.text,
          target: int.parse(target.text),
          icon: icon,
          notes: notes.text,
        ),
      );
      if (!mounted) return;
      setState(() => allowPop = true);
      Navigator.pop(context);
      notice(
        context,
        widget.goal == null ? 'Meta criada' : 'Alterações salvas',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e is FormatException
              ? e.message
              : 'Não foi possível salvar. Tente novamente.';
        });
      }
    }
  }

  Future<void> destructive(bool delete) async {
    final goal = widget.goal!;
    if (!await confirm(
      context,
      delete ? 'Excluir meta?' : 'Reiniciar contagem?',
      delete
          ? 'A meta será removida. Você poderá desfazer em seguida.'
          : 'Os dias registrados serão zerados. As observações serão mantidas.',
      delete ? 'Excluir' : 'Reiniciar',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => saving = true);
    final index = widget.store.goals.indexWhere((g) => g.id == goal.id);
    try {
      await widget.store.change(
        () => delete
            ? widget.store.repository.delete(goal.id)
            : widget.store.repository.reset(goal.id),
      );
      if (!mounted) return;
      setState(() => allowPop = true);
      Navigator.pop(context);
      notice(
        context,
        delete ? 'Meta excluída' : 'Contagem reiniciada',
        undo: () => widget.store.change(
          () => widget.store.repository.restore(goal, index),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: allowPop || (!dirty && !saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SafeArea(
            top: false,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.notesOnly
                              ? 'Observações'
                              : widget.goal == null
                              ? 'Nova meta'
                              : 'Editar meta',
                          style: TextStyle(
                            fontSize: isIOS(context) ? 30 : 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: saving ? null : close,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!widget.notesOnly) ...[
                    TextFormField(
                      controller: name,
                      autofocus: widget.goal == null,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 20,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Ex.: Leitura',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final clean = value?.trim() ?? '';
                        if (clean.isEmpty) return 'Dê um nome à meta';
                        if (widget.store.goals.any(
                          (g) =>
                              g.id != widget.goal?.id &&
                              g.name.toLowerCase() == clean.toLowerCase(),
                        )) {
                          return 'Já existe uma meta com esse nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: target,
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
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final n = int.tryParse(value ?? '') ?? 0;
                        if (n < 1 || n > 3650) {
                          return 'Use um número inteiro de 1 a 3650';
                        }
                        if (n < (widget.goal?.days ?? 0)) {
                          return 'Mínimo de ${widget.goal!.days} dias já registrados';
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
                          : (value) => setState(() => icon = value!),
                    ),
                  ] else
                    TextFormField(
                      controller: notes,
                      maxLines: 5,
                      maxLength: 280,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Observação',
                        hintText: 'O que te ajuda a continuar?',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    ),
                  if (widget.goal != null && !widget.notesOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: saving || widget.goal!.days == 0
                                  ? null
                                  : () => destructive(false),
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Reiniciar'),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: saving
                                  ? null
                                  : () => destructive(true),
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
                          onPressed: saving ? null : close,
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: saving ? null : save,
                          child: saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.goal == null ? 'Criar meta' : 'Salvar',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
