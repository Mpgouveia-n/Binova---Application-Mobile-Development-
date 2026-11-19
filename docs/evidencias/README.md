# Evidências técnicas — TASK 08

Registros da execução de **19/11/2026**, produzidos na raiz do pacote
`binova_mobile`. Cada log identifica o comando, o instante da captura com offset,
o código de saída e os fluxos stdout/stderr capturados. As saídas não foram
reescritas como exemplos; os títulos são metadados acrescentados à captura.

| Verificação | Resultado observado | Registro |
|---|---|---|
| Dart SDK | 3.13.1 stable, Windows x64 | [dart-versao.txt](dart-versao.txt) |
| Dependências | `Got dependencies!`, saída 0 | [dependencias.txt](dependencias.txt) |
| Análise estática | `No issues found!`, saída 0 | [analise.txt](analise.txt) |
| Testes | **174 aprovados**, `All tests passed!`, saída 0 | [testes.txt](testes.txt) |
| Jornada completa | Cadastro ID 6 e consulta na mesma sessão; saída 0 | [demonstracao.txt](demonstracao.txt) |

Os testes foram executados com `dart test --reporter expanded`, equivalente à
suíte de `dart test` com relatório detalhado. A ordem das mensagens de testes
concorrentes pode variar entre execuções.

## Jornada registrada

Comando: `dart run bin/main.dart`. A entrada foi fornecida ao processo e fechada
de forma controlada, sem digitação humana. O programa foi encerrado pela opção 0.
O transcript de stdout não repete automaticamente as entradas recebidas via pipe;
elas estão integralmente registradas em
[entradas-demonstracao.txt](entradas-demonstracao.txt).

| Etapa | Entradas |
|---|---|
| Listar pontos | `1` |
| Consultar Mercado Vila Aurora | `2`, `3` |
| Registrar ocorrência | `3`, cidadão `1`, ponto `3`, tipo `1`, descrição |
| Descrição utilizada | `Recipiente cheio na entrada do mercado.` |
| Consultar registros de Ana Lima | `4`, cidadão `1` |
| Encerrar | `0` |

A consulta apresentou as ocorrências mockadas 1 e 5 e a recém-criada 6, vinculada
ao ponto 3, com tipo `LIXEIRA_CHEIA` e status `ABERTA`. A saída real contém as datas
da execução. Não foram usados sensores reais, backend ou persistência permanente.

## Condições e limites da evidência

- Foi utilizado o executável do Dart SDK instalado; o caminho pessoal foi omitido
  dos metadados publicados, mantendo a forma de comando `dart`.
- Foi reutilizado um diretório auxiliar temporário para `APPDATA`, restrito ao
  processo de validação, e o cache de pacotes instalado. Não houve alteração global.
- O log de dependências registra sucesso online; não foi necessário fallback offline.
- Os registros contêm somente dados fictícios do MVP. Não incluem tokens, senhas
  reais, caminhos pessoais ou arquivos temporários do ambiente.
- Estes arquivos não comprovam gravação de vídeo ou publicação no GitHub.

Para repetir a demonstração manualmente, consultar
[roteiro-demonstracao.md](../roteiro-demonstracao.md).
