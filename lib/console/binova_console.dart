import 'package:binova_mobile/models/classificacao_ponto_coleta.dart';
import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
import 'package:binova_mobile/models/usuario.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';

/// Entrada null representa EOF. O relógio é consultado uma vez por operação.
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

  void executar() {
    escrever('Bem-vindo à Binova!');
    escrever('Simulação acadêmica — Global Solution 2026/2 — FIAP.');
    escrever('Dados simulados em memória, sem sensores físicos.');
    while (true) {
      escrever(
        '\n===== BINOVA =====\n'
        'Monitoramento inteligente de resíduos\n\n'
        '1 - Listar pontos de coleta\n'
        '2 - Consultar ponto por ID\n'
        '3 - Registrar ocorrência\n'
        '4 - Consultar minhas ocorrências\n'
        '0 - Sair\n\n'
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
        case '':
          escrever('Nenhuma opção informada. Digite 1, 2, 3, 4 ou 0.');
        default:
          escrever('Opção inválida. Digite 1, 2, 3, 4 ou 0.');
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
        'Situação: ${detalhes.classificacao.valorContrato}',
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
      'Classificação: ${detalhes.classificacao.valorContrato}',
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
      escrever(
        'Identificação demonstrativa: seleção de ID, sem autenticação '
        'ou garantia real de privacidade.',
      );
      final List<Usuario> cidadaos = ocorrencias.listarCidadaos();
      if (cidadaos.isEmpty) {
        escrever('Nenhum cidadão disponível para seleção.');
        return true;
      }
      for (final Usuario cidadao in cidadaos) {
        escrever('ID: ${cidadao.id} - ${cidadao.nome}');
      }
      final int usuarioId = _lerId('Informe o ID do cidadão:');
      ocorrencias.validarCidadao(usuarioId);
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
