import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:binova_mobile/console/binova_console.dart';
import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';
import 'package:test/test.dart';

// Executa o aplicativo real em um processo separado e captura sua saída.
Future<String> executarMain(List<String> entradas) async {
  final processo = await Process.start(Platform.resolvedExecutable, [
    'bin/main.dart',
  ], workingDirectory: Directory.current.path);

  final saida = processo.stdout.transform(utf8.decoder).join();
  final erros = processo.stderr.transform(utf8.decoder).join();

  try {
    for (final entrada in entradas) {
      processo.stdin.writeln(entrada);
    }

    // Encerra a entrada para simular EOF.
    await processo.stdin.close();

    final codigo = await processo.exitCode.timeout(const Duration(seconds: 15));

    final texto = (await saida).replaceAll('\r\n', '\n');

    expect(await erros, isEmpty, reason: 'O processo não deve emitir erros.');
    expect(codigo, 0, reason: texto);

    return texto;
  } finally {
    processo.kill();
  }
}

// Separa os blocos de consulta de ocorrências exibidos no console.
List<String> consultasDoCidadao(String saida) {
  return saida
      .split('===== MINHAS OCORRÊNCIAS =====')
      .skip(1)
      .map((bloco) => bloco.split('===== BINOVA =====').first)
      .toList();
}

// Extrai os IDs das ocorrências apresentados em uma consulta.
List<int> idsDasOcorrencias(String bloco) {
  return RegExp(
    r'Ocorrência ID: (\d+)',
  ).allMatches(bloco).map((match) => int.parse(match.group(1)!)).toList();
}

void main() {
  // Verifica cadastro, navegação e consulta no aplicativo real.
  test('A: jornada completa mantém o cadastro e a consulta', () async {
    final saida = await executarMain([
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

    final consulta = consultasDoCidadao(saida).single;

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
  });

  // Confirma que cada cidadão visualiza somente suas ocorrências.
  test('B: consultas mantêm os registros separados por cidadão', () async {
    final saida = await executarMain([
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

    final consultas = consultasDoCidadao(saida);

    expect(consultas, hasLength(2));
    expect(idsDasOcorrencias(consultas[0]), [2]);
    expect(consultas[0], isNot(contains('Exclusivo integrado B')));
    expect(idsDasOcorrencias(consultas[1]), [1, 5, 6]);
    expect(consultas[1], contains('Exclusivo integrado B'));
  });

  // Garante que uma tentativa inválida não prejudica o cadastro seguinte.
  test('C: cadastro inválido não altera os dados nem consome ID', () async {
    final saida = await executarMain([
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

    final consultas = consultasDoCidadao(saida);

    expect(idsDasOcorrencias(consultas[0]), [1, 5]);
    expect(idsDasOcorrencias(consultas[1]), [1, 5, 6]);
    expect(consultas[1], contains('Descrição: Valido integrado C'));
    expect(
      'Ocorrência registrada com sucesso!'.allMatches(saida),
      hasLength(1),
    );
  });

  // Testa o encerramento por EOF em todas as etapas da navegação.
  final entradasAteEof = <String, List<String>>{
    'menu principal': [],
    'seleção do cidadão': ['3'],
    'seleção do ponto': ['3', '1'],
    'seleção do tipo': ['3', '1', '1'],
    'descrição': ['3', '1', '1', '1'],
    'consulta de ocorrências': ['4'],
  };

  for (final cenario in entradasAteEof.entries) {
    test('D: encerra por EOF em ${cenario.key}', () async {
      final saida = await executarMain(cenario.value);

      expect(
        saida.trimRight(),
        endsWith('Entrada encerrada. Binova encerrada.'),
      );
      expect('===== BINOVA ====='.allMatches(saida), hasLength(1));
      expect(saida, isNot(contains('Ocorrência registrada com sucesso!')));
    });
  }

  // Confere que uma falha e um EOF não alteram registros indevidamente.
  test('C/D: falha e EOF preservam os dados da aplicação', () {
    final referencia = DateTime.utc(2026, 11, 19, 12);
    final dados = DadosMockados.criar(referencia: referencia);

    final registros = OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: dados.ocorrencias,
    );

    final pontos = PontoColetaService(
      pontosColeta: dados.pontosColeta,
      leituras: dados.leituras,
    );

    final entradas = <String?>[
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

    var indice = 0;
    var falhaVerificada = false;

    BinovaConsole(
      service: pontos,
      ocorrenciaService: registros,
      lerEntrada: () {
        if (indice >= entradas.length) {
          throw StateError('Leitura após EOF.');
        }
        return entradas[indice++];
      },
      escrever: (mensagem) {
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
  });

  // Verifica a atualização da classificação quando a leitura envelhece.
  test('E: leitura antiga deixa de apresentar percentual atualizado', () {
    final referencia = DateTime.utc(2026, 11, 19, 12);
    final dados = DadosMockados.criar(referencia: referencia);

    final pontos = PontoColetaService(
      pontosColeta: dados.pontosColeta,
      leituras: dados.leituras,
    );

    final entradas = ['2', '1', '2', '1', '0'];
    final mensagens = <String>[];

    var indice = 0;
    var consultas = 0;

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

    final detalhes = mensagens
        .where((mensagem) => mensagem.contains('===== DETALHES DO PONTO ====='))
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
        (detalhe) => detalhe.contains('19/11/2026 11:57:00 (UTC)'),
      ),
      isTrue,
    );

    expect(
      dados.leituras.first.registradoEm,
      referencia.subtract(const Duration(minutes: 3)),
    );
  });
}
