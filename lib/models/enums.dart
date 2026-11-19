/// Os valores do contrato conceitual ficam centralizados nas enumerações.
enum PapelUsuario {
  cidadao('CIDADAO'),
  admin('ADMIN');

  const PapelUsuario(this.valorContrato);
  final String valorContrato;
}

enum TipoOcorrencia {
  lixeiraCheia('LIXEIRA_CHEIA'),
  descarteIrregular('DESCARTE_IRREGULAR'),
  estruturaDanificada('ESTRUTURA_DANIFICADA'),
  outro('OUTRO');

  const TipoOcorrencia(this.valorContrato);
  final String valorContrato;
}

enum StatusOcorrencia {
  aberta('ABERTA'),
  emAtendimento('EM_ATENDIMENTO'),
  resolvida('RESOLVIDA');

  const StatusOcorrencia(this.valorContrato);
  final String valorContrato;
}
