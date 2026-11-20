import 'dart:async';
import 'dart:io';

import '../services/auth_api_service.dart';
import '../services/ocorrencia_api_service.dart';
import '../services/ponto_coleta_api_service.dart';

// Interface de terminal que consome os serviços da API Java Spring Boot.
// É independente do console original, que continua utilizando dados locais.
class BinovaApiConsole {
  final AuthApiService authService;
  final PontoColetaApiService pontoColetaService;
  final OcorrenciaApiService ocorrenciaService;

  // Recebe os serviços de API preparados pelo main_api.dart.
  BinovaApiConsole({
    required this.authService,
    required this.pontoColetaService,
    required this.ocorrenciaService,
  });

  String? _nomeUsuario;
  bool _encerrar = false;

  // Inicia o programa exigindo identificação antes de apresentar o menu.
  Future<void> iniciar() async {
    _titulo('BINOVA | INTEGRACAO COM API JAVA');

    while (!_encerrar) {
      if (!authService.autenticado) {
        await _menuAcesso();
      } else {
        await _menuPrincipal();
      }
    }

    stdout.writeln('\nAplicacao encerrada.');
  }

  // Exibe as opções de login, cadastro e encerramento.
  Future<void> _menuAcesso() async {
    stdout.writeln('\n1 - Entrar com email e senha');
    stdout.writeln('2 - Cadastrar novo cidadao');
    stdout.writeln('0 - Encerrar aplicacao');

    final opcao = _ler('Opcao: ');
    if (opcao == null) {
      _encerrar = true;
      return;
    }

    switch (opcao) {
      case '1':
        await _executar(_login, contexto: 'login');
      case '2':
        await _executar(_cadastro, contexto: 'cadastro');
      case '0':
        _encerrar = true;
      default:
        stdout.writeln('Opcao invalida.');
    }
  }

  // Autentica o usuário na API e consulta seu perfil.
  Future<void> _login() async {
    final email = _lerObrigatorio('Email: ');
    if (email == null) return;

    final senha = _lerObrigatorio('Senha: ');
    if (senha == null) return;

    final resposta = await authService.login(email: email, senha: senha);
    try {
      final perfil = await authService.consultarPerfil();
      _nomeUsuario = _texto(perfil['nome']);
    } catch (_) {
      // O JWT continua válido mesmo quando a consulta opcional falha.
      _nomeUsuario = null;
    }

    stdout.writeln('Login realizado com sucesso.');
    stdout.writeln('Usuario: ${_nomeUsuario ?? 'ID ${authService.usuarioId}'}');
    stdout.writeln('Perfil: ${_texto(resposta['papel'])}');
  }

  // Cadastra um cidadão e informa que o login deve ser feito em seguida.
  Future<void> _cadastro() async {
    final nome = _lerObrigatorio('Nome: ');
    if (nome == null) return;

    final email = _lerObrigatorio('Email: ');
    if (email == null) return;

    final senha = _lerObrigatorio('Senha (8 a 72 caracteres): ');
    if (senha == null) return;

    final usuario = await authService.cadastrar(
      nome: nome,
      email: email,
      senha: senha,
    );
    stdout.writeln('Cadastro criado: ${_texto(usuario['nome'])}.');
    stdout.writeln('Agora escolha a opcao 1 para entrar com email e senha.');
  }

  // Mostra o menu operacional somente após o login.
  Future<void> _menuPrincipal() async {
    _titulo('MENU PRINCIPAL');
    stdout.writeln('Conectado: ${_nomeUsuario ?? 'Usuario ${authService.usuarioId}'}');
    stdout.writeln('1 - Listar pontos de coleta ativos');
    stdout.writeln('2 - Consultar ponto por ID e situacao');
    stdout.writeln('3 - Registrar ocorrencia');
    stdout.writeln('4 - Minhas ocorrencias');
    stdout.writeln('5 - Pesquisar pontos por nome');
    stdout.writeln('6 - Painel geral dos pontos');
    stdout.writeln('7 - Sair da conta');
    stdout.writeln('0 - Encerrar aplicacao');

    final opcao = _ler('Opcao: ');
    if (opcao == null) {
      _encerrar = true;
      return;
    }

    switch (opcao) {
      case '1':
        await _executar(_listarPontos);
      case '2':
        await _executar(_consultarPonto);
      case '3':
        await _executar(_registrarOcorrencia);
      case '4':
        await _executar(_minhasOcorrencias);
      case '5':
        await _executar(_pesquisarPontos);
      case '6':
        await _executar(_painelGeral);
      case '7':
        authService.logout();
        _nomeUsuario = null;
        stdout.writeln('Sessao encerrada.');
      case '0':
        _encerrar = true;
      default:
        stdout.writeln('Opcao invalida.');
    }
  }

  // Busca os pontos ativos na API Java, respeitando a paginação.
  Future<void> _listarPontos() async {
    final pagina = await pontoColetaService.listar(ativo: true, tamanho: 20);
    final itens = _itens(pagina);
    _titulo('PONTOS DE COLETA ATIVOS');
    _mostrarPontos(itens);
    _mostrarPaginacao(pagina);
  }

  // Consulta um ponto por ID e solicita sua classificação ao Java.
  Future<void> _consultarPonto() async {
    final id = _lerId('ID do ponto: ');
    if (id == null) return;

    final ponto = await pontoColetaService.consultar(id);
    final situacao = await pontoColetaService.consultarSituacao(id);

    _titulo('DETALHES DO PONTO');
    stdout.writeln('ID: ${_texto(ponto['id'])}');
    stdout.writeln('Nome: ${_texto(ponto['nome'])}');
    stdout.writeln('Localizacao: ${_texto(ponto['descricaoLocalizacao'])}');
    stdout.writeln('Capacidade: ${_texto(ponto['capacidadeLitros'])} litros');
    stdout.writeln('Ativo: ${ponto['ativo'] == true ? 'Sim' : 'Nao'}');
    stdout.writeln('Situacao: ${_texto(situacao['situacao'])}');
    stdout.writeln('Nivel: ${_percentual(situacao['nivelPercentual'])}');
    stdout.writeln('Ultima leitura: ${_texto(situacao['ultimaLeitura'])}');
  }

  // Registra uma ocorrência usando o JWT do cidadão autenticado.
  Future<void> _registrarOcorrencia() async {
    if (authService.papel != 'CIDADAO') {
      stdout.writeln('Somente cidadaos podem registrar ocorrencias.');
      return;
    }

    final id = _lerId('ID do ponto de coleta: ');
    if (id == null) return;

    // Confirma a existência e a condição ativa antes do envio.
    final ponto = await pontoColetaService.consultar(id);
    if (ponto['ativo'] != true) {
      stdout.writeln('Nao e possivel registrar em um ponto inativo.');
      return;
    }

    stdout.writeln('1 - Lixeira cheia');
    stdout.writeln('2 - Descarte irregular');
    stdout.writeln('3 - Estrutura danificada');
    stdout.writeln('4 - Outro');

    final escolha = _ler('Tipo de ocorrencia: ');
    if (escolha == null) return;
    const tipos = {
      '1': 'LIXEIRA_CHEIA',
      '2': 'DESCARTE_IRREGULAR',
      '3': 'ESTRUTURA_DANIFICADA',
      '4': 'OUTRO',
    };
    final tipo = tipos[escolha];
    if (tipo == null) {
      stdout.writeln('Tipo invalido.');
      return;
    }

    final descricao = _lerObrigatorio('Descricao do problema: ');
    if (descricao == null) return;

    final ocorrencia = await ocorrenciaService.registrar(
      pontoColetaId: id,
      tipo: tipo,
      descricao: descricao,
    );

    stdout.writeln('Ocorrencia registrada com sucesso!');
    stdout.writeln('ID: ${_texto(ocorrencia['id'])}');
    stdout.writeln('Status: ${_texto(ocorrencia['status'])}');
  }

  // Lista as ocorrências do usuário autenticado.
  // O Java restringe a listagem de cidadãos ao próprio autor.
  Future<void> _minhasOcorrencias() async {
    final pagina = await ocorrenciaService.listar(tamanho: 20);
    final itens = _itens(pagina);
    _titulo('OCORRENCIAS');

    if (itens.isEmpty) {
      stdout.writeln('Nenhuma ocorrencia encontrada.');
    } else {
      for (final item in itens) {
        stdout.writeln(
          '#${_texto(item['id'])} | Ponto ${_texto(item['pontoColetaId'])} | '
          '${_texto(item['tipo'])} | ${_texto(item['status'])}',
        );
        stdout.writeln('  ${_texto(item['descricao'])}');
        stdout.writeln('  Criada em: ${_texto(item['criadoEm'])}');
      }
    }
    _mostrarPaginacao(pagina);
  }

  // Pesquisa pontos por nome utilizando o endpoint específico da API.
  Future<void> _pesquisarPontos() async {
    final nome = _lerObrigatorio('Nome para pesquisar: ');
    if (nome == null) return;

    final pagina = await pontoColetaService.buscarPorNome(nome, tamanho: 20);
    _titulo('RESULTADOS DA PESQUISA');
    _mostrarPontos(_itens(pagina));
    _mostrarPaginacao(pagina);
  }

  // Apresenta o total de pontos ativos e suas situações atuais.
  // Cada situação é calculada no servidor Java, não no Dart.
  Future<void> _painelGeral() async {
    _titulo('PAINEL GERAL DOS PONTOS');
    final totais = <String, int>{};
    var quantidade = 0;
    var paginaAtual = 0;

    while (true) {
      final pagina = await pontoColetaService.listar(
        ativo: true,
        pagina: paginaAtual,
        tamanho: 20,
      );
      final itens = _itens(pagina);
      for (final ponto in itens) {
        final id = _inteiro(ponto['id']);
        if (id == null) continue;
        final situacao = await pontoColetaService.consultarSituacao(id);
        final estado = _texto(situacao['situacao']);
        totais[estado] = (totais[estado] ?? 0) + 1;
        quantidade++;
      }

      final totalPaginas = _inteiro(pagina['totalPages']);
      paginaAtual++;
      if (itens.isEmpty ||
          (totalPaginas != null && paginaAtual >= totalPaginas) ||
          itens.length < 20) {
        break;
      }
    }

    stdout.writeln('Pontos ativos: $quantidade');
    for (final entrada in totais.entries) {
      stdout.writeln('${entrada.key}: ${entrada.value}');
    }
  }

  // Exibe uma lista de pontos de coleta retornada pela API.
  void _mostrarPontos(List<Map<String, dynamic>> itens) {
    if (itens.isEmpty) {
      stdout.writeln('Nenhum ponto encontrado.');
      return;
    }
    for (final item in itens) {
      stdout.writeln(
        '#${_texto(item['id'])} | ${_texto(item['nome'])} | '
        '${_texto(item['descricaoLocalizacao'])}',
      );
    }
  }

  // Extrai os elementos da propriedade content de uma Page do Spring.
  List<Map<String, dynamic>> _itens(Map<String, dynamic> pagina) {
    final conteudo = pagina['content'];
    if (conteudo is! List) {
      throw const FormatException('A API nao retornou uma lista valida.');
    }
    return conteudo.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Registro retornado em formato invalido.');
      }
      return item;
    }).toList();
  }

  // Mostra a posição atual da paginação de resultados.
  void _mostrarPaginacao(Map<String, dynamic> pagina) {
    final numero = _inteiro(pagina['number']);
    final total = _inteiro(pagina['totalPages']);
    if (numero != null && total != null && total > 0) {
      stdout.writeln('Pagina ${numero + 1} de $total.');
    }
  }

  // Lê uma entrada do terminal. EOF encerra a aplicação.
  String? _ler(String mensagem) {
    stdout.write(mensagem);
    final resposta = stdin.readLineSync();
    if (resposta == null) {
      _encerrar = true;
      return null;
    }
    return resposta.trim();
  }

  // Solicita uma informação obrigatória.
  String? _lerObrigatorio(String mensagem) {
    final resposta = _ler(mensagem);
    if (resposta == null) return null;
    if (resposta.isEmpty) {
      stdout.writeln('Este campo e obrigatorio.');
      return null;
    }
    return resposta;
  }

  // Converte a entrada informada em ID positivo.
  int? _lerId(String mensagem) {
    final resposta = _ler(mensagem);
    if (resposta == null) return null;
    final id = int.tryParse(resposta);
    if (id == null || id <= 0) {
      stdout.writeln('Informe um ID numerico maior que zero.');
      return null;
    }
    return id;
  }

  // Converte números de respostas JSON para inteiros quando possível.
  int? _inteiro(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse('$valor');
  }

  // Formata campos opcionais sem exibir null no terminal.
  String _texto(dynamic valor) {
    return valor == null ? 'Nao informado' : valor.toString();
  }

  // Formata o percentual fornecido pela API.
  String _percentual(dynamic valor) {
    return valor == null ? 'Sem dados atualizados' : '$valor%';
  }

  // Traduz respostas HTTP e falhas locais para mensagens claras ao cidadão.
  // Nenhum corpo JSON, token ou detalhe interno é exibido no terminal.
  String _mensagemErro(Object erro, {String contexto = ''}) {
    if (erro is HttpException) {
      // O ApiClient informa o código como "Erro HTTP 401: ...".
      final codigo = RegExp(r'Erro HTTP\s+(\d{3})')
          .firstMatch(erro.message)?.group(1);
      final status = int.tryParse(codigo ?? '');

      switch (status) {
        case 300:
        case 301:
        case 302:
        case 303:
        case 304:
        case 307:
        case 308:
          return 'A API redirecionou a solicitacao. Verifique o endereco do servidor.';
        case 400:
          return 'Dados invalidos. Confira as informacoes e tente novamente.';
        case 401:
          if (contexto == 'login') {
            return 'Email ou senha incorretos. Tente novamente.';
          }
          return 'Sua sessao nao e mais valida. Faca login novamente.';
        case 402:
          return 'A operacao nao esta disponivel para esta conta.';
        case 403:
          return 'Voce nao tem permissao para realizar esta operacao.';
        case 404:
          return 'Registro nao encontrado.';
        case 405:
          return 'Essa operacao nao e permitida pela API.';
        case 406:
          return 'O servidor nao conseguiu fornecer a resposta solicitada.';
        case 408:
          return 'A solicitacao demorou muito. Tente novamente.';
        case 409:
          return contexto == 'cadastro'
              ? 'Nao foi possivel cadastrar. Este email pode ja estar em uso.'
              : 'Conflito de dados. Verifique as informacoes e tente novamente.';
        case 410:
          return 'O recurso solicitado nao esta mais disponivel.';
        case 413:
          return 'Os dados enviados ultrapassam o tamanho permitido.';
        case 415:
          return 'O formato dos dados enviados nao foi aceito.';
        case 422:
          return 'Os dados enviados nao atendem as regras de validacao.';
        case 429:
          return 'Muitas solicitacoes seguidas. Tente novamente mais tarde.';
        case 500:
          return 'Ocorreu uma falha interna no servidor. Tente novamente.';
        case 501:
          return 'Esta funcionalidade ainda nao e suportada pelo servidor.';
        case 502:
        case 503:
        case 504:
          return 'O servidor esta indisponivel no momento. Tente novamente.';
      }

      if (status != null && status >= 300 && status < 400) {
        return 'O servidor solicitou um redirecionamento inesperado.';
      }
      if (status != null && status >= 400 && status < 500) {
        return 'Nao foi possivel concluir a solicitacao. Confira os dados.';
      }
      if (status != null && status >= 500 && status < 600) {
        return 'O servidor apresentou uma falha. Tente novamente mais tarde.';
      }
      return 'A API retornou uma resposta inesperada.';
    }

    if (erro is SocketException) {
      return 'Nao foi possivel conectar ao Java. Confira se a API esta ligada.';
    }
    if (erro is TimeoutException) {
      return 'O servidor demorou muito para responder. Tente novamente.';
    }
    if (erro is FormatException) {
      return 'A resposta recebida do servidor esta em formato invalido.';
    }
    if (erro is ArgumentError) {
      if (contexto == 'cadastro') {
        return 'Confira nome, email e senha. A senha deve ter de 8 a 72 caracteres.';
      }
      return 'Os dados informados nao sao validos.';
    }
    if (erro is StateError) {
      return 'Sua sessao nao esta disponivel. Faca login novamente.';
    }

    // O ApiClient converte algumas falhas de rede em Exception com mensagem.
    // Reconhecemos somente categorias conhecidas, sem imprimir a excecao bruta.
    final descricao = erro.toString().toLowerCase();
    if (descricao.contains('n\u00e3o foi poss\u00edvel conectar') ||
        descricao.contains('nao foi possivel conectar') ||
        descricao.contains('socketexception') ||
        descricao.contains('connection refused')) {
      return 'Nao foi possivel conectar ao Java. Confira se a API esta ligada.';
    }
    if (descricao.contains('demorou muito') ||
        descricao.contains('timeoutexception') ||
        descricao.contains('timed out')) {
      return 'O servidor demorou muito para responder. Tente novamente.';
    }
    if (descricao.contains('json invalido') ||
        descricao.contains('json inv\u00e1lido')) {
      return 'A resposta recebida do servidor esta em formato invalido.';
    }

    return 'Nao foi possivel concluir a operacao. Tente novamente.';
  }

  // Executa cada operacao sem interromper o menu em caso de falha.
  // Um HTTP 401 fora do login encerra a sessao local para novo acesso.
  Future<void> _executar(
    Future<void> Function() operacao, {
    String contexto = '',
  }) async {
    try {
      await operacao();
    } catch (erro) {
      if (erro is HttpException &&
          contexto != 'login' &&
          RegExp(r'Erro HTTP\s+401(?:\D|$)').hasMatch(erro.message)) {
        authService.logout();
        _nomeUsuario = null;
      }
      stdout.writeln('\n${_mensagemErro(erro, contexto: contexto)}');
    }
  }

  // Imprime um título simples para separar as telas do console.
  void _titulo(String texto) {
    stdout.writeln('\n${'=' * 48}');
    stdout.writeln(texto);
    stdout.writeln('=' * 48);
  }
}
