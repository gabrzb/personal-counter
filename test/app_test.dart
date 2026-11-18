import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:contador_pessoal/src/data/goal_repository.dart';
import 'package:contador_pessoal/src/state/goal_store.dart';
import 'package:contador_pessoal/src/ui/home_page.dart';
import 'package:contador_pessoal/src/ui/theme.dart';

Future<void> flush(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 160)),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await tester.runAsync(() async {
    final file = File('build/qa/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
  image.dispose();
}

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    for (final family in ['Roboto', '.SF Pro Text']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
    }
  });
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      '${platform.name}: create, register, notes, themes and delete',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = GoalRepository(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        );
        final store = GoalStore(repository);
      addTearDown(() async { store.dispose(); await repository.close(); });
        await tester.runAsync(store.initialize);
        await tester.pumpWidget(
          ListenableBuilder(
            listenable: store,
            builder: (_, _) => RepaintBoundary(
              key: const ValueKey('capture'),
              child: MaterialApp(
                locale: const Locale('pt', 'BR'),
                supportedLocales: const [Locale('pt', 'BR')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                theme: metasTheme(Brightness.light, platform: platform),
                darkTheme: metasTheme(Brightness.dark, platform: platform),
                themeMode: store.themeMode,
                home: HomePage(store: store),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Toda conquista começa\ncom uma meta'),
          findsOneWidget,
        );
        await tester.tap(find.text('Nova meta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Criar meta'));
        await tester.pumpAndSettle();
        expect(find.text('Dê um nome à meta'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).at(0), 'Leitura');
        await tester.tap(find.text('Criar meta'));
        await flush(tester);
        expect(store.goals.single.name, 'Leitura');
        await tester.tap(find.text('Leitura'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Registrar dia'));
        await flush(tester);
        expect(store.goals.single.days, 1);
        expect(find.text('Dia registrado'), findsWidgets);
        await capture(tester, '${platform.name}-detail');
        await tester.tap(find.byTooltip('Editar observações'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'Ler antes de dormir',
        );
        await tester.tap(find.text('Salvar'));
        await flush(tester);
        expect(store.goals.single.notes, 'Ler antes de dormir');
        await tester.tap(find.byTooltip('Ativar tema escuro'));
        await flush(tester);
        await capture(tester, '${platform.name}-dark');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await capture(tester, '${platform.name}-home');
        await tester.tap(find.text('Leitura'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Editar meta'));
        await tester.pumpAndSettle();
        await capture(tester, '${platform.name}-editor');
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir').last);
        await flush(tester);
        expect(store.goals, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
