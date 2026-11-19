import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:binova_mobile/console/binova_console.dart';
import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';
import 'package:test/test.dart';

/// Executa o entrypoint real: composição, mocks e serviços não são substituídos.
/// Somente stdin/stdout/stderr são controlados. Não depende de datas absolutas.
Future<String> executarMain(List<String> entradas) async {
  final Process processo = await Process.start(Platform.resolvedExecutable, [
    'bin/main.dart',
  ], workingDirectory: Directory.current.path);
  final Future<String> saida = processo.stdout.transform(utf8.decoder).join();
  final Future<String> erros = processo.stderr.transform(utf8.decoder).join();
  try {
    for (final String entrada in entradas) {
      processo.stdin.writeln(entrada);
    }
    // Fechar stdin permite testar EOF sem deixar um processo aguardando entrada.
    await processo.stdin.close();
    final int codigo = await processo.exitCode.timeout(
      const Duration(seconds: 15),
    );
    final String texto = (await saida).replaceAll('\r\n', '\n');
    expect(await erros, isEmpty, reason: 'O processo não deve emitir erros.');
    expect(codigo, 0, reason: texto);
    return texto;
  } finally {
    processo.kill();
  }
}

List<String> consultasDoCidadao(String saida) => saida
    .split('===== MINHAS OCORRÊNCIAS =====')
    .skip(1)
    .map((String bloco) => bloco.split('===== BINOVA =====').first)
    .toList();

List<int> idsDasOcorrencias(String bloco) =>
    RegExp(r'Ocorrência ID: (\d+)')
        .allMatches(bloco)
        .map((RegExpMatch match) => int.parse(match.group(1)!))
        .toList();

void main() {
  test(
    'A: main real mantém cadastro e consulta durante jornada completa',
    () async {
      final String saida = await executarMain([
        '1',
        '2',
        '3',
        '3',
        '1',
        '3',
        '1',
        'Relato integrado A',
        '4',
        '1',
        '0',
      ]);
      expect(saida, contains('===== PONTOS DE COLETA ====='));
      expect(saida, contains('===== DETALHES DO PONTO ====='));
      expect(saida, contains('Nome: Mercado Vila Aurora'));
      expect(saida, contains('Ocorrência registrada com sucesso! ID: 6'));
      final String consulta = consultasDoCidadao(saida).single;
      expect(idsDasOcorrencias(consulta), [1, 5, 6]);
      expect(consulta, contains('Descrição: Relato integrado A'));
      expect(consulta, contains('Ponto: 3 - Mercado Vila Aurora'));
      expect(consulta, contains('Tipo: LIXEIRA_CHEIA'));
      expect(consulta, contains('Status: ABERTA'));
      expect(
        consulta,
        contains(RegExp(r'Criada em: \d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}')),
      );
      expect(saida.trimRight(), endsWith('Binova encerrada. Até logo!'));
    },
  );

  test(
    'B: main real isola cidadãos e preserva o registro ao alternar consultas',
    () async {
      final String saida = await executarMain([
        '3',
        '1',
        '1',
        '4',
        'Exclusivo integrado B',
        '4',
        '2',
        '4',
        '1',
        '0',
      ]);
      final List<String> consultas = consultasDoCidadao(saida);
      expect(consultas, hasLength(2));
      expect(idsDasOcorrencias(consultas[0]), [2]);
      expect(consultas[0], isNot(contains('Exclusivo integrado B')));
      expect(idsDasOcorrencias(consultas[1]), [1, 5, 6]);
      expect(consultas[1], contains('Exclusivo integrado B'));
    },
  );

  test(
    'C: main real rejeita cadastro e aceita o seguinte sem perder dados ou ID',
    () async {
      final String saida = await executarMain([
        '3',
        '1',
        '1',
        '1',
        '   ',
        '4',
        '1',
        '3',
        '1',
        '1',
        '2',
        'Valido integrado C',
        '4',
        '1',
        '0',
      ]);
      expect(
        saida,
        contains('Operação cancelada. A descrição não pode ficar vazia.'),
      );
      final List<String> consultas = consultasDoCidadao(saida);
      expect(idsDasOcorrencias(consultas[0]), [1, 5]);
      expect(idsDasOcorrencias(consultas[1]), [1, 5, 6]);
      expect(consultas[1], contains('Descrição: Valido integrado C'));
      expect(
        'Ocorrência registrada com sucesso!'.allMatches(saida),
        hasLength(1),
      );
    },
  );

  final Map<String, List<String>> entradasAteEof = {
    'menu principal': [],
    'seleção do cidadão': ['3'],
    'seleção do ponto': ['3', '1'],
    'seleção do tipo': ['3', '1', '1'],
    'descrição': ['3', '1', '1', '1'],
    'consulta de ocorrências': ['4'],
  };
  for (final MapEntry<String, List<String>> cenario in entradasAteEof.entries) {
    test('D: main real encerra por EOF em ${cenario.key}', () async {
      final String saida = await executarMain(cenario.value);
      expect(
        saida.trimRight(),
        endsWith('Entrada encerrada. Binova encerrada.'),
      );
      expect('===== BINOVA ====='.allMatches(saida), hasLength(1));
      expect(saida, isNot(contains('Ocorrência registrada com sucesso!')));
    });
  }

  test(
    'C/D: falha e EOF preservam contagem e objetos no armazenamento real',
    () {
      final DateTime referencia = DateTime.utc(2026, 11, 19, 12);
      final DadosMockados dados = DadosMockados.criar(referencia: referencia);
      final OcorrenciaService registros = OcorrenciaService(
        usuarios: dados.usuarios,
        pontosColeta: dados.pontosColeta,
        ocorrencias: dados.ocorrencias,
      );
      final PontoColetaService pontos = PontoColetaService(
        pontosColeta: dados.pontosColeta,
        leituras: dados.leituras,
      );
      final List<String?> entradas = [
        '3',
        '1',
        '1',
        '1',
        '   ',
        '3',
        '1',
        '1',
        '1',
        'Cadastro confirmado',
        '3',
        '1',
        '1',
        '1',
        null,
      ];
      int indice = 0;
      bool falhaVerificada = false;
      BinovaConsole(
        service: pontos,
        ocorrenciaService: registros,
        lerEntrada: () {
          if (indice >= entradas.length) {
            throw StateError('Leitura após EOF.');
          }
          return entradas[indice++];
        },
        escrever: (String mensagem) {
          if (mensagem.startsWith('Operação cancelada.')) {
            expect(registros.listar(), orderedEquals(dados.ocorrencias));
            falhaVerificada = true;
          }
        },
        agora: () => referencia,
      ).executar();
      expect(indice, entradas.length);
      expect(falhaVerificada, isTrue);
      expect(registros.listar(), hasLength(6));
      expect(registros.listar().take(5), orderedEquals(dados.ocorrencias));
      expect(registros.buscarPorId(6)?.descricao, 'Cadastro confirmado');
      expect(dados.ocorrencias, hasLength(5));
    },
  );

  test(
    'E: mesmo ponto envelhece na mesma sessão sem exibir percentual antigo',
    () {
      final DateTime referencia = DateTime.utc(2026, 11, 19, 12);
      final DadosMockados dados = DadosMockados.criar(referencia: referencia);
      final PontoColetaService pontos = PontoColetaService(
        pontosColeta: dados.pontosColeta,
        leituras: dados.leituras,
      );
      final List<String> entradas = ['2', '1', '2', '1', '0'];
      final List<String> mensagens = [];
      int indice = 0;
      int consultas = 0;
      BinovaConsole(
        service: pontos,
        ocorrenciaService: OcorrenciaService(
          usuarios: dados.usuarios,
          pontosColeta: dados.pontosColeta,
          ocorrencias: dados.ocorrencias,
        ),
        lerEntrada: () => entradas[indice++],
        escrever: mensagens.add,
        agora: () => referencia.add(Duration(minutes: consultas++ * 16)),
      ).executar();
      final List<String> detalhes = mensagens
          .where(
            (String mensagem) =>
                mensagem.contains('===== DETALHES DO PONTO ====='),
          )
          .toList();
      expect(detalhes, hasLength(2));
      expect(consultas, 2);
      expect(detalhes[0], contains('ID: 1\n'));
      expect(detalhes[0], contains('Nível de preenchimento: 25%'));
      expect(detalhes[0], contains('Classificação: DISPONIVEL'));
      expect(detalhes[1], contains('ID: 1\n'));
      expect(detalhes[1], contains('Nível de preenchimento: Indisponível'));
      expect(detalhes[1], contains('Classificação: SEM_DADOS_ATUALIZADOS'));
      expect(detalhes[1], isNot(contains('25%')));
      expect(
        detalhes.every(
          (String detalhe) => detalhe.contains('19/11/2026 11:57:00 (UTC)'),
        ),
        isTrue,
      );
      expect(
        dados.leituras.first.registradoEm,
        referencia.subtract(const Duration(minutes: 3)),
      );
    },
  );
}
