class LeituraSensor {
  LeituraSensor({
    required this.id,
    required this.pontoColetaId,
    required this.distanciaCm,
    required this.nivelPercentual,
    required this.registradoEm,
  }) {
    if (!distanciaCm.isFinite || distanciaCm < 0) {
      throw ArgumentError.value(
        distanciaCm,
        'distanciaCm',
        'Deve ser finita e não negativa.',
      );
    }
    if (!nivelPercentual.isFinite ||
        nivelPercentual < 0 ||
        nivelPercentual > 100) {
      throw ArgumentError.value(
        nivelPercentual,
        'nivelPercentual',
        'Deve ser finito e estar entre 0 e 100.',
      );
    }
  }

  final int id;
  final int pontoColetaId;
  final double distanciaCm;
  final double nivelPercentual;
  final DateTime registradoEm;
}
