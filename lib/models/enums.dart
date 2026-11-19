
 // Define os perfis de usuário disponíveis no sistema.
enum PapelUsuario {
  cidadao('CIDADAO'),
  admin('ADMIN');

  // Inicializa o valor utilizado no contrato.
  const PapelUsuario(this.valorContrato);

  final String valorContrato;
}

// Define os tipos de ocorrência que podem ser registrados.
enum TipoOcorrencia {
  lixeiraCheia('LIXEIRA_CHEIA'),
  descarteIrregular('DESCARTE_IRREGULAR'),
  estruturaDanificada('ESTRUTURA_DANIFICADA'),
  outro('OUTRO');

  // Inicializa o valor utilizado no contrato.
  const TipoOcorrencia(this.valorContrato);

  final String valorContrato;
}

// Define os possíveis estados de uma ocorrência.
enum StatusOcorrencia {
  aberta('ABERTA'),
  emAtendimento('EM_ATENDIMENTO'),
  resolvida('RESOLVIDA');

  // Inicializa o valor utilizado no contrato.
  const StatusOcorrencia(this.valorContrato);

  final String valorContrato;
}
