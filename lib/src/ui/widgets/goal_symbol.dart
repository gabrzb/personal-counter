import 'package:flutter/material.dart';

import '../theme.dart';
import '../goal_icons.dart';

class GoalSymbol extends StatelessWidget {
  const GoalSymbol(this.name, {super.key, this.size = 32});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const hues = <String, Color>{
      'fitness': Color(0xFF6945A2),
      'school': Color(0xFF6945A2),
      'water': Color(0xFF24699C),
      'meditation': Color(0xFF327359),
      'sleep': Color(0xFF4E5899),
      'savings': Color(0xFF875115),
      'run': Color(0xFF875115),
    };
    final hue = isIOS(context) ? hues[name] ?? colors.primary : colors.primary;
    final foreground = isDark(context)
        ? Color.lerp(hue, Colors.white, .55)!
        : hue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isIOS(context)
            ? foreground.withValues(alpha: .12)
            : colors.primaryContainer,
        borderRadius: BorderRadius.circular(isIOS(context) ? 10 : size),
      ),
      child: Icon(
        goalIcons[name]?.$1 ?? Icons.flag_outlined,
        size: size * .58,
        color: foreground,
      ),
    );
  }
}
