import 'package:binova_mobile/models/classificacao_ponto_coleta.dart';
import 'package:binova_mobile/models/leitura_sensor.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';

/// Consulta uma fotografia dos dados, sem alterar as coleções recebidas.
class PontoColetaService {
  PontoColetaService({
    required Iterable<PontoColeta> pontosColeta,
    required Iterable<LeituraSensor> leituras,
  }) : _pontos = List.unmodifiable(pontosColeta),
       _leituras = List.unmodifiable(leituras);

  static const Duration validadeLeitura = Duration(minutes: 15);
  final List<PontoColeta> _pontos;
  final List<LeituraSensor> _leituras;

  List<PontoColeta> listarAtivos() =>
      List.unmodifiable(_pontos.where((PontoColeta ponto) => ponto.ativo));

  /// A busca por ID também permite consultar pontos inativos.
  PontoColeta? buscarPorId(int id) {
    for (final PontoColeta ponto in _pontos) {
      if (ponto.id == id) return ponto;
    }
    return null;
  }

  /// IDs inexistentes não possuem histórico e retornam lista vazia.
  List<LeituraSensor> consultarLeituras(int pontoId) {
    if (buscarPorId(pontoId) == null) return const [];
    return List.unmodifiable(
      _leituras.where(
        (LeituraSensor leitura) => leitura.pontoColetaId == pontoId,
      ),
    );
  }

  /// Seleciona pela data, sem ordenar nem filtrar leituras antigas ou futuras.
  /// Em empate de data, mantém a primeira leitura encontrada.
  LeituraSensor? obterLeituraMaisRecente(int pontoId) =>
      _maisRecente(consultarLeituras(pontoId));

  /// Null distingue um ID inexistente de um ponto sem dados atualizados.
  ClassificacaoPontoColeta? classificarPonto(
    int pontoId, {
    required DateTime referencia,
  }) => consultarDetalhes(pontoId, referencia: referencia)?.classificacao;

  DetalhesPontoColeta? consultarDetalhes(
    int pontoId, {
    required DateTime referencia,
  }) {
    final PontoColeta? ponto = buscarPorId(pontoId);
    if (ponto == null) return null;
    final List<LeituraSensor> historico = consultarLeituras(pontoId);
    final LeituraSensor? recente = _maisRecente(historico);
    return DetalhesPontoColeta(
      ponto: ponto,
      leituras: historico,
      leituraMaisRecente: recente,
      classificacao: _classificar(recente, referencia),
    );
  }

  LeituraSensor? _maisRecente(Iterable<LeituraSensor> leituras) {
    LeituraSensor? recente;
    for (final LeituraSensor leitura in leituras) {
      if (recente == null ||
          leitura.registradoEm.isAfter(recente.registradoEm)) {
        recente = leitura;
      }
    }
    return recente;
  }

  ClassificacaoPontoColeta _classificar(
    LeituraSensor? leitura,
    DateTime referencia,
  ) {
    if (leitura == null) return ClassificacaoPontoColeta.semDadosAtualizados;
    final Duration idade = referencia.difference(leitura.registradoEm);
    if (idade.isNegative || idade > validadeLeitura) {
      return ClassificacaoPontoColeta.semDadosAtualizados;
    }
    if (leitura.nivelPercentual < 50) {
      return ClassificacaoPontoColeta.disponivel;
    }
    if (leitura.nivelPercentual < 80) return ClassificacaoPontoColeta.atencao;
    return ClassificacaoPontoColeta.proximaDoLimite;
  }
}

/// Resultado de consulta para uma futura apresentação de detalhes no console.
class DetalhesPontoColeta {
  DetalhesPontoColeta({
    required this.ponto,
    required List<LeituraSensor> leituras,
    required this.leituraMaisRecente,
    required this.classificacao,
  }) : leituras = List.unmodifiable(leituras);

  final PontoColeta ponto;
  final List<LeituraSensor> leituras;
  final LeituraSensor? leituraMaisRecente;
  final ClassificacaoPontoColeta classificacao;
}
