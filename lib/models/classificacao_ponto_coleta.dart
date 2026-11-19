
 // Define os níveis de preenchimento dos pontos de coleta.
enum ClassificacaoPontoColeta {
  disponivel('DISPONIVEL'),
  atencao('ATENCAO'),
  proximaDoLimite('PROXIMA_DO_LIMITE'),
  semDadosAtualizados('SEM_DADOS_ATUALIZADOS');

  // Inicializa o valor utilizado no contrato.
  const ClassificacaoPontoColeta(this.valorContrato);

  final String valorContrato;
}
