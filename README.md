# Binova

**Global Solution 2026/2 | FIAP | Mobile Application Development**

O **Binova** é uma solução CitizenTech voltada ao acompanhamento de pontos de coleta de resíduos e à comunicação de problemas encontrados pela população. O projeto permite consultar a situação dos locais de descarte, acompanhar níveis de preenchimento e registrar ocorrências relacionadas à limpeza urbana.

A aplicação desta disciplina foi desenvolvida em **Dart Console**, com navegação por menus e armazenamento das informações durante a execução, conforme adaptação autorizada pelo professor. O projeto também conta com um protótipo visual de cinco telas no Figma, que apresenta a proposta de experiência para dispositivos móveis.

## Problema e público beneficiado

O acúmulo de resíduos e o descarte irregular dificultam a conservação dos espaços públicos. Nem sempre o cidadão consegue identificar a situação de um ponto de coleta ou comunicar um problema de maneira organizada.

O Binova foi pensado para moradores que utilizam os pontos de coleta e para equipes responsáveis pela limpeza e pelo acompanhamento desses locais. A proposta reúne consulta e comunicação em um fluxo simples: localizar um ponto, verificar sua situação e registrar uma ocorrência quando necessário.

## Objetivos de Desenvolvimento Sustentável

O projeto está alinhado a dois Objetivos de Desenvolvimento Sustentável da Agenda 2030 da ONU:

| ODS | Relação com o Binova |
|---|---|
| **ODS 11: Cidades e Comunidades Sustentáveis** | Apoiar o cuidado com os espaços urbanos por meio do acompanhamento dos pontos de coleta e da participação dos cidadãos. |
| **ODS 12: Consumo e Produção Responsáveis** | Incentivar a atenção ao descarte adequado de resíduos e facilitar a identificação de problemas nos locais de coleta. |

## Adequação da entrega às orientações do professor

A proposta original de Mobile Application Development previa o desenvolvimento em Flutter, com navegação entre telas, gerenciamento de estado e formulários próprios de uma interface gráfica.

Para a entrega do Binova, **o professor autorizou o desenvolvimento em Dart puro, por meio de uma aplicação de console, em substituição à implementação em Flutter**. Também foi concedida **dispensa dos requisitos 3 (gerenciamento de estado com `StatefulWidget` e `setState()`) e 4 (formulário com `Form`, `TextFormField` e validação visual)**, pois esses recursos são específicos do fluxo de interface gráfica previsto inicialmente.

Por esse motivo, o repositório não contém um aplicativo Flutter, telas implementadas com widgets nem esses componentes de formulário e gerenciamento de estado. No Dart Console, as interações equivalentes são realizadas por menus, leitura de dados, validações e serviços. A apresentação visual da solução está disponível separadamente no protótipo de cinco telas do Figma.

Essa adaptação diz respeito ao formato autorizado para a disciplina e não altera a proposta CitizenTech do projeto.


## Por que existe uma pasta de integração com a API Java?

Além da aplicação original de Mobile em Dart Console, o repositório contém a pasta `lib/api/`, criada **para atender a uma solicitação da disciplina de Java Advanced**: demonstrar a comunicação entre a API Java Spring Boot e uma aplicação Mobile.

**Essa integração não foi exigida pelo professor de Mobile Application Development.** Por isso, foi desenvolvida como uma versão complementar e independente, sem substituir a entrega original da disciplina, seus dados simulados ou seu fluxo de execução.

A aplicação principal de Mobile continua sendo executada com `dart run bin/main.dart` e **não depende de Java, servidor HTTP ou banco de dados**. A versão integrada possui arquivos e inicialização próprios, separados dentro de `lib/api/`. Sua documentação e o procedimento de execução ficam no **[README específico da integração](lib/api/README.md)**, sem necessidade de seguir essas instruções para avaliar a entrega de Mobile.

Para referência, o projeto Java Advanced está disponível no **[repositório da API Java](https://github.com/GustavoSiciliano/GlobalSolution_2026_Java)**, e sua demonstração está no **[vídeo de Java](https://youtu.be/2SlwoG4p7Oc)**.

## Tecnologias utilizadas

- **Dart**, com null safety e SDK compatível com `^3.13.1`.
- **Git e GitHub**, para versionamento do código e documentação.
- **Figma**, para o protótipo visual com cinco telas.
- **Pacotes `test` e `lints`**, utilizados no desenvolvimento.

A **versão original** em Dart não exige Flutter, emulador, servidor, banco de dados ou conexão com sensores para ser executada. Os níveis dos recipientes são simulados e não representam medições físicas em tempo real.

## Funcionalidades

O acesso ao Binova começa com a identificação de um cidadão existente ou com um cadastro rápido. Depois disso, o menu principal permite:

1. Listar pontos de coleta ativos.
2. Consultar informações de um ponto pelo ID.
3. Registrar uma ocorrência em um ponto ativo.
4. Consultar as ocorrências do cidadão identificado.
5. Pesquisar pontos por nome ou localização.
6. Visualizar o painel geral com as situações dos pontos de coleta.
7. Sair da conta e retornar à identificação inicial.

A aplicação apresenta os nomes dos cidadãos e dos pontos de coleta, os percentuais de preenchimento e as informações disponíveis em cada consulta. Cadastros e ocorrências realizados permanecem disponíveis até o encerramento do programa.

## Regras de funcionamento

### Classificação dos pontos

| Preenchimento e condição da leitura | Situação |
|---|---|
| De 0% até menos de 50% | `DISPONIVEL` |
| De 50% até menos de 80% | `ATENCAO` |
| De 80% até 100% | `PROXIMA_DO_LIMITE` |
| Sem leitura válida e recente | `SEM_DADOS_ATUALIZADOS` |

O sistema considera a leitura mais recente de cada ponto, independentemente da ordem dos registros. Uma leitura é considerada atual quando tem de zero a quinze minutos de idade, inclusive. Leituras futuras ou com mais de quinze minutos não são utilizadas para determinar o estado atual. Em caso de empate de horário, permanece a primeira leitura encontrada.

A listagem principal mostra somente pontos ativos. Pontos inativos podem ser consultados por ID, mas não recebem novos registros de ocorrência.

### Identificação e ocorrências

A identificação ocorre no início da execução, com a opção de utilizar um cidadão já cadastrado ou fazer um novo cadastro. Essa identificação organiza os registros por cidadão durante a sessão; não representa autenticação com senha.

O registro de ocorrência exige um cidadão válido, um ponto ativo, um tipo de ocorrência disponível e uma descrição preenchida. Descrições vazias ou formadas somente por espaços são rejeitadas. Novas ocorrências recebem o status `ABERTA` e um ID sequencial, calculado a partir do maior identificador existente.

Os registros são armazenados em memória. Ao encerrar e iniciar novamente a aplicação, a base inicial é recriada.

## Organização do projeto

| Pasta | Responsabilidade |
|---|---|
| `bin/` | Inicialização da aplicação pelo arquivo `main.dart`. |
| `lib/models/` | Estruturas de usuário, ponto de coleta, leitura, ocorrência e enumerações. |
| `lib/data/` | Conjunto inicial de informações utilizadas pela aplicação. |
| `lib/services/` | Consultas, validações, classificação de pontos e gerenciamento de ocorrências. |
| `lib/console/` | Tela inicial de acesso, menus, pesquisas e apresentação dos resultados. |
| `lib/api/` | Versão complementar de integração HTTP com a API Java, desenvolvida para a disciplina de Java Advanced; separada do Mobile original. |
| `test/` | Testes dos modelos, serviços e fluxos do console. |

A separação por responsabilidades facilita a leitura do código e permite manter as regras de negócio independentes da apresentação no terminal.

## Como executar o projeto

### 1. Preparar o ambiente

Instale o **Dart SDK 3.13.1 ou superior**, respeitando a faixa de versões declarada no `pubspec.yaml`. Depois, abra o terminal do VS Code ou PowerShell e confira:

```powershell
dart --version
```

O comando deve apresentar a versão instalada do Dart. Não é necessário iniciar o Flutter.

### 2. Abrir a pasta correta

Clone o repositório ou baixe seu conteúdo pelo GitHub:

```powershell
git clone https://github.com/Mpgouveia-n/Binova---Application-Mobile-Development-.git
cd Binova---Application-Mobile-Development-
```

Localize o arquivo `pubspec.yaml`. Se ele estiver na pasta `binova_mobile`, entre nela:

```powershell
cd binova_mobile
```

**Os próximos comandos devem ser executados na pasta que contém o `pubspec.yaml`.**

### 3. Instalar as dependências

```powershell
dart pub get
```

### 4. Iniciar o Binova (versão original de Mobile)

```powershell
dart run bin/main.dart
```

Na primeira tela, escolha entre entrar com um cadastro existente e realizar um cadastro rápido. Após a identificação, o sistema abrirá o menu principal.

## Passo a passo para conhecer as funcionalidades

Este é um percurso sugerido para a apresentação da aplicação:

1. Execute `dart run bin/main.dart`.
2. Na tela inicial, selecione **Entrar com cadastro existente**.
3. Escolha o cidadão **Ana Lima**, identificado pelo ID `1`, ou pesquise pelo nome, conforme a orientação exibida no terminal.
4. No menu principal, escolha **1** para listar os pontos ativos.
5. Escolha **5** e pesquise por `Mercado` para encontrar o **Mercado Vila Aurora**.
6. Escolha **2** e informe o ID `3` para consultar esse ponto diretamente.
7. Escolha **6** para visualizar o painel geral e as classificações.
8. Escolha **3** para registrar uma ocorrência. Informe o ponto `3`, selecione um dos tipos exibidos e descreva o problema.
9. Escolha **4** para consultar a ocorrência na lista do cidadão identificado.
10. Escolha **7** para sair da conta e retornar à tela inicial, sem encerrar a execução.
11. Se desejar, utilize **Fazer cadastro rápido** e confira a identificação com o novo nome.
12. Utilize **0** para encerrar a aplicação.

A classificação de um ponto pode mudar durante a execução porque a validade das leituras considera o horário atual.

## Como verificar o código

Na pasta que contém `pubspec.yaml`, execute os comandos abaixo:

**Análise de código:**

```powershell
dart analyze
```

**Testes automatizados:**

```powershell
dart test
```

**Resultado detalhado dos testes:**

```powershell
dart test --reporter expanded
```

**Conferência de formatação, sem modificar arquivos:**

```powershell
dart format --output=none --set-exit-if-changed .
```

O resultado dos comandos deve ser conferido no terminal, usando a versão do código publicada no repositório.

## Problemas comuns ao executar

| Situação | Como resolver |
|---|---|
| O terminal não reconhece `dart`. | Verifique a instalação do Dart SDK, confirme que a pasta `bin` está no PATH e reinicie o terminal. |
| A versão do Dart é incompatível. | Execute `dart --version` e atualize o SDK para uma versão aceita pelo `pubspec.yaml`. |
| Aparece `No pubspec.yaml file found`. | Entre na pasta correta do projeto antes de executar os comandos. |
| Os imports `package:binova_mobile` não são reconhecidos. | Execute `dart pub get` na pasta do `pubspec.yaml` e reinicie a análise do VS Code, se necessário. |
| O pacote `test` não é encontrado. | Execute `dart pub get` e confirme que as dependências foram instaladas. |
| O download das dependências falha. | Verifique a conexão com a internet e tente novamente. O comando `dart pub get --offline` só funciona se os pacotes já estiverem no cache. |
| Uma opção ou um ID não é aceito. | Confira as opções mostradas na tela, digite um número válido e pressione Enter. |
| Os dados cadastrados não aparecem após reiniciar. | Os registros são mantidos apenas durante a execução atual. |

Evite apagar o `pubspec.lock` para corrigir erros sem antes verificar a causa. Também não é necessário remover manualmente a pasta `.dart_tool`, pois ela é gerenciada pelo Dart e deve permanecer no `.gitignore`.

## Protótipo mobile

O projeto possui um protótipo visual no Figma que apresenta as funcionalidades organizadas para uso em um aplicativo para celular. São cinco telas: **Início, Pontos de coleta, Detalhes do ponto, Registrar ocorrência e Minhas ocorrências**.

O protótipo utiliza uma identidade visual Eco-Tech, com indicadores de preenchimento, pesquisa, histórico de registros e navegação inferior. Ele complementa a aplicação executada em Dart Console e demonstra a proposta de interface para dispositivos móveis.

**[Visualizar o protótipo Binova no Figma](https://www.figma.com/design/qxJAkVzKzr1JdKEHtsQDuU/Binova-%E2%80%94-Prot%C3%B3tipo-Mobile-para-Avalia%C3%A7%C3%A3o--5-telas-?node-id=0-1)**

## Vídeo demonstrativo da aplicação e do protótipo

O vídeo apresenta o objetivo do Binova, a organização do código, a navegação no terminal, a identificação de cidadãos, a consulta dos pontos de coleta, o registro de ocorrências e o protótipo mobile.

**[Assistir à demonstração do Binova no YouTube](https://youtu.be/iXxDHLVQCTA)**

## Repositório GitHub

**[Binova | Mobile Application Development](https://github.com/Mpgouveia-n/Binova---Application-Mobile-Development-)**

A evolução do desenvolvimento pode ser acompanhada pela seção de commits do GitHub.

## Uso de inteligência artificial generativa

O grupo utilizou **ChatGPT (OpenAI)** como ferramenta de apoio à organização da documentação, esclarecimento de conceitos, revisão de trechos de código e análise de possíveis erros. 

## Integrantes

| Integrante | RM |
|---|---|
| Gustavo de Jesus | 567926 |
| Gustavo Siciliano | 568419 |
| Samuel Keniti | 567614 |
| Manuel Pedro | 567458 |
| Vinicius Morrone | 566884 |