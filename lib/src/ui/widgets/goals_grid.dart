import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../domain/goal.dart';
import '../theme.dart';
import 'goal_card.dart';

class GoalsGrid extends StatelessWidget {
  const GoalsGrid({
    super.key,
    required this.goals,
    required this.columns,
    required this.sorting,
    required this.busy,
    required this.onOpen,
    required this.onMove,
  });

  final List<Goal> goals;
  final int columns;
  final bool sorting;
  final bool busy;
  final ValueChanged<Goal> onOpen;
  final void Function(int id, int target) onMove;

  @override
  Widget build(BuildContext context) {
    final ios = isIOS(context);
    final colors = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final spacing = ios ? 12.0 : 8.0;
    final height = (ios ? 151.0 : 142.0) + (textScale - 1).clamp(0, 3) * 65;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxColumns = (constraints.maxWidth / (textScale > 1.3 ? 140 : 82))
            .floor()
            .clamp(1, 6);
        final effectiveColumns = columns.clamp(1, maxColumns);
        final width =
            (constraints.maxWidth - (effectiveColumns - 1) * spacing) /
            effectiveColumns;
        return GridView.builder(
          itemCount: goals.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveColumns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 12,
            mainAxisExtent: height,
          ),
          itemBuilder: (context, index) {
            final goal = goals[index];
            return DragTarget<int>(
              key: ValueKey(goal.id),
              onWillAcceptWithDetails: (details) => details.data != goal.id,
              onAcceptWithDetails: (details) => onMove(details.data, index),
              builder: (context, candidates, rejected) => Semantics(
                customSemanticsActions: {
                  if (index > 0)
                    const CustomSemanticsAction(label: 'Mover antes'): () =>
                        onMove(goal.id, index - 1),
                  if (index < goals.length - 1)
                    const CustomSemanticsAction(label: 'Mover depois'): () =>
                        onMove(goal.id, index + 1),
                },
                child: AnimatedContainer(
                  duration: motion(context, 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: candidates.isNotEmpty
                        ? Border.all(color: colors.primary, width: 2)
                        : null,
                  ),
                  child: LongPressDraggable<int>(
                    data: goal.id,
                    maxSimultaneousDrags: busy ? 0 : 1,
                    onDragStarted: HapticFeedback.lightImpact,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: GoalCard(
                          goal: goal,
                          compact: effectiveColumns >= 3,
                          selected: !ios && index == 0,
                          sorting: sorting || !ios,
                          floating: true,
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.open_with_rounded,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    child: GoalCard(
                      goal: goal,
                      compact: effectiveColumns >= 3,
                      selected: !ios && index == 0,
                      sorting: sorting || !ios,
                      floating: false,
                      onOpen: sorting ? null : () => onOpen(goal),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
