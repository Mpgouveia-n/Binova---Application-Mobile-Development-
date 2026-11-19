# Binova

Projeto acadêmico da **Global Solution 2026/2 — FIAP**, com foco em
**CitizenTech e sustentabilidade**. A Binova demonstra como a consulta ao estado
de pontos de coleta e o registro de problemas por cidadãos podem apoiar o
acompanhamento do descarte de resíduos.

Este repositório contém o MVP funcional de **Mobile Application Development em
Dart puro via console**. Os níveis dos recipientes são simulados; não representam
medições físicas em tempo real.

## Tecnologias

- Dart com null safety; SDK compatível com `^3.13.1` (validado com Dart 3.13.1).
- Aplicação interativa de console.
- Dados mockados e armazenamento temporário em memória.
- `test` e `lints` como dependências de desenvolvimento.
- Nenhuma dependência externa de produção.

## Funcionalidades

- Listar pontos de coleta ativos e consultar detalhes pelo ID.
- Apresentar classificação de preenchimento e última leitura registrada.
- Registrar ocorrências vinculadas a cidadão e ponto ativo.
- Consultar as ocorrências do cidadão selecionado, incluindo registros da sessão.
- Tratar entradas vazias, inválidas, registros inexistentes e fim de entrada (EOF).

## Regras de negócio

| Condição da leitura atual | Classificação no console |
|---|---|
| De 0% até menos de 50% | `DISPONIVEL` |
| De 50% até menos de 80% | `ATENCAO` |
| De 80% até 100% | `PROXIMA_DO_LIMITE` |
| Ausente, futura ou com idade superior a 15 minutos | `SEM_DADOS_ATUALIZADOS` |

A leitura cronologicamente mais recente determina o estado, independentemente da
ordem da lista. Sua idade deve estar entre zero e 15 minutos, inclusive. Em empate
de data, prevalece a primeira encontrada. Uma leitura futura não é substituída por
uma anterior; um percentual antigo ou futuro não é exibido como atual.

Pontos inativos não aparecem na listagem pública, mas podem ser consultados por ID.
Novas ocorrências exigem usuário existente com papel `CIDADAO`, ponto existente e
ativo, tipo previsto no enum e descrição não vazia após `trim()`. Administradores
não podem registrar neste fluxo. O status inicial é `ABERTA`; criação e atualização
recebem o mesmo instante. O ID é o maior existente mais um, sem consumir IDs em
tentativas inválidas. Não há edição ou exclusão de ocorrências.

Os dados existem somente durante a execução. Ao reiniciar, os mocks são recriados
e as ocorrências adicionadas anteriormente deixam de existir.

## Arquitetura

| Diretório | Responsabilidade |
|---|---|
| `bin/` | Inicialização e composição dos componentes em `main.dart` |
| `lib/models/` | `Usuario`, `PontoColeta`, `LeituraSensor`, `Ocorrencia`, enums e invariantes |
| `lib/data/` | Fábrica de mocks com datas relativas a um instante de referência |
| `lib/services/` | Consultas, classificação e cadastro de ocorrências em memória |
| `lib/console/` | Menu, entrada, saída e apresentação dos resultados |
| `test/` | Testes de domínio, dados, serviços, console e integração pelo entrypoint real |

Uma base de mocks e uma instância de cada serviço são criadas por sessão. O
console recebe entrada, saída e relógio injetáveis, permitindo testes sem digitação
humana. Os serviços protegem suas coleções contra alterações externas.

## Como executar

No Windows (PowerShell), Linux ou macOS, com Dart instalado e disponível no PATH,
abra o terminal na pasta que contém `binova_mobile` e execute:

```sh
cd binova_mobile
dart --version
dart pub get
dart run bin/main.dart
```

Se o terminal já estiver na raiz do pacote, onde está o `pubspec.yaml`, omita o
`cd binova_mobile`. Se o pacote for a própria raiz do repositório clonado, entre
diretamente nessa raiz. Não é necessário iniciar Flutter ou um emulador.

| Opção | Ação |
|---|---|
| `1` | Listar pontos ativos |
| `2` | Informar o ID e consultar um ponto |
| `3` | Selecionar cidadão, ponto, tipo e descrição para registrar ocorrência |
| `4` | Selecionar cidadão para consultar suas ocorrências |
| `0` | Encerrar normalmente |

Pressione Enter após cada entrada. Validações malsucedidas cancelam a operação e
retornam ao menu. EOF encerra sem registrar um cadastro incompleto.

### Dados para demonstração

Existem **5 usuários, 8 pontos, 8 leituras e 5 ocorrências iniciais**. São sete
pontos ativos e um inativo. Use o cidadão **1 — Ana Lima** e o ponto
**3 — Mercado Vila Aurora** para a jornada completa. Os usuários e locais são
fictícios. O usuário 5 é administrador e é rejeitado no fluxo de cidadão.

| Ponto | Cenário inicial |
|---|---|
| 1 | 25%, leitura de 3 minutos antes da inicialização |
| 2 | 65%, leitura de 5 minutos antes da inicialização |
| 3 | 92%, leitura de 1 minuto antes da inicialização |
| 5 | Apenas leitura histórica de 45 minutos |
| 6 | Nenhuma leitura |
| 7 | Múltiplas leituras fora de ordem; a mais recente tem 85% |
| 8 | Inativo; acessível somente na consulta direta |

As leituras não se renovam durante a sessão. O ponto 4 começa com uma leitura de
exatamente 15 minutos e pode aparecer sem dados atualizados logo após iniciar:
o relógio avança enquanto o programa é utilizado. Isso respeita a regra temporal.

## Testes e qualidade

Na raiz do pacote:

```sh
dart analyze
dart test
```

Para saída expandida: `dart test --reporter expanded`. Para conferir formatação
sem editar arquivos: `dart format --output=none --set-exit-if-changed .`.

A validação registrada nesta entrega executou **174 testes aprovados**, incluindo
integração que inicia o `bin/main.dart` real. Veja os logs em
[docs/evidencias](docs/evidencias/README.md). Os testes de tempo usam referência
controlada; os testes de processo verificam a jornada sem depender de datas exatas.

Se houver falha de conectividade ao obter pacotes, `dart pub get --offline` pode
ser usado somente quando todas as dependências já estiverem no cache. Não desative
TLS nem altere configurações globais para executar a demonstração.

## Limitações do MVP

- Sem login ou autenticação real: selecionar ID é apenas identificação demonstrativa,
  sem garantia real de privacidade ou autorização.
- Sem persistência permanente, banco de dados ou integração com backend/API REST.
- Sem comunicação com sensores físicos ou atualização automática das leituras.
- Sem Flutter ou interface gráfica implementada neste pacote.
- Protótipo feito em Figma simulando a interface gráfica  

## Protótipo Figma - Binova 

Binova ♻️ - https://www.figma.com/make/upgwPsqNuVbJIoNBMjSLWz/Prot%C3%B3tipo-Mobile-Binova?t=kAh9k60csVqNpCqS-1

## Integrantes

| Integrante | RM |
|---|---|
| Gustavo de Jesus | 567926 |
| Gustavo Siciliano | 568419 |
| Samuel Keniti | 567614 |
| Manuel Pedro | 567458 |
| Vinicius Morrone | 566884 |

Os nomes dos usuários mockados não identificam integrantes da equipe.

## Evidências e gravação

- [Índice e resultados técnicos](docs/evidencias/README.md).
- [Log completo dos testes](docs/evidencias/testes.txt).
- [Entradas da demonstração](docs/evidencias/entradas-demonstracao.txt).
- [Saída real da jornada completa](docs/evidencias/demonstracao.txt).
- [Roteiro de gravação de 3 a 5 minutos](docs/roteiro-demonstracao.md).

As evidências são registros textuais de comandos executados. Não representam um
vídeo gravado nem comprovam publicação no GitHub.

## Preparação para publicação

Consulte [docs/publicacao-github.md](docs/publicacao-github.md) para revisar os
arquivos e publicar manualmente. O `pubspec.lock` deve acompanhar esta aplicação;
`.dart_tool/`, `build/` e `coverage/` são ignorados. Nenhum remoto, licença ou link
de vídeo foi presumido. A publicação permanece sob responsabilidade do grupo.
