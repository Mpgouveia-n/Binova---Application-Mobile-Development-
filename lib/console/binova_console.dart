import 'package:binova_mobile/models/classificacao_ponto_coleta.dart';
import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
import 'package:binova_mobile/models/usuario.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';

// Organiza o menu, pesquisas e identificação simulada no terminal.
class BinovaConsole {
  BinovaConsole({
    required this.service,
    required this.lerEntrada,
    required this.escrever,
    required this.agora,
    this.ocorrenciaService,
  });

  final PontoColetaService service;
  final String? Function() lerEntrada;
  final void Function(String) escrever;
  final DateTime Function() agora;
  // Opcional para preservar clientes e testes da navegação de pontos.
  // A aplicação principal sempre injeta uma única instância por sessão.
  final OcorrenciaService? ocorrenciaService;

  // Cidadão identificado durante a sessão; não representa autenticação real.
  Usuario? _usuarioAtual;

  // Exibe o menu e direciona cada opção para sua funcionalidade.
  void executar() {
    escrever('\n========================================');
    escrever('          BEM-VINDO À BINOVA');
    escrever('========================================');

    while (true) {
      final String identificacao = _usuarioAtual == null
          ? 'Cidadão: não identificado'
          : 'Cidadão: ${_usuarioAtual!.nome}';

      escrever(
        '\n===== BINOVA =====\n'
        'Monitoramento inteligente de resíduos\n'
        '$identificacao\n'
        '----------------------------------------\n'
        '1 - Listar pontos de coleta\n\n'
        '2 - Consultar ponto por ID\n\n'
        '3 - Registrar ocorrência\n\n'
        '4 - Consultar minhas ocorrências\n\n'
        '5 - Pesquisar pontos por nome ou local\n\n'
        '6 - Painel geral dos pontos\n\n'
        '7 - Identificar cidadão\n\n'
        '8 - Fazer cadastro rápido\n\n'
        '0 - Sair\n'
        '----------------------------------------\n'
        'Escolha uma opção:',
      );

      final String? entrada = lerEntrada();
      if (entrada == null) {
        _encerrarPorEof();
        return;
      }

      switch (entrada.trim()) {
        case '0':
          escrever('Binova encerrada. Até logo!');
          return;
        case '1':
          _listarPontos();
        case '2':
          if (!_consultarPorId()) {
            _encerrarPorEof();
            return;
          }
        case '3':
          if (!_operarOcorrencias(registrar: true)) {
            _encerrarPorEof();
            return;
          }
        case '4':
          if (!_operarOcorrencias(registrar: false)) {
            _encerrarPorEof();
            return;
          }
        case '5':
          if (!_pesquisarPontos()) {
            _encerrarPorEof();
            return;
          }
        case '6':
          _painelGeral();
        case '7':
          if (!_identificar()) {
            _encerrarPorEof();
            return;
          }
        case '8':
          if (!_cadastrar()) {
            _encerrarPorEof();
            return;
          }
        case '':
          escrever('Nenhuma opção informada. Digite uma opção do menu.');
        default:
          escrever('Opção inválida. Escolha uma opção exibida no menu.');
      }
    }
  }

  void _listarPontos() {
    escrever('\n===== PONTOS DE COLETA =====');
    final List<PontoColeta> pontos = service.listarAtivos();
    if (pontos.isEmpty) {
      escrever('Nenhum ponto de coleta ativo disponível.');
      return;
    }
    final DateTime referencia = agora();
    for (final PontoColeta ponto in pontos) {
      final DetalhesPontoColeta detalhes = service.consultarDetalhes(
        ponto.id,
        referencia: referencia,
      )!;
      escrever(
        '\nID: ${ponto.id}\n'
        'Nome: ${ponto.nome}\n'
        'Localização: ${ponto.descricaoLocalizacao}\n'
        'Nível: ${_nivel(detalhes)}\n'
        'Situação: ${detalhes.classificacao.valorContrato}\n'
        'Descrição: ${_classificacao(detalhes.classificacao)}\n'
        '${_barra(detalhes)}\n'
        '----------------------------------------',
      );
    }
  }

  /// Retorna false somente quando a entrada é encerrada durante a consulta.
  bool _consultarPorId() {
    escrever('Informe o ID do ponto de coleta:');
    final String? entrada = lerEntrada();
    if (entrada == null) return false;
    final String texto = entrada.trim();
    if (texto.isEmpty) {
      escrever('Nenhum ID informado. Digite um número inteiro positivo.');
      return true;
    }
    final int? id = int.tryParse(texto);
    if (id == null || id <= 0) {
      escrever('ID inválido. Digite um número inteiro positivo.');
      return true;
    }
    final DetalhesPontoColeta? detalhes = service.consultarDetalhes(
      id,
      referencia: agora(),
    );
    if (detalhes == null) {
      escrever('Ponto de coleta com ID $id não encontrado.');
      return true;
    }
    final PontoColeta ponto = detalhes.ponto;
    final DateTime? data = detalhes.leituraMaisRecente?.registradoEm;
    escrever(
      '\n===== DETALHES DO PONTO =====\n\n'
      'ID: ${ponto.id}\n'
      'Nome: ${ponto.nome}\n'
      'Localização: ${ponto.descricaoLocalizacao}\n'
      'Capacidade: ${_numero(ponto.capacidadeLitros)} litros\n'
      'Ativo: ${ponto.ativo ? 'Sim' : 'Não'}\n\n'
      'Última leitura: ${data == null ? 'Não disponível' : _formatarData(data)}\n'
      'Nível de preenchimento: ${_nivel(detalhes)}\n'
      'Classificação: ${detalhes.classificacao.valorContrato}\n'
      'Descrição: ${_classificacao(detalhes.classificacao)}\n'
      '${_barra(detalhes)}',
    );
    if (data != null &&
        detalhes.classificacao ==
            ClassificacaoPontoColeta.semDadosAtualizados) {
      escrever('O registro exibido não é válido para o estado atual.');
    }
    return true;
  }

  static const Map<int, TipoOcorrencia> _tipos = {
    1: TipoOcorrencia.lixeiraCheia,
    2: TipoOcorrencia.descarteIrregular,
    3: TipoOcorrencia.estruturaDanificada,
    4: TipoOcorrencia.outro,
  };

  bool _operarOcorrencias({required bool registrar}) {
    final OcorrenciaService? ocorrencias = ocorrenciaService;
    if (ocorrencias == null) {
      escrever('Serviço de ocorrências não configurado.');
      return true;
    }
    try {
      escrever('\n===== IDENTIFICAÇÃO =====');
      final List<Usuario> cidadaos = ocorrencias.listarCidadaos();
      if (cidadaos.isEmpty) {
        escrever('Nenhum cidadão disponível para seleção.');
        return true;
      }
      int usuarioId;
      if (_usuarioAtual != null) {
        usuarioId = _usuarioAtual!.id;
        escrever('Cidadão identificado: ${_usuarioAtual!.nome}');
      } else {
        for (final cidadao in cidadaos) {
          escrever('ID: ${cidadao.id} - ${cidadao.nome}');
        }
        usuarioId = _lerId('Informe o ID do cidadão:');
        ocorrencias.validarCidadao(usuarioId);
        // A seleção direta mantém a navegação original sem iniciar sessão.
      }
      if (registrar) {
        _registrarOcorrencia(ocorrencias, usuarioId);
      } else {
        _listarOcorrencias(ocorrencias, usuarioId);
      }
      return true;
    } on _FimEntradaConsole {
      return false;
    } on FormatException catch (erro) {
      escrever('Operação cancelada. ${erro.message}');
      return true;
    } on ValidacaoOcorrenciaException catch (erro) {
      escrever('Operação cancelada. ${erro.mensagem}');
      return true;
    }
  }

  String _lerTexto(String mensagem) {
    escrever(mensagem);
    final String? entrada = lerEntrada();
    if (entrada == null) throw const _FimEntradaConsole();
    return entrada;
  }

  int _lerId(String mensagem) {
    final int? id = int.tryParse(_lerTexto(mensagem).trim());
    if (id == null || id <= 0) {
      throw const FormatException('Informe um ID inteiro positivo.');
    }
    return id;
  }

  void _registrarOcorrencia(OcorrenciaService ocorrencias, int usuarioId) {
    escrever('\n===== NOVA OCORRÊNCIA =====');
    final int pontoId = _lerId('Informe o ID do ponto de coleta:');
    ocorrencias.validarPontoAtivo(pontoId);
    for (final MapEntry<int, TipoOcorrencia> opcao in _tipos.entries) {
      escrever(
        '${opcao.key} - ${opcao.value.valorContrato.replaceAll('_', ' ')}',
      );
    }
    final int? escolha = int.tryParse(
      _lerTexto('Selecione o tipo de ocorrência:').trim(),
    );
    final TipoOcorrencia? tipo = _tipos[escolha];
    if (tipo == null) {
      throw const FormatException('Tipo de ocorrência inválido.');
    }
    final String descricao = _lerTexto('Descreva o problema:');
    final Ocorrencia nova = ocorrencias.registrar(
      usuarioId: usuarioId,
      pontoColetaId: pontoId,
      tipo: tipo,
      descricao: descricao,
      referencia: agora(),
    );
    escrever('Ocorrência registrada com sucesso! ID: ${nova.id}');
  }

  void _listarOcorrencias(OcorrenciaService ocorrencias, int usuarioId) {
    final List<Ocorrencia> registros = ocorrencias.listarPorCidadao(usuarioId);
    escrever('\n===== MINHAS OCORRÊNCIAS =====');
    if (registros.isEmpty) {
      escrever('Nenhuma ocorrência encontrada para este cidadão.');
      return;
    }
    for (final Ocorrencia ocorrencia in registros) {
      final PontoColeta? ponto = service.buscarPorId(ocorrencia.pontoColetaId);
      escrever(
        '\nOcorrência ID: ${ocorrencia.id}\n'
        'Ponto: ${ocorrencia.pontoColetaId} - ${ponto?.nome ?? 'Nome indisponível'}\n'
        'Tipo: ${ocorrencia.tipo.valorContrato}\n'
        'Descrição: ${ocorrencia.descricao}\n'
        'Status: ${ocorrencia.status.valorContrato}\n'
        'Criada em: ${_formatarData(ocorrencia.criadoEm)}',
      );
    }
  }

  // Permite procurar pontos ativos por nome, local ou ID.
  bool _pesquisarPontos() {
    escrever('\n===== PESQUISAR PONTOS =====');
    escrever('Digite o nome, a localização ou o ID do ponto:');
    final entrada = lerEntrada();
    if (entrada == null) return false;
    final termo = entrada.trim().toLowerCase();
    if (termo.isEmpty) {
      escrever('Informe algum texto para pesquisar.');
      return true;
    }
    final encontrados = service.listarAtivos().where((ponto) =>
        ponto.id.toString() == termo ||
        ponto.nome.toLowerCase().contains(termo) ||
        ponto.descricaoLocalizacao.toLowerCase().contains(termo)).toList();
    if (encontrados.isEmpty) {
      escrever('Nenhum ponto encontrado para "$entrada".');
      return true;
    }
    final referencia = agora();
    escrever('${encontrados.length} resultado(s) encontrado(s):');
    for (final ponto in encontrados) {
      final detalhes = service.consultarDetalhes(ponto.id, referencia: referencia)!;
      escrever('\n----------------------------------------\n'
          'ID: ${ponto.id} | ${ponto.nome}\n'
          'Local: ${ponto.descricaoLocalizacao}\n'
          'Situação: ${_classificacao(detalhes.classificacao)}\n'
          '${_barra(detalhes)}');
    }
    return true;
  }

  // Resume a situação dos pontos ativos com dados calculados.
  void _painelGeral() {
    escrever('\n===== PAINEL GERAL =====');
    final pontos = service.listarAtivos();
    final referencia = agora();
    var disponiveis = 0;
    var atencao = 0;
    var limite = 0;
    var semDados = 0;
    for (final ponto in pontos) {
      final situacao = service.classificarPonto(ponto.id, referencia: referencia);
      switch (situacao) {
        case ClassificacaoPontoColeta.disponivel:
          disponiveis++;
        case ClassificacaoPontoColeta.atencao:
          atencao++;
        case ClassificacaoPontoColeta.proximaDoLimite:
          limite++;
        default:
          semDados++;
      }
    }
    escrever('Pontos ativos: ${pontos.length}\n'
        'Disponíveis: $disponiveis\n'
        'Em atenção: $atencao\n'
        'Próximos do limite: $limite\n'
        'Sem dados atualizados: $semDados');
    final ocorrencias = ocorrenciaService;
    if (ocorrencias != null) {
      escrever('Ocorrências registradas: ${ocorrencias.listar().length}');
    }
    escrever('----------------------------------------');
  }

  // Entra como cidadão existente por ID, nome ou e-mail.
  bool _identificar() {
    escrever('\n===== IDENTIFICAÇÃO =====');
    final ocorrencias = ocorrenciaService;
    if (ocorrencias == null) {
      escrever('Serviço de ocorrências não configurado.');
      return true;
    }
    escrever('Digite o ID, nome ou e-mail do cidadão:');
    final entrada = lerEntrada();
    if (entrada == null) return false;
    final termo = entrada.trim();
    if (termo.isEmpty) {
      escrever('Informe um nome, ID ou e-mail.');
      return true;
    }
    final resultados = ocorrencias.pesquisarCidadaos(termo);
    if (resultados.isEmpty) {
      escrever('Cidadão não encontrado. Use a opção 8 para se cadastrar.');
      return true;
    }
    if (resultados.length == 1) {
      _usuarioAtual = resultados.first;
      escrever('Identificação realizada: ${_usuarioAtual!.nome}');
      return true;
    }
    escrever('Foram encontrados ${resultados.length} cidadãos:');
    for (final usuario in resultados) {
      escrever('ID: ${usuario.id} - ${usuario.nome} (${usuario.email})');
    }
    escrever('Informe o ID exato para selecionar:');
    final escolha = lerEntrada();
    if (escolha == null) return false;
    final id = int.tryParse(escolha.trim());
    final selecionados = resultados.where((usuario) => usuario.id == id).toList();
    if (selecionados.isEmpty) {
      escrever('ID não corresponde aos resultados encontrados.');
      return true;
    }
    _usuarioAtual = selecionados.first;
    escrever('Identificação realizada: ${_usuarioAtual!.nome}');
    return true;
  }

  // Cadastra um cidadão na memória e o identifica automaticamente.
  bool _cadastrar() {
    escrever('\n===== CADASTRO RÁPIDO =====');
    final ocorrencias = ocorrenciaService;
    if (ocorrencias == null) {
      escrever('Serviço de ocorrências não configurado.');
      return true;
    }
    escrever('Informe seu nome completo:');
    final nome = lerEntrada();
    if (nome == null) return false;
    escrever('Informe seu e-mail:');
    final email = lerEntrada();
    if (email == null) return false;
    try {
      final novo = ocorrencias.cadastrarCidadao(
        nome: nome, email: email, referencia: agora(),
      );
      _usuarioAtual = novo;
      escrever('Cadastro realizado! Bem-vindo(a), ${novo.nome}.');
      escrever('Seu ID de cidadão é ${novo.id}.');
    } on ValidacaoOcorrenciaException catch (erro) {
      escrever('Cadastro não realizado. ${erro.mensagem}');
    }
    return true;
  }

  // Traduz as classificações técnicas para nomes amigáveis.
  String _classificacao(ClassificacaoPontoColeta valor) {
    switch (valor) {
      case ClassificacaoPontoColeta.disponivel:
        return 'Disponível';
      case ClassificacaoPontoColeta.atencao:
        return 'Atenção';
      case ClassificacaoPontoColeta.proximaDoLimite:
        return 'Próximo do limite';
      case ClassificacaoPontoColeta.semDadosAtualizados:
        return 'Sem dados atualizados';
    }
  }

  // Desenha uma barra textual proporcional ao nível de preenchimento.
  String _barra(DetalhesPontoColeta detalhes) {
    if (detalhes.classificacao == ClassificacaoPontoColeta.semDadosAtualizados) {
      return '[----------] Sem leitura válida';
    }
    final nivel = detalhes.leituraMaisRecente!.nivelPercentual;
    final preenchidos = (nivel / 10).round().clamp(0, 10);
    return '[${'#' * preenchidos}${'-' * (10 - preenchidos)}] ${_numero(nivel)}%';
  }

  // A decisão sobre atualização é exclusivamente a classificação do serviço.
  String _nivel(DetalhesPontoColeta detalhes) =>
      detalhes.classificacao == ClassificacaoPontoColeta.semDadosAtualizados
      ? 'Indisponível'
      : '${_numero(detalhes.leituraMaisRecente!.nivelPercentual)}%';

  String _numero(double valor) =>
      valor == valor.truncateToDouble() ? valor.toStringAsFixed(0) : '$valor';

  String _formatarData(DateTime data) {
    String dois(int valor) => valor.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)}/${data.year} '
        '${dois(data.hour)}:${dois(data.minute)}:${dois(data.second)} '
        '(${data.isUtc ? 'UTC' : 'horário local'})';
  }

  void _encerrarPorEof() => escrever('Entrada encerrada. Binova encerrada.');
}

class _FimEntradaConsole implements Exception {
  const _FimEntradaConsole();
}
