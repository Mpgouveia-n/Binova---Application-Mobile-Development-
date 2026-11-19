import 'package:binova_mobile/console/apresentacao.dart';
import 'package:test/test.dart';

void main() {
  test('apresenta boas-vindas, contexto acadêmico e próximas etapas', () {
    final mensagem = gerarMensagemApresentacao();
    expect(mensagem, contains('Bem-vindo à Binova!'));
    expect(mensagem, contains('Simulação acadêmica'));
    expect(mensagem, contains('Global Solution 2026/2 — FIAP'));
    expect(
      mensagem,
      contains('As funcionalidades serão implementadas nas próximas etapas.'),
    );
  });
}
