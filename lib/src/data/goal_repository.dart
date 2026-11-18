import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/goal.dart';

/// SQLite is the source of truth. Multi-table changes are atomic.
class GoalRepository {
  GoalRepository({DatabaseFactory? factory, this._path})
    : _factory = factory ?? databaseFactory;
  final DatabaseFactory _factory;
  final String? _path;
  Database? _database;
  Future<void> open() async {
    if (_database != null) return;
    _database = await _factory.openDatabase(
      _path ?? p.join(await _factory.getDatabasesPath(), 'metas.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE goals (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL COLLATE NOCASE UNIQUE, target INTEGER NOT NULL CHECK(target BETWEEN 1 AND 3650), icon TEXT NOT NULL, notes TEXT NOT NULL DEFAULT \'\', position INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE registrations (goal_id INTEGER NOT NULL REFERENCES goals(id) ON DELETE CASCADE, day TEXT NOT NULL, PRIMARY KEY(goal_id, day))',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
        },
      ),
    );
  }

  Database get db => _database!;
  Future<List<Goal>> load() async {
    final rows = await db.query('goals', orderBy: 'position, id');
    final dates = await db.query('registrations');
    return rows
        .map(
          (row) => Goal(
            id: row['id'] as int,
            name: row['name'] as String,
            target: row['target'] as int,
            icon: row['icon'] as String,
            notes: row['notes'] as String,
            dates: dates
                .where((d) => d['goal_id'] == row['id'])
                .map((d) => d['day'] as String),
          ),
        )
        .toList();
  }

  Future<Map<String, String>> settings() async => {
    for (final row in await db.query('settings'))
      row['key'] as String: row['value'] as String,
  };
  Future<void> setSetting(String key, String value) async {
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> save({
    Goal? previous,
    required String name,
    required int target,
    required String icon,
    required String notes,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty ||
        clean.runes.length > 20 ||
        target < 1 ||
        target > 3650 ||
        notes.runes.length > 280 ||
        target < (previous?.days ?? 0)) {
      throw const FormatException(
        'Confira o nome, o objetivo e as observações.',
      );
    }
    await db.transaction((txn) async {
      final duplicates = await txn.query('goals');
      if (duplicates.any(
        (row) =>
            row['id'] != previous?.id &&
            (row['name'] as String).toLowerCase() == clean.toLowerCase(),
      )) {
        throw const FormatException('Já existe uma meta com esse nome.');
      }
      final values = {
        'name': clean,
        'target': target,
        'icon': icon,
        'notes': notes.trim(),
      };
      if (previous == null) {
        final max =
            Sqflite.firstIntValue(
              await txn.rawQuery('SELECT MAX(position) FROM goals'),
            ) ??
            -1;
        await txn.insert('goals', {...values, 'position': max + 1});
      } else {
        await txn.update(
          'goals',
          values,
          where: 'id = ?',
          whereArgs: [previous.id],
        );
      }
    });
  }

  Future<void> register(int id, DateTime now) async {
    await db.transaction((txn) async {
      final rows = await txn.query('goals', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) {
        throw const FormatException('Esta meta não existe mais.');
      }
      final dates = await txn.query(
        'registrations',
        where: 'goal_id = ?',
        whereArgs: [id],
      );
      if (dates.any((row) => row['day'] == dayKey(now))) {
        throw const FormatException('Hoje já foi registrado.');
      }
      if (dates.length >= (rows.single['target'] as int)) {
        throw const FormatException('Você já concluiu esta meta.');
      }
      await txn.insert('registrations', {'goal_id': id, 'day': dayKey(now)});
    });
  }

  Future<void> removeRegistration(int id, String day) async {
    await db.delete(
      'registrations',
      where: 'goal_id = ? AND day = ?',
      whereArgs: [id, day],
    );
  }

  Future<void> reset(int id) async {
    await db.delete('registrations', where: 'goal_id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restore(Goal goal, int position) async {
    await db.transaction((txn) async {
      await txn.insert('goals', {
        'id': goal.id,
        'name': goal.name,
        'target': goal.target,
        'icon': goal.icon,
        'notes': goal.notes,
        'position': position,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (final date in goal.dates) {
        await txn.insert('registrations', {
          'goal_id': goal.id,
          'day': date,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> reorder(List<int> ids) async {
    await db.transaction((txn) async {
      for (var i = 0; i < ids.length; i++) {
        await txn.update(
          'goals',
          {'position': i},
          where: 'id = ?',
          whereArgs: [ids[i]],
        );
      }
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
