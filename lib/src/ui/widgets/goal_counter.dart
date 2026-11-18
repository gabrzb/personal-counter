import 'package:flutter/material.dart';

import '../../domain/goal.dart';
import '../theme.dart';
import '../goal_icons.dart';

class GoalCounter extends StatelessWidget {
  const GoalCounter({super.key, required this.goal});
  final Goal goal;
  @override
  Widget build(BuildContext context) {
    if (isIOS(context)) return _IOSCounter(goal: goal);
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        children: [
          Semantics(
            liveRegion: true,
            label: '${goal.days} de ${goal.target} dias',
            child: AnimatedSwitcher(
              duration: motion(context),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: .92, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              ),
              child: Text(
                '${goal.days}',
                key: ValueKey(goal.days),
                style: TextStyle(
                  fontSize: 80,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          Text(
            'de ${goal.target} dias',
            style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: TweenAnimationBuilder<double>(
              duration: motion(context, 420),
              tween: Tween(end: goal.progress),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: colors.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (goal.complete)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Meta concluída',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IOSCounter extends StatelessWidget {
  const _IOSCounter({required this.goal});
  final Goal goal;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: goal.progress),
                    duration: motion(context, 420),
                    builder: (_, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                      backgroundColor: colors.primaryContainer,
                    ),
                  ),
                ),
                Icon(
                  goalIcons[goal.icon]?.$1 ?? Icons.flag_outlined,
                  color: colors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.complete ? 'Meta concluída' : 'Objetivo em dias',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  liveRegion: true,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${goal.days}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' de ${goal.target} dias',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(goal.progress * 100).round()}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
