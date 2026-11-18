import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:contador_pessoal/src/app.dart';
import 'package:contador_pessoal/src/data/goal_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('QA_CAPTURE')) return;
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
      .hideCurrentSnackBar();
  await tester.pumpAndSettle();
  debugPrint('QA_CAPTURE:$name');
  await Future<void>.delayed(const Duration(seconds: 5));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native SQLite and full daily registration flow', (tester) async {
    final path = p.join(await getDatabasesPath(), 'native-qa.db');
    await deleteDatabase(path);
    final repository = GoalRepository(path: path);
    await repository.open();
    await repository.setSetting('theme', 'light');
    for (final entry in [
      ('Treino', 'fitness'),
      ('Meditar', 'meditation'),
      ('Água', 'water'),
      ('Estudo', 'school'),
      ('Sono', 'sleep'),
      ('Poupar', 'savings'),
      ('Correr', 'run'),
    ]) {
      await repository.save(
        name: entry.$1,
        target: 30,
        icon: entry.$2,
        notes: '',
      );
    }
    await tester.pumpWidget(MetasApp(repository: repository));
    await tester.pumpAndSettle();
    final create = find.text('Nova meta');
    if (create.evaluate().isNotEmpty) {
      await tester.tap(create.first);
    } else {
      await tester.tap(find.byTooltip('Nova meta'));
    }
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Teste nativo');
    await tester.tap(find.text('Criar meta'));
    await tester.pumpAndSettle();
    await capture(tester, 'native-android-home');
    await tester.tap(find.text('Teste nativo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar dia'));
    await tester.pumpAndSettle();
    await capture(tester, 'native-android-detail');
    await tester.tap(find.byTooltip('Ativar tema escuro'));
    await tester.pumpAndSettle();
    await capture(tester, 'native-android-dark');
    await capture(tester, 'native-android-large-font');
    await tester.tap(find.byTooltip('Editar meta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    await capture(tester, 'native-android-editor-keyboard');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    final saved = (await repository.load()).singleWhere(
      (g) => g.name == 'Teste nativo',
    );
    expect(saved.days, 1);
    expect(saved.registered(DateTime.now()), isTrue);
    await repository.close();
    await repository.open();
    expect(
      (await repository.load()).singleWhere((g) => g.id == saved.id).days,
      1,
    );
    await repository.delete(saved.id);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await repository.close();
    await deleteDatabase(path);
  });
}
