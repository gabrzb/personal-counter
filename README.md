# Metas

App Flutter para Android e iOS, com metas pessoais e registro diário em SQLite. Interface em português, temas claro/escuro e apresentação adaptada à plataforma.

## Executar

Requer Flutter 3.47.1 ou compatível com Dart 3.13.1, Android SDK para Android e macOS/Xcode para iOS.

```sh
flutter pub get
flutter run
```

## Funcionalidades

- Criar e editar metas de 1 a 3650 dias, com nome e ícone.
- Registrar o dia atual uma única vez, até concluir o objetivo.
- Consultar os registros no calendário; datas passadas e futuras não são alteradas.
- Editar observações, reiniciar e excluir, com confirmação e opção de desfazer.
- Reordenar com toque longo e arraste, ou pelas ações de acessibilidade.
- Escolher 2, 3 ou 4 colunas e alternar o tema, com preferências persistidas.

Os dias são acumulados, não uma sequência obrigatória. Uma ausência não zera a contagem. O app usa a data local do dispositivo e começa vazio. Não exige conexão ou conta; desinstalar o app pode remover seus dados locais.

## Estrutura

`lib/src/domain` contém o modelo e as datas; `data`, o repositório SQLite; `state`, o estado observável; `ui`, telas, componentes e tema. O banco é a fonte de verdade: mudanças são confirmadas antes de atualizar a interface. Operações envolvendo múltiplas tabelas usam transações; registros diários têm chave única e exclusão em cascata.

`lib/src/ui/widgets/` reúne os componentes de apresentação: card, grade, cabeçalho, calendário, contador, observações e formulário. São `StatelessWidget`, com construtores `const`; recebem dados e callbacks. As telas preservam apenas o estado necessário para ordenação, mês/data e edição, e a aplicação gerencia o ciclo de vida do repositório. Feedback e catálogo de ícones ficam separados em `feedback.dart` e `goal_icons.dart`.

O banco `metas.db` é criado no diretório privado do app. A versão inicial do esquema é 1; futuras mudanças devem usar migrações, preservando os dados existentes.

## Verificação

```sh
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d emulator-5554
```

Os testes cobrem persistência após reabrir, validação, duplicidades, reordenação, reinício, exclusão/restauração e fluxos de interface Android/iOS. O teste de integração usa um banco separado (`native-qa.db`), sem alterar metas pessoais.

Capturas locais dos widgets ficam em `build/qa`. Para capturas nativas Android no Windows, com emulador aberto:

```powershell
.\tool\capture_android.ps1
```

As capturas de widgets iOS no Windows usam Roboto como substituta na verificação; a execução no iOS usa a fonte do sistema. A compilação e os testes nativos iOS precisam ser feitos em macOS com Xcode.

## Compilar

```sh
flutter build apk --release
# Em macOS, após configurar assinatura no Xcode:
flutter build ipa --release
```

O Android usa a chave de desenvolvimento do template para builds locais. Configure sua própria assinatura antes de distribuir nas lojas. Nome exibido: **Metas**; identificador: `br.com.contadorpessoal.contador_pessoal`.

O ícone geométrico é regenerado por `tool/generate_icons.ps1`. A licença da fonte está em `assets/fonts/LICENSE.txt`.

Referências visuais e documentos locais de design ficam fora do versionamento, conforme `.gitignore`.
