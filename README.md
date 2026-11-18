# Metas

App Flutter para Android e iOS com metas pessoais, registro diário, calendário e observações. Dados locais em SQLite, temas claro/escuro e grade reordenável.

Os dias são acumulados: faltar um dia não reinicia a contagem. Não exige conta ou conexão.

## Executar

Requer Flutter 3.47.1 / Dart 3.13.1 ou compatível. Para iOS, macOS com Xcode.

```sh
flutter pub get
flutter run
```

## Testar

```sh
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d emulator-5554
```

## Compilar

```sh
flutter build apk --release
flutter build ipa --release # macOS/Xcode
```

## Estrutura

Código em `lib/src/`: `domain/`, `data/` (SQLite), `state/` e `ui/`.

Licença da fonte em `assets/fonts/LICENSE.txt`.
