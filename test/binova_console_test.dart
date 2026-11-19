import 'package:binova_mobile/console/binova_console.dart';
import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/models/leitura_sensor.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';
import 'package:test/test.dart';

void main() {
  final DateTime referencia = DateTime.utc(2026, 11, 19, 12);
  late DadosMockados dados;
  late PontoColetaService service;

  setUp(() {
    dados = DadosMockados.criar(referencia: referencia);
    service = PontoColetaService(
      pontosColeta: dados.pontosColeta,
      leituras: dados.leituras,
    );
  });

  String executar(
    List<String?> entradas, {
    PontoColetaService? consulta,
    DateTime Function()? agora,
  }) {
    int indice = 0;
    final List<String> saidas = [];
    BinovaConsole(
      service: consulta ?? service,
      lerEntrada: () {
        // Detecta repetição indevida de leitura após EOF sem travar o teste.
        if (indice >= entradas.length) {
          throw StateError('Console leu além das entradas fornecidas.');
        }
        return entradas[indice++];
      },
      escrever: saidas.add,
      agora: agora ?? () => referencia,
    ).executar();
    expect(indice, entradas.length);
    return saidas.join('\n');
  }

  int quantidadeMenus(String saida) =>
      '===== BINOVA ====='.allMatches(saida).length;

  test('menu exibe opções, contexto simulado e encerra com zero', () {
    final String saida = executar(['0']);
    expect(saida, contains('===== BINOVA ====='));
    expect(saida, contains('Monitoramento inteligente de resíduos'));
    expect(saida, contains('1 - Listar pontos de coleta'));
    expect(saida, contains('2 - Consultar ponto por ID'));
    expect(saida, contains('0 - Sair'));
    expect(saida, contains('Simulação acadêmica'));
    expect(saida, contains('sem sensores físicos'));
    expect(saida, endsWith('Binova encerrada. Até logo!'));
    expect(quantidadeMenus(saida), 1);
  });

  test('opção inválida informa erro e mantém menu disponível', () {
    final String saida = executar(['abc', '9', '0']);
    expect('Opção inválida'.allMatches(saida), hasLength(2));
    expect(quantidadeMenus(saida), 3);
  });

  test('opção vazia ou com espaços recebe mensagem amigável', () {
    final String saida = executar(['', '   ', '0']);
    expect('Nenhuma opção informada'.allMatches(saida), hasLength(2));
    expect(quantidadeMenus(saida), 3);
  });

  test('espaços ao redor da opção e do ID são aceitos', () {
    final String saida = executar([' 2 ', ' 3 ', ' 0 ']);
    expect(saida, contains('ID: 3\n'));
    expect(saida, contains('===== DETALHES DO PONTO ====='));
  });

  test('EOF no menu encerra sem nova leitura nem repetição', () {
    final String saida = executar([null]);
    expect(quantidadeMenus(saida), 1);
    expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
  });

  test('EOF na solicitação de ID encerra sem voltar ao menu', () {
    final String saida = executar(['2', null]);
    expect(saida, contains('Informe o ID do ponto de coleta:'));
    expect(quantidadeMenus(saida), 1);
    expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
  });

  test('opção 1 lista IDs e nomes dos sete ativos e omite inativo', () {
    final String saida = executar(['1', '0']);
    expect(saida, contains('===== PONTOS DE COLETA ====='));
    for (final ponto in dados.pontosColeta.where((p) => p.ativo)) {
      expect(saida, contains('ID: ${ponto.id}\nNome: ${ponto.nome}\n'));
      expect(saida, contains('Localização: ${ponto.descricaoLocalizacao}'));
    }
    expect(saida, isNot(contains('ID: 8\n')));
    expect(saida, isNot(contains(dados.pontosColeta.last.nome)));
    expect(quantidadeMenus(saida), 2);
  });

  test(
    'listagem apresenta níveis e classificações fornecidas pelo serviço',
    () {
      final String saida = executar(['1', '0']);
      expect(saida, contains('Nível: 25%\nSituação: DISPONIVEL'));
      expect(saida, contains('Nível: 65%\nSituação: ATENCAO'));
      expect(saida, contains('Nível: 92%\nSituação: PROXIMA_DO_LIMITE'));
      expect(saida, contains('Nível: 85%\nSituação: PROXIMA_DO_LIMITE'));
      expect(
        'Nível: Indisponível\nSituação: SEM_DADOS_ATUALIZADOS'.allMatches(
          saida,
        ),
        hasLength(2),
      );
      expect(saida, isNot(contains('Nível: 40%')));
      expect(saida, isNot(contains('Nível: 20%')));
    },
  );

  test('lista vazia informa ausência e permite retornar ao menu', () {
    final String saida = executar([
      '1',
      '0',
    ], consulta: PontoColetaService(pontosColeta: [], leituras: []));
    expect(saida, contains('Nenhum ponto de coleta ativo disponível.'));
    expect(quantidadeMenus(saida), 2);
  });

  test('fonte somente com inativos também apresenta listagem vazia', () {
    final String saida = executar(
      ['1', '0'],
      consulta: PontoColetaService(
        pontosColeta: [dados.pontosColeta.last],
        leituras: dados.leituras,
      ),
    );
    expect(saida, contains('Nenhum ponto de coleta ativo disponível.'));
    expect(saida, isNot(contains('ID: 8\n')));
  });

  test(
    'consulta ID existente mostra capacidade, localização, data e nível',
    () {
      final String saida = executar(['2', '3', '0']);
      expect(saida, contains('===== DETALHES DO PONTO ====='));
      expect(saida, contains('ID: 3\nNome: Mercado Vila Aurora'));
      expect(
        saida,
        contains('Localização: ${dados.pontosColeta[2].descricaoLocalizacao}'),
      );
      expect(saida, contains('Capacidade: 120 litros'));
      expect(saida, contains('Ativo: Sim'));
      expect(saida, contains('Última leitura: 19/11/2026 11:59:00 (UTC)'));
      expect(saida, contains('Nível de preenchimento: 92%'));
      expect(saida, contains('Classificação: PROXIMA_DO_LIMITE'));
      expect(quantidadeMenus(saida), 2);
    },
  );

  test('consulta ID inexistente informa ausência sem encerrar', () {
    final String saida = executar(['2', '999', '0']);
    expect(saida, contains('Ponto de coleta com ID 999 não encontrado.'));
    expect(quantidadeMenus(saida), 2);
  });

  for (final String texto in ['', '   ']) {
    test('ID vazio "$texto" recebe mensagem específica', () {
      final String saida = executar(['2', texto, '0']);
      expect(saida, contains('Nenhum ID informado.'));
      expect(quantidadeMenus(saida), 2);
    });
  }

  for (final String texto in [
    'abc',
    '3.5',
    '0',
    '-1',
    '99999999999999999999999999999',
  ]) {
    test('ID inválido "$texto" não causa exceção nem encerra aplicação', () {
      final String saida = executar(['2', texto, '0']);
      expect(
        saida,
        contains('ID inválido. Digite um número inteiro positivo.'),
      );
      expect(quantidadeMenus(saida), 2);
    });
  }

  test('ponto inativo é acessível diretamente pelo ID', () {
    final String saida = executar(['2', '8', '0']);
    expect(saida, contains('Nome: Biblioteca Sabiá'));
    expect(saida, contains('Capacidade: 240 litros'));
    expect(saida, contains('Ativo: Não'));
  });

  test(
    'detalhes históricos mostram data sem apresentar percentual como atual',
    () {
      final String saida = executar(['2', '5', '0']);
      expect(saida, contains('Última leitura: 19/11/2026 11:15:00 (UTC)'));
      expect(saida, contains('Nível de preenchimento: Indisponível'));
      expect(saida, contains('Classificação: SEM_DADOS_ATUALIZADOS'));
      expect(
        saida,
        contains('O registro exibido não é válido para o estado atual.'),
      );
      expect(saida, isNot(contains('40%')));
    },
  );

  test('ausência de leitura é apresentada em detalhes sem data inventada', () {
    final String saida = executar(['2', '6', '0']);
    expect(saida, contains('Última leitura: Não disponível'));
    expect(saida, contains('Nível de preenchimento: Indisponível'));
    expect(saida, contains('Classificação: SEM_DADOS_ATUALIZADOS'));
  });

  test(
    'leitura futura não tem percentual exibido na listagem nem nos detalhes',
    () {
      final String saida = executar(
        ['1', '2', '1', '0'],
        consulta: PontoColetaService(
          pontosColeta: dados.pontosColeta,
          leituras: [
            LeituraSensor(
              id: 1,
              pontoColetaId: 1,
              distanciaCm: 1,
              nivelPercentual: 99,
              registradoEm: referencia.add(const Duration(minutes: 1)),
            ),
          ],
        ),
      );
      expect(saida, isNot(contains('99%')));
      expect(saida, contains('Nível: Indisponível'));
      expect(saida, contains('Nível de preenchimento: Indisponível'));
      expect(saida, contains('Última leitura: 19/11/2026 12:01:00 (UTC)'));
    },
  );

  test('várias operações e erros na mesma sessão terminam normalmente', () {
    final String saida = executar([
      '1',
      '2',
      '3',
      'erro',
      '2',
      '999',
      '1',
      '0',
    ]);
    expect('===== PONTOS DE COLETA ====='.allMatches(saida), hasLength(2));
    expect(saida, contains('===== DETALHES DO PONTO ====='));
    expect(saida, contains('Opção inválida'));
    expect(saida, contains('ID 999 não encontrado'));
    expect(quantidadeMenus(saida), 6);
    expect(saida, endsWith('Binova encerrada. Até logo!'));
  });

  test('EOF após uma operação também encerra normalmente', () {
    final String saida = executar(['1', null]);
    expect(quantidadeMenus(saida), 2);
    expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
  });

  test(
    'relógio avança sem recriar mocks e usa uma referência por operação',
    () {
      int chamadas = 0;
      final String saida = executar([
        '1',
        '2',
        '1',
        '0',
      ], agora: () => referencia.add(Duration(minutes: chamadas++ * 20)));
      expect(chamadas, 2);
      expect(saida, contains('Nível: 25%\nSituação: DISPONIVEL'));
      expect(saida, contains('Nível de preenchimento: Indisponível'));
      expect(saida, contains('Última leitura: 19/11/2026 11:57:00 (UTC)'));
    },
  );

  test('sessão de consultas preserva as coleções fornecidas', () {
    final List<int> idsPontos = dados.pontosColeta.map((p) => p.id).toList();
    final List<int> idsLeituras = dados.leituras.map((l) => l.id).toList();
    executar(['1', '2', '7', '0']);
    expect(dados.pontosColeta.map((p) => p.id), orderedEquals(idsPontos));
    expect(dados.leituras.map((l) => l.id), orderedEquals(idsLeituras));
  });
}
