
import 'dart:io';

import 'package:binova_mobile/console/binova_console.dart';
import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';

// Inicializa os dados, configura os serviços e executa o Binova.
void main() {
  // Cria os dados fictícios utilizados durante a sessão.
  final DadosMockados dados = DadosMockados.criar(
    referencia: DateTime.now(),
  );

  // Configura o serviço de consulta dos pontos de coleta.
  final PontoColetaService service = PontoColetaService(
    pontosColeta: dados.pontosColeta,
    leituras: dados.leituras,
  );

  // Inicializa o console com os serviços e as operações de entrada e saída.
  BinovaConsole(
    service: service,
    ocorrenciaService: OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: dados.ocorrencias,
    ),
    lerEntrada: () => stdin.readLineSync(),
    escrever: (String mensagem) => stdout.writeln(mensagem),
    agora: DateTime.now,
  ).executar();
}
