import 'enums.dart';

class Ocorrencia {
  Ocorrencia({
    required this.id,
    required this.pontoColetaId,
    required this.usuarioId,
    required this.tipo,
    required this.descricao,
    required this.status,
    required this.criadoEm,
    required this.atualizadoEm,
  }) {
    if (atualizadoEm.isBefore(criadoEm)) {
      throw ArgumentError.value(
        atualizadoEm,
        'atualizadoEm',
        'Não pode anteceder a criação.',
      );
    }
  }

  final int id;
  final int pontoColetaId;
  final int usuarioId;
  final TipoOcorrencia tipo;
  final String descricao;
  final StatusOcorrencia status;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
}
