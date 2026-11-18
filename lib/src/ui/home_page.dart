import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../domain/goal.dart';
import '../state/goal_store.dart';
import 'detail_page.dart';
import 'goal_editor.dart';
import 'theme.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});
  final GoalStore store;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool sorting = false;
  int? dragging;
  GoalStore get store => widget.store;
  Future<void> move(int id, int target) async {
    final from = store.goals.indexWhere((g) => g.id == id);
    if (from < 0 || from == target) return;
    try {
      await store.move(from, target);
      HapticFeedback.selectionClick();
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ios = isIOS(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final requested = store.columns ?? (ios ? 2 : 4);
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final maxColumns =
                  (constraints.maxWidth / (textScale > 1.3 ? 140 : 82))
                      .floor()
                      .clamp(1, 6);
              final columns = requested.clamp(1, maxColumns);
              final actions = <Widget>[
                IconButton(
                  tooltip: sorting ? 'Concluir reordenação' : 'Reordenar metas',
                  onPressed: store.goals.isEmpty
                      ? null
                      : () => setState(() => sorting = !sorting),
                  icon: Icon(
                    sorting ? Icons.check_rounded : Icons.swap_vert_rounded,
                  ),
                ),
                if (ios) ThemeButton(store: store),
                if (ios)
                  IconButton.filledTonal(
                    tooltip: 'Nova meta',
                    onPressed: () => showGoalEditor(context, store),
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
                    for (final n in [2, 3, 4])
                      CheckedPopupMenuItem(
                        value: n,
                        checked: requested == n,
                        child: Text('$n colunas'),
                      ),
                  ],
                ),
              ];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
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
                              fontWeight: ios
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: store.goals.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        color: colors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.flag_outlined,
                                        color: colors.primary,
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Toda conquista começa\ncom uma meta',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        height: 1.5,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          showGoalEditor(context, store),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Nova meta'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              itemCount: store.goals.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: ios ? 12 : 8,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent:
                                        (ios ? 151 : 142) +
                                        (textScale - 1).clamp(0, 3) * 65,
                                  ),
                              itemBuilder: (context, index) {
                                final goal = store.goals[index];
                                Widget card(bool floating) => GoalCard(
                                  goal: goal,
                                  compact: columns >= 3,
                                  selected: !ios && index == 0,
                                  sorting: sorting || !ios,
                                  floating: floating,
                                  onOpen: sorting
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => DetailPage(
                                              store: store,
                                              id: goal.id,
                                            ),
                                          ),
                                        ),
                                );
                                return DragTarget<int>(
                                  onWillAcceptWithDetails: (d) =>
                                      d.data != goal.id,
                                  onAcceptWithDetails: (d) =>
                                      move(d.data, index),
                                  builder: (context, candidates, rejected) =>
                                      Semantics(
                                        customSemanticsActions: {
                                          if (index > 0)
                                            const CustomSemanticsAction(
                                              label: 'Mover antes',
                                            ): () =>
                                                move(goal.id, index - 1),
                                          if (index < store.goals.length - 1)
                                            const CustomSemanticsAction(
                                              label: 'Mover depois',
                                            ): () =>
                                                move(goal.id, index + 1),
                                        },
                                        child: AnimatedContainer(
                                          duration: motion(context, 180),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: candidates.isNotEmpty
                                                ? Border.all(
                                                    color: colors.primary,
                                                    width: 2,
                                                  )
                                                : null,
                                          ),
                                          child: LongPressDraggable<int>(
                                            data: goal.id,
                                            maxSimultaneousDrags: store.busy
                                                ? 0
                                                : 1,
                                            onDragStarted: () {
                                              HapticFeedback.lightImpact();
                                              setState(
                                                () => dragging = goal.id,
                                              );
                                            },
                                            onDragEnd: (_) =>
                                                setState(() => dragging = null),
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: SizedBox(
                                                width:
                                                    (constraints.maxWidth -
                                                        40 -
                                                        (columns - 1) * 10) /
                                                    columns,
                                                height: ios ? 151 : 142,
                                                child: card(true),
                                              ),
                                            ),
                                            childWhenDragging: Container(
                                              decoration: BoxDecoration(
                                                color: colors.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.open_with_rounded,
                                                  color: colors.primary,
                                                ),
                                              ),
                                            ),
                                            child: AnimatedOpacity(
                                              duration: motion(context, 140),
                                              opacity: dragging == goal.id
                                                  ? .4
                                                  : 1,
                                              child: card(false),
                                            ),
                                          ),
                                        ),
                                      ),
                                );
                              },
                            ),
                    ),
                    if (!ios)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ThemeButton(store: store),
                            if (store.goals.isNotEmpty)
                              FilledButton.icon(
                                onPressed: () => showGoalEditor(context, store),
                                icon: const Icon(Icons.add),
                                label: const Text('Nova meta'),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.compact,
    required this.selected,
    required this.sorting,
    required this.floating,
    this.onOpen,
  });
  final Goal goal;
  final bool compact, selected, sorting, floating;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ios = isIOS(context);
    final radius = BorderRadius.circular(ios ? 19 : 12);
    return Semantics(
      button: true,
      label: '${goal.name}, ${goal.days} de ${goal.target} dias',
      child: Material(
        color: selected
            ? colors.primaryContainer
            : ios
            ? (isDark(context) ? const Color(0xFF1C1C1E) : Colors.white)
            : Color.alphaBlend(
                colors.onSurface.withValues(alpha: .025),
                colors.surface,
              ),
        borderRadius: radius,
        elevation: floating ? 8 : 0,
        child: InkWell(
          onTap: onOpen,
          borderRadius: radius,
          child: Container(
            padding: EdgeInsets.all(compact ? 10 : 13),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: ios
                  ? null
                  : Border.all(
                      color: selected
                          ? colors.primary.withValues(alpha: .35)
                          : colors.outlineVariant,
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GoalSymbol(goal.icon, size: compact ? 26 : 34),
                    const Spacer(),
                    Icon(
                      sorting
                          ? Icons.drag_indicator_rounded
                          : Icons.chevron_right_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${goal.days}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1,
                        ),
                      ),
                      TextSpan(
                        text: ' dias',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                ),
                if (!ios)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: colors.primary.withValues(alpha: .12),
                    ),
                  ),
                if (ios) const Spacer(),
                Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
