
import 'package:binova_mobile/models/classificacao_ponto_coleta.dart';
import 'package:binova_mobile/models/leitura_sensor.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';

// Responsável pelas consultas e classificações dos pontos de coleta.
class PontoColetaService {
  // Inicializa o serviço com cópias não modificáveis dos dados.
  PontoColetaService({
    required Iterable<PontoColeta> pontosColeta,
    required Iterable<LeituraSensor> leituras,
  }) : _pontos = List.unmodifiable(pontosColeta),
       _leituras = List.unmodifiable(leituras);

  static const Duration validadeLeitura = Duration(minutes: 15);

  final List<PontoColeta> _pontos;
  final List<LeituraSensor> _leituras;

  // Retorna somente os pontos de coleta ativos.
  List<PontoColeta> listarAtivos() {
    return List.unmodifiable(
      _pontos.where((ponto) => ponto.ativo),
    );
  }

  // Busca um ponto pelo ID, incluindo pontos inativos.
  PontoColeta? buscarPorId(int id) {
    for (final ponto in _pontos) {
      if (ponto.id == id) {
        return ponto;
      }
    }

    return null;
  }

  // Consulta o histórico de leituras de um ponto de coleta.
  List<LeituraSensor> consultarLeituras(int pontoId) {
    if (buscarPorId(pontoId) == null) {
      return const [];
    }

    return List.unmodifiable(
      _leituras.where(
        (leitura) => leitura.pontoColetaId == pontoId,
      ),
    );
  }

  // Obtém a leitura mais recente registrada para o ponto.
  LeituraSensor? obterLeituraMaisRecente(int pontoId) {
    return _maisRecente(consultarLeituras(pontoId));
  }

  // Classifica o ponto conforme o preenchimento e a data da leitura.
  ClassificacaoPontoColeta? classificarPonto(
    int pontoId, {
    required DateTime referencia,
  }) {
    return consultarDetalhes(
      pontoId,
      referencia: referencia,
    )?.classificacao;
  }

  // Reúne o ponto, seu histórico e a classificação atual.
  DetalhesPontoColeta? consultarDetalhes(
    int pontoId, {
    required DateTime referencia,
  }) {
    final ponto = buscarPorId(pontoId);

    if (ponto == null) {
      return null;
    }

    final historico = consultarLeituras(pontoId);
    final recente = _maisRecente(historico);

    return DetalhesPontoColeta(
      ponto: ponto,
      leituras: historico,
      leituraMaisRecente: recente,
      classificacao: _classificar(recente, referencia),
    );
  }

  // Identifica a leitura com a data mais recente.
  LeituraSensor? _maisRecente(Iterable<LeituraSensor> leituras) {
    LeituraSensor? recente;

    for (final leitura in leituras) {
      if (recente == null ||
          leitura.registradoEm.isAfter(recente.registradoEm)) {
        recente = leitura;
      }
    }

    return recente;
  }

  // Define a classificação conforme as regras de preenchimento.
  ClassificacaoPontoColeta _classificar(
    LeituraSensor? leitura,
    DateTime referencia,
  ) {
    if (leitura == null) {
      return ClassificacaoPontoColeta.semDadosAtualizados;
    }

    final idade = referencia.difference(leitura.registradoEm);

    if (idade.isNegative || idade > validadeLeitura) {
      return ClassificacaoPontoColeta.semDadosAtualizados;
    }

    if (leitura.nivelPercentual < 50) {
      return ClassificacaoPontoColeta.disponivel;
    }

    if (leitura.nivelPercentual < 80) {
      return ClassificacaoPontoColeta.atencao;
    }

    return ClassificacaoPontoColeta.proximaDoLimite;
  }
}

// Armazena os detalhes consultados de um ponto de coleta.
class DetalhesPontoColeta {
  // Inicializa os detalhes e protege o histórico de alterações.
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
