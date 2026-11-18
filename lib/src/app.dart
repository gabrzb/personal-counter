import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/goal_repository.dart';
import 'state/goal_store.dart';
import 'ui/home_page.dart';
import 'ui/theme.dart';

class MetasApp extends StatefulWidget {
  const MetasApp({super.key, required this.repository, this.platform});
  final GoalRepository repository;
  final TargetPlatform? platform;
  @override
  State<MetasApp> createState() => _MetasAppState();
}

class _MetasAppState extends State<MetasApp> {
  late final GoalStore store = GoalStore(widget.repository);
  late Future<void> initialization;
  @override
  void initState() {
    super.initState();
    initialization = store.initialize();
  }

  @override
  void dispose() {
    store.dispose();
    widget.repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final platform = widget.platform ?? defaultTargetPlatform;
      return MaterialApp(
        title: 'Metas',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: metasTheme(Brightness.light, platform: platform),
        darkTheme: metasTheme(Brightness.dark, platform: platform),
        themeMode: store.themeMode,
        home: FutureBuilder(
          future: initialization,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storage_rounded, size: 48),
                        const SizedBox(height: 16),
                        const Text('Não foi possível abrir seus dados.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(
                            () => initialization = store.initialize(),
                          ),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return HomePage(store: store);
          },
        ),
      );
    },
  );
}
