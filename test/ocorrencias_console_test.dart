import 'package:binova_mobile/console/binova_console.dart';
import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';
import 'package:test/test.dart';

void main() {
  final referencia = DateTime.utc(2026, 11, 19, 12);
  late DadosMockados dados;
  late OcorrenciaService ocorrencias;
  late PontoColetaService pontos;

  // Prepara os serviços e os dados antes de cada teste.
  setUp(() {
    dados = DadosMockados.criar(referencia: referencia);

    pontos = PontoColetaService(
      pontosColeta: dados.pontosColeta,
      leituras: dados.leituras,
    );

    ocorrencias = OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: dados.ocorrencias,
    );
  });

  // Simula as entradas e captura a saída do console.
  String executar(List<String?> entradas, {OcorrenciaService? registros}) {
    var indice = 0;
    final saidas = <String>[];

    BinovaConsole(
      service: pontos,
      ocorrenciaService: registros ?? ocorrencias,
      lerEntrada: () {
        if (indice >= entradas.length) {
          throw StateError('Leitura indevida após fim das entradas.');
        }
        return entradas[indice++];
      },
      escrever: saidas.add,
      agora: () => referencia,
    ).executar();

    expect(indice, entradas.length);
    return saidas.join('\n');
  }

  group('Menu e navegação', () {
    // Verifica as opções do menu e a identificação da simulação.
    test('menu apresenta as opções e identifica a simulação', () {
      final saida = executar(['4', '1', '0']);

      expect(saida, contains('3 - Registrar ocorrência'));
      expect(saida, contains('4 - Consultar minhas ocorrências'));
      expect(
        saida,
        contains('sem autenticação ou garantia real de privacidade'),
      );

      for (final usuario in dados.usuarios.where(
        (u) => u.papel == PapelUsuario.cidadao,
      )) {
        expect(saida, contains('ID: ${usuario.id} - ${usuario.nome}'));
      }

      expect(saida, isNot(contains('Elisa Rocha')));
      expect(saida, isNot(contains('hash-simulado')));
    });

    // Confirma o funcionamento conjunto da navegação e dos cadastros.
    test('cadastros e consultas coexistem com a navegação', () {
      final saida = executar([
        '1',
        '2',
        '3',
        '3',
        '1',
        '1',
        '2',
        'Primeiro relato',
        '3',
        '1',
        '2',
        '3',
        'Segundo relato',
        '4',
        '1',
        '0',
      ]);

      expect(saida, contains('===== PONTOS DE COLETA ====='));
      expect(saida, contains('===== DETALHES DO PONTO ====='));
      expect(saida, contains('Ocorrência ID: 6'));
      expect(saida, contains('Ocorrência ID: 7'));
      expect(ocorrencias.listar(), hasLength(7));
      expect(dados.ocorrencias, hasLength(5));
    });
  });

  group('Cadastro de ocorrências', () {
    // Confirma o cadastro e a consulta do registro na mesma sessão.
    test('cadastro completo permite consultar o registro criado', () {
      final saida = executar([
        '3',
        '1',
        '3',
        '1',
        '  Relato novo  ',
        '4',
        '1',
        '0',
      ]);

      expect(saida, contains('Ocorrência registrada com sucesso! ID: 6'));
      expect(saida, contains('Ocorrência ID: 6'));
      expect(saida, contains('Ponto: 3 - Mercado Vila Aurora'));
      expect(saida, contains('Tipo: LIXEIRA_CHEIA'));
      expect(saida, contains('Descrição: Relato novo\n'));
      expect(saida, contains('Status: ABERTA'));
      expect(saida, contains('Criada em: 19/11/2026 12:00:00 (UTC)'));
      expect(ocorrencias.listar(), hasLength(6));
      expect(ocorrencias.buscarPorId(6)?.descricao, 'Relato novo');
      expect(saida, endsWith('Binova encerrada. Até logo!'));
      expect('===== BINOVA ====='.allMatches(saida), hasLength(3));
    });

    // Relaciona as opções do menu aos tipos de ocorrência.
    final mapeamento = <String, TipoOcorrencia>{
      '1': TipoOcorrencia.lixeiraCheia,
      '2': TipoOcorrencia.descarteIrregular,
      '3': TipoOcorrencia.estruturaDanificada,
      '4': TipoOcorrencia.outro,
    };

    // Verifica se cada opção registra o tipo correspondente.
    for (final opcao in mapeamento.entries) {
      test('seleção ${opcao.key} registra ${opcao.value.valorContrato}', () {
        executar(['3', '1', '1', opcao.key, 'Relato', '0']);
        expect(ocorrencias.buscarPorId(6)?.tipo, opcao.value);
      });
    }
  });

  group('Consulta de ocorrências', () {
    // Verifica a consulta exclusiva dos registros do cidadão.
    test('consulta somente as ocorrências do cidadão selecionado', () {
      final saida = executar(['4', '2', '0']);

      expect(saida, contains('Ocorrência ID: 2\n'));
      expect(saida, contains('Tipo: DESCARTE_IRREGULAR'));
      expect(saida, contains('Status: EM_ATENDIMENTO'));

      for (final outro in [1, 3, 4, 5]) {
        expect(saida, isNot(contains('Ocorrência ID: $outro\n')));
      }

      expect(ocorrencias.listar(), hasLength(5));
    });

    // Garante que registros de um cidadão não apareçam para outro.
    test('registro de um cidadão não aparece para outro', () {
      final saida = executar([
        '3',
        '1',
        '1',
        '4',
        'Exclusivo da Ana',
        '4',
        '2',
        '0',
      ]);

      expect(saida, contains('sucesso! ID: 6'));
      expect(saida, isNot(contains('Descrição: Exclusivo da Ana')));
      expect(saida, isNot(contains('Ocorrência ID: 6\n')));
      expect(saida, contains('Ocorrência ID: 2\n'));
    });

    // Confirma a mensagem exibida quando não existem registros.
    test('cidadão sem ocorrências recebe uma mensagem informativa', () {
      final vazio = OcorrenciaService(
        usuarios: dados.usuarios,
        pontosColeta: dados.pontosColeta,
        ocorrencias: [],
      );

      final saida = executar(['4', '1', '0'], registros: vazio);

      expect(
        saida,
        contains('Nenhuma ocorrência encontrada para este cidadão.'),
      );
    });

    // Mantém a consulta quando o nome do ponto não está disponível.
    test('consulta preserva registros sem nome do ponto disponível', () {
      final historico = OcorrenciaService(
        usuarios: dados.usuarios,
        pontosColeta: [],
        ocorrencias: [
          Ocorrencia(
            id: 90,
            usuarioId: 1,
            pontoColetaId: 999,
            tipo: TipoOcorrencia.outro,
            descricao: 'Histórico',
            status: StatusOcorrencia.resolvida,
            criadoEm: referencia,
            atualizadoEm: referencia,
          ),
        ],
      );

      final saida = executar(['4', '1', '0'], registros: historico);

      expect(saida, contains('Ponto: 999 - Nome indisponível'));
      expect(saida, contains('Status: RESOLVIDA'));
    });
  });

  group('Validação de usuários', () {
    // Verifica o retorno ao menu quando não existem cidadãos.
    test('ausência de cidadãos retorna ao menu', () {
      final vazio = OcorrenciaService(
        usuarios: [],
        pontosColeta: dados.pontosColeta,
        ocorrencias: [],
      );

      final saida = executar(['3', '4', '0'], registros: vazio);

      expect('Nenhum cidadão disponível'.allMatches(saida), hasLength(2));
      expect(vazio.listar(), isEmpty);
    });

    // Rejeita usuários inválidos nas opções de cadastro e consulta.
    for (final opcao in ['3', '4']) {
      for (final id in ['', ' ', 'abc', '0', '-1', '999', '5']) {
        test('opção $opcao rejeita cidadão "$id"', () {
          final saida = executar([opcao, id, '0']);

          expect(saida, contains('Operação cancelada.'));

          if (id == '5') {
            expect(saida, contains('Administradores não participam'));
          }

          expect(ocorrencias.listar(), orderedEquals(dados.ocorrencias));
          expect(saida, endsWith('Binova encerrada. Até logo!'));
        });
      }
    }
  });

  group('Validação de pontos de coleta', () {
    // Impede o cadastro em pontos inexistentes ou inativos.
    for (final id in ['', ' ', 'abc', '0', '-1', '999', '8']) {
      test('ponto inválido ou inativo "$id" cancela o cadastro', () {
        final saida = executar(['3', '1', id, '0']);

        expect(saida, contains('Operação cancelada.'));

        if (id == '8') {
          expect(saida, contains('inativo'));
        }

        expect(ocorrencias.listar(), orderedEquals(dados.ocorrencias));
      });
    }
  });

  group('Validação de tipos e descrições', () {
    // Rejeita tipos que não correspondem às opções disponíveis.
    for (final tipo in ['', ' ', 'abc', '0', '-1', '5', '1.5']) {
      test('tipo inválido "$tipo" não registra ocorrência', () {
        final saida = executar(['3', '1', '1', tipo, '0']);

        expect(saida, contains('Tipo de ocorrência inválido.'));
        expect(ocorrencias.listar(), orderedEquals(dados.ocorrencias));
      });
    }

    // Impede descrições vazias sem consumir o próximo ID.
    for (final descricao in ['', '   ']) {
      test('descrição inválida "$descricao" não consome ID', () {
        final saida = executar([
          '3',
          '1',
          '1',
          '1',
          descricao,
          '3',
          '1',
          '1',
          '1',
          'Válida',
          '0',
        ]);

        expect(saida, contains('A descrição não pode ficar vazia.'));
        expect(saida, contains('sucesso! ID: 6'));
        expect(ocorrencias.listar(), hasLength(6));
        expect(ocorrencias.buscarPorId(6)?.descricao, 'Válida');
      });
    }
  });

  group('Encerramento da entrada', () {
    final cadastro = ['3', '1', '1', '1'];

    // Verifica o encerramento durante cada etapa do cadastro.
    for (var etapa = 1; etapa <= cadastro.length; etapa++) {
      test('EOF na etapa $etapa encerra sem salvar', () {
        final saida = executar([...cadastro.take(etapa), null]);

        expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
        expect(ocorrencias.listar(), orderedEquals(dados.ocorrencias));
        expect('===== BINOVA ====='.allMatches(saida), hasLength(1));
      });
    }

    // Confirma o encerramento ao interromper uma consulta.
    test('EOF durante consulta encerra sem repetir entrada', () {
      final saida = executar(['4', null]);

      expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
      expect(ocorrencias.listar(), hasLength(5));
    });
  });
}
