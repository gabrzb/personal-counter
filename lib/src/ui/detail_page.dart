import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/goal.dart';
import '../state/goal_store.dart';
import 'goal_editor.dart';
import 'theme.dart';
import 'feedback.dart';
import 'widgets/goal_calendar.dart';
import 'widgets/goal_counter.dart';
import 'widgets/goal_notes.dart';
import 'widgets/goal_registration_bar.dart';

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
                      GoalCounter(goal: goal),
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
                      GoalNotes(
                        notes: goal.notes,
                        onEdit: store.busy
                            ? null
                            : () => showGoalEditor(
                                context,
                                store,
                                goal: goal,
                                notesOnly: true,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              GoalRegistrationBar(
                store: store,
                registered: registered,
                complete: goal.complete,
                onRegister: () => register(goal),
              ),
            ],
          ),
        ),
      );
    },
  );
}
