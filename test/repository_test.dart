import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:contador_pessoal/src/data/goal_repository.dart';

void main() {
  sqfliteFfiInit();
  late GoalRepository repository;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('metas_test_');
    repository = GoalRepository(
      factory: databaseFactoryFfi,
      path: '${directory.path}/test.db',
    );
    await repository.open();
  });
  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test(
    'persists goals, real dates, notes and preferences after reopening',
    () async {
      await repository.save(
        name: 'Leitura',
        target: 30,
        icon: 'book',
        notes: 'Antes de dormir',
      );
      final goal = (await repository.load()).single;
      await repository.register(goal.id, DateTime(2026, 11, 17, 23, 59));
      await repository.register(goal.id, DateTime(2026, 11, 18));
      await repository.setSetting('theme', 'dark');
      await repository.close();
      await repository.open();
      final loaded = (await repository.load()).single;
      expect(loaded.days, 2);
      expect(loaded.dates, {'2026-11-17', '2026-11-18'});
      expect(loaded.notes, 'Antes de dormir');
      expect((await repository.settings())['theme'], 'dark');
    },
  );

  test(
    'rejects duplicates, invalid targets, repeated days and completed goals',
    () async {
      await repository.save(name: 'Água', target: 1, icon: 'water', notes: '');
      await expectLater(
        repository.save(name: ' água ', target: 30, icon: 'water', notes: ''),
        throwsFormatException,
      );
      await expectLater(
        repository.save(name: 'Inválida', target: 0, icon: 'flag', notes: ''),
        throwsFormatException,
      );
      final goal = (await repository.load()).single;
      await repository.register(goal.id, DateTime(2026, 11, 17));
      await expectLater(
        repository.register(goal.id, DateTime(2026, 11, 17)),
        throwsFormatException,
      );
      await expectLater(
        repository.register(goal.id, DateTime(2026, 11, 18)),
        throwsFormatException,
      );
      expect((await repository.load()).single.days, 1);
    },
  );

  test(
    'reorders, resets, deletes cascading records and restores snapshots',
    () async {
      for (final name in ['Leitura', 'Treino']) {
        await repository.save(
          name: name,
          target: 30,
          icon: 'flag',
          notes: 'preservada',
        );
      }
      var goals = await repository.load();
      await repository.reorder(goals.reversed.map((g) => g.id).toList());
      expect((await repository.load()).first.name, 'Treino');
      await repository.register(goals.first.id, DateTime(2026, 11, 17));
      final snapshot = (await repository.load()).last;
      await repository.reset(snapshot.id);
      expect((await repository.load()).last.days, 0);
      expect((await repository.load()).last.notes, 'preservada');
      await repository.restore(snapshot, 1);
      await repository.delete(snapshot.id);
      expect(await repository.db.query('registrations'), isEmpty);
      await repository.restore(snapshot, 1);
      goals = await repository.load();
      expect(goals.last.days, 1);
      await repository.removeRegistration(snapshot.id, '2026-11-17');
      expect((await repository.load()).last.days, 0);
    },
  );
}
