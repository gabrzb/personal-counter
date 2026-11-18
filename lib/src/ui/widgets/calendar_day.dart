import 'package:flutter/material.dart';

import '../theme.dart';

class CalendarDay extends StatelessWidget {
  const CalendarDay({
    super.key,
    required this.date,
    required this.recorded,
    required this.today,
    required this.markSize,
    required this.onTap,
  });

  final DateTime date;
  final bool recorded;
  final bool today;
  final double markSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label:
          '${MaterialLocalizations.of(context).formatFullDate(date)}${recorded ? ', registrado' : ''}${today ? ', hoje' : ''}',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isIOS(context) ? 24 : 6),
        child: Center(
          child: AnimatedContainer(
            duration: motion(context),
            width: markSize,
            height: markSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: recorded ? colors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(
                isIOS(context) ? markSize : 6,
              ),
              border: today ? Border.all(color: colors.primary) : null,
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                color: recorded ? colors.primary : colors.onSurfaceVariant,
                fontWeight: recorded ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
