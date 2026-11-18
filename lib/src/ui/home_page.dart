import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/goal_store.dart';
import 'detail_page.dart';
import 'feedback.dart';
import 'goal_editor.dart';
import 'theme.dart';
import 'widgets/empty_goals.dart';
import 'widgets/goals_grid.dart';
import 'widgets/goals_header.dart';
import 'widgets/theme_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});
  final GoalStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool sorting = false;
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
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoalsHeader(
                store: store,
                sorting: sorting,
                onToggleSorting: () => setState(() => sorting = !sorting),
                onCreate: () => showGoalEditor(context, store),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: store.goals.isEmpty
                    ? EmptyGoals(onCreate: () => showGoalEditor(context, store))
                    : GoalsGrid(
                        goals: store.goals,
                        columns: store.columns ?? (isIOS(context) ? 2 : 4),
                        sorting: sorting,
                        busy: store.busy,
                        onMove: move,
                        onOpen: (goal) => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DetailPage(store: store, id: goal.id),
                          ),
                        ),
                      ),
              ),
              if (!isIOS(context))
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
        ),
      ),
    ),
  );
}
