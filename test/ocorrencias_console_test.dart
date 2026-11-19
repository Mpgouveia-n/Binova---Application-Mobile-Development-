import 'package:binova_mobile/console/binova_console.dart';
import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';
import 'package:test/test.dart';

void main() {
  final DateTime referencia = DateTime.utc(2026, 11, 19, 12);
  late DadosMockados dados;
  late OcorrenciaService ocorrencias;
  late PontoColetaService pontos;

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

  String executar(List<String?> entradas, {OcorrenciaService? registros}) {
    int indice = 0;
    final List<String> saidas = [];
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

  test(
    'menu inclui registro e consulta e seleção é declaradamente simulada',
    () {
      final String saida = executar(['4', '1', '0']);
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
    },
  );

  test(
    'cadastro completo confirma ID 6 e consulta na mesma sessão o encontra',
    () {
      final String saida = executar([
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
    },
  );

  test('consulta inclui mocks do cidadão e exclui os dos demais', () {
    final String saida = executar(['4', '2', '0']);
    expect(saida, contains('Ocorrência ID: 2\n'));
    expect(saida, contains('Tipo: DESCARTE_IRREGULAR'));
    expect(saida, contains('Status: EM_ATENDIMENTO'));
    for (final int outro in [1, 3, 4, 5]) {
      expect(saida, isNot(contains('Ocorrência ID: $outro\n')));
    }
    expect(ocorrencias.listar(), hasLength(5));
  });

  test('registro de um cidadão não aparece na consulta de outro', () {
    final String saida = executar([
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

  test('cidadão sem ocorrências recebe mensagem amigável', () {
    final OcorrenciaService vazio = OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: [],
    );
    final String saida = executar(['4', '1', '0'], registros: vazio);
    expect(saida, contains('Nenhuma ocorrência encontrada para este cidadão.'));
  });

  test('sem cidadãos disponíveis retorna ao menu sem solicitar ID', () {
    final OcorrenciaService vazio = OcorrenciaService(
      usuarios: [],
      pontosColeta: dados.pontosColeta,
      ocorrencias: [],
    );
    final String saida = executar(['3', '4', '0'], registros: vazio);
    expect('Nenhum cidadão disponível'.allMatches(saida), hasLength(2));
    expect(vazio.listar(), isEmpty);
  });

  for (final String opcao in ['3', '4']) {
    for (final String id in ['', ' ', 'abc', '0', '-1', '999', '5']) {
      test('opção $opcao rejeita cidadão "$id" sem alterar ocorrências', () {
        final String saida = executar([opcao, id, '0']);
        expect(saida, contains('Operação cancelada.'));
        if (id == '5') {
          expect(saida, contains('Administradores não participam'));
        }
        expect(ocorrencias.listar(), orderedEquals(dados.ocorrencias));
        expect(saida, endsWith('Binova encerrada. Até logo!'));
      });
    }
  }

  for (final String id in ['', ' ', 'abc', '0', '-1', '999', '8']) {
    test('ponto inválido ou inativo "$id" cancela sem registro parcial', () {
      final String saida = executar(['3', '1', id, '0']);
      expect(saida, contains('Operação cancelada.'));
      if (id == '8') expect(saida, contains('inativo'));
      expect(ocorrencias.listar(), orderedEquals(dados.ocorrencias));
    });
  }

  for (final String tipo in ['', ' ', 'abc', '0', '-1', '5', '1.5']) {
    test('tipo inválido "$tipo" cancela sem registrar', () {
      final String saida = executar(['3', '1', '1', tipo, '0']);
      expect(saida, contains('Tipo de ocorrência inválido.'));
      expect(ocorrencias.listar(), orderedEquals(dados.ocorrencias));
    });
  }

  for (final String descricao in ['', '   ']) {
    test('descrição inválida "$descricao" não altera base nem consome ID', () {
      final String saida = executar([
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

  final Map<String, TipoOcorrencia> mapeamento = {
    '1': TipoOcorrencia.lixeiraCheia,
    '2': TipoOcorrencia.descarteIrregular,
    '3': TipoOcorrencia.estruturaDanificada,
    '4': TipoOcorrencia.outro,
  };
  for (final MapEntry<String, TipoOcorrencia> opcao in mapeamento.entries) {
    test('seleção ${opcao.key} registra ${opcao.value.valorContrato}', () {
      executar(['3', '1', '1', opcao.key, 'Relato', '0']);
      expect(ocorrencias.buscarPorId(6)?.tipo, opcao.value);
    });
  }

  final List<String> cadastro = ['3', '1', '1', '1'];
  for (int etapa = 1; etapa <= cadastro.length; etapa++) {
    test('EOF na etapa $etapa do cadastro encerra sem salvar', () {
      final String saida = executar([...cadastro.take(etapa), null]);
      expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
      expect(ocorrencias.listar(), orderedEquals(dados.ocorrencias));
      expect('===== BINOVA ====='.allMatches(saida), hasLength(1));
    });
  }

  test('EOF durante consulta encerra sem repetir entrada', () {
    final String saida = executar(['4', null]);
    expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
    expect(ocorrencias.listar(), hasLength(5));
  });

  test('cadastros consecutivos e navegação de pontos coexistem na sessão', () {
    final String saida = executar([
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

  test('consulta preserva ocorrência mesmo se nome do ponto não estiver disponível', () {
    final OcorrenciaService historico = OcorrenciaService(
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
    final String saida = executar(['4', '1', '0'], registros: historico);
    expect(saida, contains('Ponto: 999 - Nome indisponível'));
    expect(saida, contains('Status: RESOLVIDA'));
  });
}
