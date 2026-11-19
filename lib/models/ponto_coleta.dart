
 // Representa um ponto de coleta cadastrado no sistema.
class PontoColeta {
  // Inicializa o ponto e valida sua capacidade.
  PontoColeta({
    required this.id,
    required this.nome,
    required this.descricaoLocalizacao,
    required this.capacidadeLitros,
    required this.ativo,
    required this.criadoEm,
  }) {
    if (!capacidadeLitros.isFinite || capacidadeLitros <= 0) {
      throw ArgumentError.value(
        capacidadeLitros,
        'capacidadeLitros',
        'Deve ser finita e positiva.',
      );
    }
  }

  final int id;
  final String nome;
  final String descricaoLocalizacao;
  final double capacidadeLitros;
  final bool ativo;
  final DateTime criadoEm;
}
