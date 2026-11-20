# Binova | Integração Dart Console + API Java

Este diretório contém uma **versão complementar do Binova em Dart Console**, criada para demonstrar o consumo HTTP da API desenvolvida na disciplina de **Java Advanced** da Global Solution 2026/2.

A integração foi preparada para atender à demonstração entre Java e Mobile solicitada na disciplina de Java. **Ela não é uma exigência do professor de Mobile Application Development**, que autorizou a entrega original em Dart Console. Por isso, a versão original continua independente, com dados locais, e não precisa do Java para funcionar.

Este README trata apenas da **execução e verificação da integração**. A apresentação da proposta, as ODS e as funcionalidades completas estão no README principal do Mobile; a arquitetura e os endpoints do servidor estão no README do Java.

## Links do projeto

| Material | Link |
|---|---|
| GitHub - Mobile (Dart Console) | https://github.com/Mpgouveia-n/Binova---Application-Mobile-Development- |
| GitHub - Java Advanced (API Spring Boot) | https://github.com/GustavoSiciliano/GlobalSolution_2026_Java |
| Vídeo - Java e integração | https://youtu.be/2SlwoG4p7Oc |
| Vídeo - Mobile original | https://youtu.be/iXxDHLVQCTA |
| Protótipo visual - Figma | https://www.figma.com/design/qxJAkVzKzr1JdKEHtsQDuU |

## O que é necessário

- **Dart SDK** compatível com a versão indicada no `pubspec.yaml` do Mobile.
- **JDK 21**, para executar a API Java.
- Dois terminais: um para o Spring Boot e outro para o Dart.
- Porta `8080` livre para o Java, conforme a configuração padrão.
- Dependências dos dois projetos instaladas na primeira execução.

O Dart integrado utiliza `HttpClient`, da biblioteca padrão do Dart. **Não é necessário Flutter, emulador ou navegador para executar o console.** O Swagger é usado apenas para preparar e conferir os dados na API.

## Arquivos desta integração

Os caminhos abaixo são relativos à **raiz do repositório Mobile**, onde está o `pubspec.yaml`:

```text
lib/api/
├── README.md
├── api_config.dart
├── api_client.dart
├── bin/
│   └── main_api.dart
├── console/
│   └── binova_console_api.dart
└── services/
    ├── auth_api_service.dart
    ├── ponto_coleta_api_service.dart
    └── ocorrencia_api_service.dart
```

- `api_config.dart`: endereço-base do servidor HTTP.
- `api_client.dart`: envio das requisições e tratamento das respostas.
- `services/`: login, pontos de coleta e ocorrências.
- `console/`: menus e mensagens apresentados ao usuário.
- `bin/main_api.dart`: inicialização da versão integrada.

**Atenção:** o arquivo de entrada está em `lib/api/bin/main_api.dart`, **não** em `bin/main_api.dart`.

## Passo a passo de execução

### 1. Iniciar a API Java - primeiro terminal

Clone o repositório Java e abra sua pasta, que contém `pom.xml`:

```powershell
git clone https://github.com/GustavoSiciliano/GlobalSolution_2026_Java.git
cd GlobalSolution_2026_Java
```

No **mesmo terminal**, habilite os usuários de demonstração e inicie o servidor:

```powershell
$env:BINOVA_DEMO = "true"
$env:APP_DEMO_ADMIN_PASSWORD = "AdminLocal2026"
$env:APP_DEMO_CIDADAO_PASSWORD = "CidadaoLocal2026"
.\mvnw.cmd spring-boot:run
```

Espere a inicialização terminar e **mantenha esse terminal aberto**. Confira:

- Swagger: http://localhost:8080/swagger-ui.html
- Saúde da API: http://localhost:8080/actuator/health

Se a página não abrir imediatamente, confirme que o processo Java terminou de iniciar. O Swagger não é um servidor independente e não precisa ficar aberto no navegador para o Dart funcionar; quem precisa continuar em execução é o **Spring Boot**.

### 2. Cadastrar ao menos um ponto de coleta

A versão integrada **não carrega os pontos fictícios do Mobile original**. Ela lê os dados existentes no banco da API Java. Se o banco estiver vazio, a lista no Dart estará vazia.

No Swagger:

1. Execute `POST /api/auth/login` usando `admin@binova.local` e a senha `AdminLocal2026`.
2. Copie o campo `token` da resposta e utilize **Authorize** para autenticar como administrador.
3. Execute `POST /api/pontos-coleta` com um exemplo:

```json
{
  "nome": "Ecoponto Demonstracao",
  "descricaoLocalizacao": "Entrada principal",
  "capacidadeLitros": 100
}
```

4. Anote o **ID retornado**. Confirme pelo `GET /api/pontos-coleta` que o ponto foi cadastrado e está ativo.

As leituras de sensor são opcionais para listar os pontos, mas, **sem uma leitura válida e recente**, a consulta da situação pode apresentar `SEM_DADOS_ATUALIZADOS`. Consulte o README do Java para o procedimento de criação das leituras pelo Swagger.

### 3. Iniciar o Dart integrado - segundo terminal

Abra um **novo terminal** e acesse a pasta do Mobile que contém o arquivo `pubspec.yaml`:

```powershell
git clone https://github.com/Mpgouveia-n/Binova---Application-Mobile-Development-.git
cd Binova---Application-Mobile-Development-
dart pub get
dart run lib/api/bin/main_api.dart
```

Se você já clonou o repositório Mobile, **não precisa cloná-lo novamente**: basta abrir a pasta e executar os dois últimos comandos.

A configuração padrão está em `lib/api/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:8080';
```

Use esse endereço quando Java e Dart estiverem **na mesma máquina**. Se mudar a porta do Spring Boot, atualize também o endereço no Dart. Para execução em outra máquina ou ambiente, `localhost` precisa ser substituído pelo endereço realmente acessível do servidor.

### 4. Testar a comunicação

Na tela inicial do Dart, selecione **1 - Entrar com email e senha**:

| Perfil | E-mail | Senha local |
|---|---|---|
| Cidadão | `cidadao@binova.local` | `CidadaoLocal2026` |
| Administrador | `admin@binova.local` | `AdminLocal2026` |

Para verificar o fluxo de ocorrências, utilize o **perfil cidadão**:

1. Após o login, escolha **1 - Listar pontos de coleta ativos**. O ponto criado pelo Swagger deverá aparecer.
2. Escolha **2 - Consultar ponto por ID e situação** e informe o ID retornado pelo Java.
3. Escolha **5 - Pesquisar pontos por nome** e procure por `Ecoponto`.
4. Escolha **3 - Registrar ocorrência**, informe o ID de um ponto ativo, selecione o tipo e preencha a descrição.
5. Escolha **4 - Minhas ocorrências** para conferir o registro enviado à API.
6. Se desejar, consulte `GET /api/ocorrencias` no Swagger com o token adequado e confirme o registro feito pelo Dart.

**Resultado esperado:** o Dart envia requisições HTTP ao Java, que autentica o usuário, consulta os pontos e registra a ocorrência no banco da API. Os dados da versão integrada não são os registros em memória da versão original.

## Erros comuns e como resolver

| Situação | O que verificar |
|---|---|
| `Could not find file bin/main_api.dart` | Use o caminho correto: `dart run lib/api/bin/main_api.dart`. |
| `No pubspec.yaml file found` | Abra o terminal na raiz do projeto Mobile, onde está o `pubspec.yaml`. |
| Imports `package:binova_mobile` não encontrados | Execute `dart pub get` na raiz do Mobile. |
| `File truncated before or at offset 0x0` | Confira se o arquivo `lib/api/bin/main_api.dart` existe e não está vazio ou incompleto. |
| Erro de importação de `api_client.dart` nos serviços | Verifique a estrutura da pasta `lib/api/` e se os arquivos publicados correspondem aos caminhos de importação. |
| `Connection refused`, `SocketException` ou falha de conexão | Confirme se o Java continua rodando, se a porta é `8080` e se o `baseUrl` aponta para o endereço correto. |
| Swagger não abre ou demora para carregar | Espere o Spring Boot terminar a inicialização; confira os logs e teste `/actuator/health`. Se a máquina suspendeu ou o Java foi encerrado, reinicie o processo. |
| `Configure as senhas dos usuarios de demonstracao` | Defina as três variáveis de demonstração no **mesmo terminal** antes de executar `spring-boot:run`. |
| HTTP `401` ou falha no login | Confira e-mail e senha; se reiniciou a API, entre novamente para obter um JWT válido. Contas antigas no H2 podem manter senhas anteriores. |
| HTTP `403` ao tentar cadastrar um ponto | O cadastro de pontos exige perfil `ADMIN`. O perfil `CIDADAO` é usado para registrar ocorrências. |
| Nenhum ponto aparece na listagem | Cadastre um ponto ativo pelo Swagger. O Dart integrado não importa os dados locais do Mobile original. |
| Ponto aparece, mas sua situação está sem dados | Registre uma leitura válida pelo Java; leituras antigas podem perder a validade após 15 minutos. |
| HTTP `404` | Verifique o ID informado e se o registro existe na base Java atual. |
| HTTP `400` | Confira os campos obrigatórios, os valores e os tipos enviados. |
| Timeout ou HTTP `500` | Confirme se a API está respondendo, consulte o log do terminal Java e repita o teste no Swagger. |
| `Port 8080 was already in use` | Encerre a instância que está ocupando a porta ou configure outra porta, ajustando também o `baseUrl` no Dart. |

## Diferença entre os comandos

| Objetivo | Comando, executado na raiz do Mobile |
|---|---|
| Executar a entrega original de Mobile | `dart run bin/main.dart` |
| Executar a versão integrada à API Java | `dart run lib/api/bin/main_api.dart` |

**A execução original de Mobile não depende do Java.** A versão HTTP foi adicionada apenas como demonstração complementar de integração entre as disciplinas.

Para detalhes da API, regras de negócio, autenticação, endpoints e testes automatizados, consulte o [repositório Java Advanced](https://github.com/GustavoSiciliano/GlobalSolution_2026_Java).
