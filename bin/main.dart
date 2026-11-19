import 'dart:io';

import 'package:binova_mobile/console/binova_console.dart';
import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';

void main() {
  final DadosMockados dados = DadosMockados.criar(referencia: DateTime.now());
  final PontoColetaService service = PontoColetaService(
    pontosColeta: dados.pontosColeta,
    leituras: dados.leituras,
  );
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
