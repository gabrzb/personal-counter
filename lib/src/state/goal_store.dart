import 'package:flutter/material.dart';

import '../data/goal_repository.dart';
import '../domain/goal.dart';

class GoalStore extends ChangeNotifier {
  GoalStore(this.repository);
  final GoalRepository repository;
  List<Goal> goals = [];
  ThemeMode themeMode = ThemeMode.system;
  int? columns;
  bool busy = false;
  Goal? find(int id) => goals.where((g) => g.id == id).firstOrNull;

  Future<void> initialize() async {
    await repository.open();
    goals = await repository.load();
    final settings = await repository.settings();
    themeMode = switch (settings['theme']) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    columns = int.tryParse(settings['columns'] ?? '');
    notifyListeners();
  }

  Future<void> change(Future<void> Function() action) async {
    if (busy) throw const FormatException('Aguarde a operação em andamento.');
    busy = true;
    notifyListeners();
    try {
      await action();
      goals = await repository.load();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> toggleTheme(bool currentlyDark) async {
    final next = currentlyDark ? ThemeMode.light : ThemeMode.dark;
    await repository.setSetting('theme', next.name);
    themeMode = next;
    notifyListeners();
  }

  Future<void> setColumns(int value) async {
    await repository.setSetting('columns', '$value');
    columns = value;
    notifyListeners();
  }

  Future<void> move(int from, int to) async {
    if (from == to) return;
    final ids = goals.map((g) => g.id).toList();
    ids.insert(to, ids.removeAt(from));
    await change(() => repository.reorder(ids));
  }
}
