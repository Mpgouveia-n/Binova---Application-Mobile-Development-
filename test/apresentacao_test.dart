import 'package:binova_mobile/console/apresentacao.dart';
import 'package:test/test.dart';

void main() {
  // Valida a apresentação e as funcionalidades descritas no projeto.
  test('apresenta boas-vindas, contexto acadêmico e funcionalidades', () {
    final mensagem = gerarMensagemApresentacao();

    expect(mensagem, contains('Bem-vindo à Binova!'));
    expect(mensagem, contains('Simulação acadêmica'));
    expect(mensagem, contains('Global Solution 2026/2 - FIAP'));
    expect(mensagem, contains('Consulte pontos de coleta'));
    expect(mensagem, contains('acompanhe os níveis de preenchimento'));
    expect(mensagem, contains('registre ocorrências'));
  });
}
