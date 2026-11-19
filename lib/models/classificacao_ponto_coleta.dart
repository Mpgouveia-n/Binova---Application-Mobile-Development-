enum ClassificacaoPontoColeta {
  disponivel('DISPONIVEL'),
  atencao('ATENCAO'),
  proximaDoLimite('PROXIMA_DO_LIMITE'),
  semDadosAtualizados('SEM_DADOS_ATUALIZADOS');

  const ClassificacaoPontoColeta(this.valorContrato);
  final String valorContrato;
}
