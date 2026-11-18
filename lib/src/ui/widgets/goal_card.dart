import 'package:flutter/material.dart';

import '../../domain/goal.dart';
import '../theme.dart';
import 'goal_symbol.dart';

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
