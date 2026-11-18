import 'package:flutter/material.dart';

import '../../domain/goal.dart';
import '../theme.dart';
import 'calendar_day.dart';

class GoalCalendar extends StatelessWidget {
  const GoalCalendar({
    super.key,
    required this.goal,
    required this.month,
    required this.onMonth,
    required this.onDay,
  });
  final Goal goal;
  final DateTime month;
  final ValueChanged<int> onMonth;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final label = MaterialLocalizations.of(context).formatMonthYear(month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = month.weekday % 7;
    final minimumTarget = isIOS(context) ? 44.0 : 48.0;
    final markSize = (MediaQuery.textScalerOf(context).scale(14) * 1.6).clamp(
      38.0,
      double.infinity,
    );
    final cellSize = (markSize + 10).clamp(minimumTarget, double.infinity);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Mês anterior',
              onPressed: () => onMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Próximo mês',
              onPressed: () => onMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth.clamp(cellSize * 7, double.infinity),
              child: Column(
                children: [
                  const _CalendarWeekdays(),
                  AnimatedSwitcher(
                    duration: motion(context, 180),
                    child: GridView.builder(
                      key: ValueKey(dayKey(month)),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisExtent: cellSize,
                      ),
                      itemCount: ((days + offset) / 7).ceil() * 7,
                      itemBuilder: (context, index) {
                        final day = index - offset + 1;
                        if (day < 1 || day > days) {
                          return const SizedBox.shrink();
                        }
                        final date = DateTime(month.year, month.month, day);
                        final recorded = goal.registered(date);
                        final today = dayKey(date) == dayKey(DateTime.now());
                        return CalendarDay(
                          date: date,
                          recorded: recorded,
                          today: today,
                          markSize: markSize,
                          onTap: () => onDay(date),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarWeekdays extends StatelessWidget {
  const _CalendarWeekdays();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final day in const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'])
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
