import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/goal.dart';
import '../state/goal_store.dart';
import 'goal_editor.dart';
import 'theme.dart';
import 'widgets.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.store, required this.id});
  final GoalStore store;
  final int id;
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with WidgetsBindingObserver {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Timer? midnight;
  GoalStore get store => widget.store;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scheduleMidnight();
  }

  void scheduleMidnight() {
    midnight?.cancel();
    final now = DateTime.now();
    midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (mounted) {
          setState(() {});
          scheduleMidnight();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      scheduleMidnight();
    }
  }

  @override
  void dispose() {
    midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> register(Goal goal) async {
    final date = DateTime.now();
    try {
      await store.change(() => store.repository.register(goal.id, date));
      HapticFeedback.lightImpact();
      if (mounted) {
        notice(
          context,
          store.find(goal.id)?.complete == true
              ? 'Meta concluída. Você conseguiu!'
              : 'Dia registrado',
          undo: () => store.change(
            () => store.repository.removeRegistration(goal.id, dayKey(date)),
          ),
        );
      }
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final goal = store.find(widget.id);
      if (goal == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Meta excluída')),
          body: const Center(child: Text('A meta foi removida.')),
        );
      }
      final colors = Theme.of(context).colorScheme;
      final ios = isIOS(context);
      final now = DateTime.now();
      final registered = goal.registered(now);
      return Scaffold(
        appBar: AppBar(
          title: Text(ios ? 'Minhas metas' : goal.name),
          actions: [
            IconButton(
              tooltip: 'Editar meta',
              onPressed: store.busy
                  ? null
                  : () async {
                      await showGoalEditor(context, store, goal: goal);
                      if (context.mounted && store.find(widget.id) == null) {
                        Navigator.pop(context);
                      }
                    },
              icon: const Icon(Icons.edit_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ios)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      if (ios)
                        _IOSCounter(goal: goal)
                      else
                        Center(
                          child: Column(
                            children: [
                              if (ios) GoalSymbol(goal.icon, size: 48),
                              Semantics(
                                liveRegion: true,
                                label: '${goal.days} de ${goal.target} dias',
                                child: AnimatedSwitcher(
                                  duration: motion(context),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: Tween(begin: .92, end: 1.0)
                                              .animate(
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
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 160,
                                child: TweenAnimationBuilder<double>(
                                  duration: motion(context, 420),
                                  tween: Tween(end: goal.progress),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, value, _) =>
                                      LinearProgressIndicator(
                                        value: value,
                                        minHeight: 3,
                                        backgroundColor:
                                            colors.primaryContainer,
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
                        ),
                      const SizedBox(height: 28),
                      GoalCalendar(
                        goal: goal,
                        month: month,
                        onMonth: (offset) => setState(
                          () => month = DateTime(
                            month.year,
                            month.month + offset,
                          ),
                        ),
                        onDay: (date) {
                          final today = DateTime(now.year, now.month, now.day);
                          if (date.isAfter(today)) {
                            notice(
                              context,
                              'Dias futuros não podem ser registrados',
                            );
                          } else if (dayKey(date) == dayKey(now)) {
                            if (!store.busy) register(goal);
                          } else {
                            notice(
                              context,
                              goal.registered(date)
                                  ? 'Dia registrado no calendário'
                                  : 'Nenhum registro neste dia',
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Observações',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar observações',
                            onPressed: store.busy
                                ? null
                                : () => showGoalEditor(
                                    context,
                                    store,
                                    goal: goal,
                                    notesOnly: true,
                                  ),
                            icon: const Icon(Icons.edit_note_rounded),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => showGoalEditor(
                          context,
                          store,
                          goal: goal,
                          notesOnly: true,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            goal.notes.isEmpty
                                ? 'Adicionar observação'
                                : goal.notes,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Row(
                  children: [
                    ThemeButton(store: store),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: store.busy || registered || goal.complete
                            ? null
                            : () => register(goal),
                        icon: Icon(
                          registered || goal.complete
                              ? Icons.check_rounded
                              : Icons.add,
                        ),
                        label: Text(
                          registered
                              ? 'Dia registrado'
                              : goal.complete
                              ? 'Meta concluída'
                              : 'Registrar dia',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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
    final colors = Theme.of(context).colorScheme;
    final label = MaterialLocalizations.of(context).formatMonthYear(month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = month.weekday % 7;
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
        Row(
          children: [
            for (final day in ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'])
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
        ),
        AnimatedSwitcher(
          duration: motion(context, 180),
          child: GridView.builder(
            key: ValueKey(dayKey(month)),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 44,
            ),
            itemCount: ((days + offset) / 7).ceil() * 7,
            itemBuilder: (context, index) {
              final day = index - offset + 1;
              if (day < 1 || day > days) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, day);
              final recorded = goal.registered(date);
              final today = dayKey(date) == dayKey(DateTime.now());
              return Semantics(
                label:
                    '${MaterialLocalizations.of(context).formatFullDate(date)}${recorded ? ', registrado' : ''}${today ? ', hoje' : ''}',
                button: true,
                excludeSemantics: true,
                child: Center(
                  child: InkWell(
                    onTap: () => onDay(date),
                    borderRadius: BorderRadius.circular(
                      isIOS(context) ? 24 : 6,
                    ),
                    child: AnimatedContainer(
                      duration: motion(context),
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: recorded
                            ? colors.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          isIOS(context) ? 24 : 6,
                        ),
                        border: today
                            ? Border.all(color: colors.primary)
                            : null,
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          color: recorded
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: recorded
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
