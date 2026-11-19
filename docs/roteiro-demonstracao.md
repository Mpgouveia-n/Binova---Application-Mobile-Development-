# Roteiro de demonstração — Binova

Duração planejada: **4 minutos e 30 segundos**. Este é um roteiro para gravação;
não indica que o vídeo já foi gravado. A aplicação demonstrada é Dart via console.
O Figma é um trabalho separado e não precisa ser aberto nesta gravação.

## Preparar antes de gravar

1. Disponibilizar ao apresentador a pasta completa `binova_mobile`, com `bin/`,
   `lib/`, `test/`, `pubspec.yaml` e `pubspec.lock`.
2. Abrir a pasta no editor e um terminal na raiz do pacote.
3. Usar Dart compatível com `^3.13.1`, validado em 3.13.1. Não iniciar emulador.
4. Executar os comandos abaixo antes de começar o vídeo. Se o terminal estiver na
   pasta superior, executar primeiro `cd binova_mobile`.

```sh
dart --version
dart pub get
dart analyze
dart test
```

O resultado registrado nesta entrega foi `No issues found!` e 174 testes
aprovados. Ao gravar, mostrar o resultado da execução do próprio apresentador;
se falhar, verificar o problema antes de afirmar que passou.

Não exibir contas pessoais, notificações, senhas, tokens ou pastas privadas.
Aumentar a fonte do terminal e ajustar a janela para mostrar os resultados.
No PowerShell, `Clear-Host` limpa a tela. Em Linux/macOS, usar `clear`.
Não limpar a tela durante uma pergunta do programa: esse texto viraria uma entrada.

## Sequência da gravação

| Tempo | Ação na tela | Fala sugerida |
|---|---|---|
| 0:00–0:30 | Mostrar nome do projeto no README | “A Binova é uma solução acadêmica da Global Solution 2026/2 da FIAP, voltada a CitizenTech e sustentabilidade. O MVP demonstra a consulta de pontos de coleta e a participação do cidadão no relato de problemas.” |
| 0:30–1:00 | Mostrar `bin/`, `lib/` e `test/` no editor | “A inicialização compõe os componentes. Modelos representam o domínio; dados fornece os mocks; serviços concentram regras; console trata a interação. Os testes cobrem as camadas e a jornada integrada.” |
| 1:00–1:35 | Iniciar o programa e selecionar `1` | “Aqui são listados apenas os pontos ativos. Os percentuais e classificações usam leituras simuladas. Pontos sem leitura válida apresentam nível indisponível.” |
| 1:35–2:05 | Selecionar `2` e depois ID `3` | “O Mercado Vila Aurora tem capacidade de 120 litros. Em uma sessão recém-iniciada, a leitura é de 92%, classificada como próxima do limite. Também vemos a data e o horário do registro.” |
| 2:05–3:00 | Selecionar `3` e preencher o cadastro conforme a tabela abaixo | “A identificação por ID é demonstrativa, sem senha ou autenticação. O serviço valida cidadão e ponto ativo. Escolhemos o tipo e descrevemos o problema. A confirmação apresenta o ID gerado.” |
| 3:00–3:35 | Selecionar `4`, cidadão `1`, localizar ocorrência `6` | “A consulta inclui as ocorrências iniciais e o relato que acabamos de criar. Ele está aberto e permanece disponível durante esta mesma sessão.” |
| 3:35–4:10 | Mostrar a saída da consulta e os resultados dos testes já executados | “As leituras são válidas até 15 minutos. Este MVP não tem banco de dados, backend, sensores físicos nem autenticação real. Ao encerrar, os registros da sessão são descartados. O protótipo visual é desenvolvido separadamente.” |
| 4:10–4:30 | Selecionar `0` e mostrar o encerramento | “A aplicação encerra normalmente. A Binova permite demonstrar o monitoramento simulado e o registro de problemas pelos cidadãos, com regras e testes automatizados.” |

## Comando de inicialização

```sh
dart run bin/main.dart
```

Iniciar uma **sessão nova** para seguir o roteiro: assim há cinco ocorrências
iniciais e o primeiro cadastro válido recebe o ID 6. Não encerrar ou reiniciar
entre o cadastro e a consulta. Reiniciar apaga os registros adicionados.

## Entradas exatas, uma por pergunta

| Passo | Pergunta/contexto | Entrada |
|---|---|---|
| 1 | Menu: listar pontos | `1` |
| 2 | Menu: consultar detalhes | `2` |
| 3 | ID do ponto | `3` |
| 4 | Menu: registrar ocorrência | `3` |
| 5 | ID do cidadão — Ana Lima | `1` |
| 6 | ID do ponto — Mercado Vila Aurora | `3` |
| 7 | Tipo — lixeira cheia | `1` |
| 8 | Descrição | `Recipiente cheio na entrada do mercado.` |
| 9 | Menu: consultar minhas ocorrências | `4` |
| 10 | ID do cidadão | `1` |
| 11 | Menu: sair | `0` |

Na consulta do cidadão 1 aparecem os IDs 1 e 5 dos mocks e o **ID 6** recém-criado.
Localizar o registro pela descrição, pelo ponto 3 e pelo status `ABERTA`.
As datas serão as da execução. Se houver cadastros extras, o novo ID será maior
que 6; reiniciar o programa antes de uma nova tomada para repetir a sequência.

O ponto 4 pode aparecer sem dados atualizados desde o início porque sua leitura
simulada começa no limite de 15 minutos. Usar o ponto 3 para a demonstração de
nível recente e terminar a gravação em menos de 15 minutos.

## Se algo sair do esperado

- Erro de entrada: a operação é cancelada e o menu volta; repetir a opção desejada.
- Sem pacotes por conexão indisponível: tentar `dart pub get --offline` somente se
  o cache já estiver completo. Não desativar TLS ou alterar rede globalmente.
- Terminal aguardando digitação: responder à pergunta exibida. A opção `0` sai
  quando o menu está ativo. EOF também encerra sem salvar cadastro incompleto.
- Falha ao achar `pubspec.yaml`: entrar na raiz do pacote antes dos comandos Dart.

## Após a gravação

Assistir ao vídeo e conferir legibilidade, áudio e presença da ocorrência criada.
Só então informar o link real conforme a forma de entrega escolhida pelo grupo.
Não afirmar publicação do vídeo ou do repositório enquanto ela não tiver ocorrido.
