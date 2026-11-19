import 'package:binova_mobile/console/binova_console.dart';
import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/models/leitura_sensor.dart';
import 'package:binova_mobile/services/ponto_coleta_service.dart';
import 'package:test/test.dart';

void main() {
  final referencia = DateTime.utc(2026, 11, 19, 12);
  late DadosMockados dados;
  late PontoColetaService service;

  // Prepara os dados e o serviço antes de cada teste.
  setUp(() {
    dados = DadosMockados.criar(referencia: referencia);
    service = PontoColetaService(
      pontosColeta: dados.pontosColeta,
      leituras: dados.leituras,
    );
  });

  // Simula a navegação e retorna as mensagens do console.
  String executar(
    List<String?> entradas, {
    PontoColetaService? consulta,
    DateTime Function()? agora,
  }) {
    var indice = 0;
    final saidas = <String>[];

    BinovaConsole(
      service: consulta ?? service,
      lerEntrada: () {
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

  // Conta quantas vezes o menu principal aparece.
  int quantidadeMenus(String saida) {
    return '===== BINOVA ====='.allMatches(saida).length;
  }

  group('Menu e navegação', () {
    // Verifica as opções, a apresentação e o encerramento do aplicativo.
    test('menu exibe opções, contexto simulado e encerra com zero', () {
      final saida = executar(['0']);

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

    // Confirma que opções inválidas não interrompem a navegação.
    test('opção inválida informa erro e mantém menu disponível', () {
      final saida = executar(['abc', '9', '0']);

      expect('Opção inválida'.allMatches(saida), hasLength(2));
      expect(quantidadeMenus(saida), 3);
    });

    // Verifica o tratamento de opções vazias.
    test('opção vazia ou com espaços recebe mensagem amigável', () {
      final saida = executar(['', '   ', '0']);

      expect('Nenhuma opção informada'.allMatches(saida), hasLength(2));
      expect(quantidadeMenus(saida), 3);
    });

    // Aceita opções e identificadores com espaços extras.
    test('espaços ao redor da opção e do ID são aceitos', () {
      final saida = executar([' 2 ', ' 3 ', ' 0 ']);

      expect(saida, contains('ID: 3\n'));
      expect(saida, contains('===== DETALHES DO PONTO ====='));
    });

    // Encerra corretamente quando a entrada termina no menu.
    test('EOF no menu encerra sem nova leitura nem repetição', () {
      final saida = executar([null]);

      expect(quantidadeMenus(saida), 1);
      expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
    });

    // Encerra quando a leitura termina durante a solicitação de ID.
    test('EOF na solicitação de ID encerra sem voltar ao menu', () {
      final saida = executar(['2', null]);

      expect(saida, contains('Informe o ID do ponto de coleta:'));
      expect(quantidadeMenus(saida), 1);
      expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
    });
  });

  group('Listagem de pontos de coleta', () {
    // Lista os sete pontos ativos e oculta o ponto inativo.
    test('opção 1 lista IDs e nomes dos sete ativos e omite inativo', () {
      final saida = executar(['1', '0']);

      expect(saida, contains('===== PONTOS DE COLETA ====='));

      for (final ponto in dados.pontosColeta.where((p) => p.ativo)) {
        expect(saida, contains('ID: ${ponto.id}\nNome: ${ponto.nome}\n'));
        expect(saida, contains('Localização: ${ponto.descricaoLocalizacao}'));
      }

      expect(saida, isNot(contains('ID: 8\n')));
      expect(saida, isNot(contains(dados.pontosColeta.last.nome)));
      expect(quantidadeMenus(saida), 2);
    });

    // Confere os níveis e as classificações apresentados na listagem.
    test(
      'listagem apresenta níveis e classificações fornecidas pelo serviço',
      () {
        final saida = executar(['1', '0']);

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

    // Informa quando não existem pontos cadastrados.
    test('lista vazia informa ausência e permite retornar ao menu', () {
      final consulta = PontoColetaService(pontosColeta: [], leituras: []);

      final saida = executar(['1', '0'], consulta: consulta);

      expect(saida, contains('Nenhum ponto de coleta ativo disponível.'));
      expect(quantidadeMenus(saida), 2);
    });

    // Impede a exibição de pontos quando todos estão inativos.
    test('fonte somente com inativos também apresenta listagem vazia', () {
      final consulta = PontoColetaService(
        pontosColeta: [dados.pontosColeta.last],
        leituras: dados.leituras,
      );

      final saida = executar(['1', '0'], consulta: consulta);

      expect(saida, contains('Nenhum ponto de coleta ativo disponível.'));
      expect(saida, isNot(contains('ID: 8\n')));
    });
  });

  group('Consulta de pontos de coleta', () {
    // Verifica os dados apresentados na consulta por ID.
    test(
      'consulta ID existente mostra capacidade, localização, data e nível',
      () {
        final saida = executar(['2', '3', '0']);

        expect(saida, contains('===== DETALHES DO PONTO ====='));
        expect(saida, contains('ID: 3\nNome: Mercado Vila Aurora'));
        expect(
          saida,
          contains(
            'Localização: ${dados.pontosColeta[2].descricaoLocalizacao}',
          ),
        );
        expect(saida, contains('Capacidade: 120 litros'));
        expect(saida, contains('Ativo: Sim'));
        expect(saida, contains('Última leitura: 19/11/2026 11:59:00 (UTC)'));
        expect(saida, contains('Nível de preenchimento: 92%'));
        expect(saida, contains('Classificação: PROXIMA_DO_LIMITE'));
        expect(quantidadeMenus(saida), 2);
      },
    );

    // Informa quando o identificador não corresponde a um ponto.
    test('consulta ID inexistente informa ausência sem encerrar', () {
      final saida = executar(['2', '999', '0']);

      expect(saida, contains('Ponto de coleta com ID 999 não encontrado.'));
      expect(quantidadeMenus(saida), 2);
    });

    // Rejeita identificadores vazios ou preenchidos apenas com espaços.
    for (final texto in ['', '   ']) {
      test('ID vazio "$texto" recebe mensagem específica', () {
        final saida = executar(['2', texto, '0']);

        expect(saida, contains('Nenhum ID informado.'));
        expect(quantidadeMenus(saida), 2);
      });
    }

    // Valida IDs não numéricos, negativos, decimais ou fora do limite.
    for (final texto in [
      'abc',
      '3.5',
      '0',
      '-1',
      '99999999999999999999999999999',
    ]) {
      test('ID inválido "$texto" não causa exceção nem encerra aplicação', () {
        final saida = executar(['2', texto, '0']);

        expect(
          saida,
          contains('ID inválido. Digite um número inteiro positivo.'),
        );
        expect(quantidadeMenus(saida), 2);
      });
    }

    // Permite consultar um ponto inativo diretamente pelo identificador.
    test('ponto inativo é acessível diretamente pelo ID', () {
      final saida = executar(['2', '8', '0']);

      expect(saida, contains('Nome: Biblioteca Sabiá'));
      expect(saida, contains('Capacidade: 240 litros'));
      expect(saida, contains('Ativo: Não'));
    });
  });

  group('Validação das leituras', () {
    // Exibe o histórico sem apresentar dados antigos como atuais.
    test(
      'detalhes históricos mostram data sem apresentar percentual como atual',
      () {
        final saida = executar(['2', '5', '0']);

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

    // Apresenta a ausência de leitura sem gerar uma data fictícia.
    test(
      'ausência de leitura é apresentada em detalhes sem data inventada',
      () {
        final saida = executar(['2', '6', '0']);

        expect(saida, contains('Última leitura: Não disponível'));
        expect(saida, contains('Nível de preenchimento: Indisponível'));
        expect(saida, contains('Classificação: SEM_DADOS_ATUALIZADOS'));
      },
    );

    // Impede a exibição de percentuais registrados em datas futuras.
    test(
      'leitura futura não tem percentual exibido na listagem nem nos detalhes',
      () {
        final consulta = PontoColetaService(
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
        );

        final saida = executar(['1', '2', '1', '0'], consulta: consulta);

        expect(saida, isNot(contains('99%')));
        expect(saida, contains('Nível: Indisponível'));
        expect(saida, contains('Nível de preenchimento: Indisponível'));
        expect(saida, contains('Última leitura: 19/11/2026 12:01:00 (UTC)'));
      },
    );

    // Atualiza a validade das leituras conforme o avanço do relógio.
    test(
      'relógio avança sem recriar mocks e usa uma referência por operação',
      () {
        var chamadas = 0;

        final saida = executar([
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
  });

  group('Integridade e encerramento', () {
    // Verifica a continuidade da aplicação após operações e entradas inválidas.
    test('várias operações e erros na mesma sessão terminam normalmente', () {
      final saida = executar(['1', '2', '3', 'erro', '2', '999', '1', '0']);

      expect('===== PONTOS DE COLETA ====='.allMatches(saida), hasLength(2));
      expect(saida, contains('===== DETALHES DO PONTO ====='));
      expect(saida, contains('Opção inválida'));
      expect(saida, contains('ID 999 não encontrado'));
      expect(quantidadeMenus(saida), 6);
      expect(saida, endsWith('Binova encerrada. Até logo!'));
    });

    // Confirma o encerramento quando a entrada termina após uma operação.
    test('EOF após uma operação também encerra normalmente', () {
      final saida = executar(['1', null]);

      expect(quantidadeMenus(saida), 2);
      expect(saida, endsWith('Entrada encerrada. Binova encerrada.'));
    });

    // Garante que as consultas não modifiquem os dados simulados.
    test('sessão de consultas preserva as coleções fornecidas', () {
      final idsPontos = dados.pontosColeta.map((p) => p.id).toList();
      final idsLeituras = dados.leituras.map((l) => l.id).toList();

      executar(['1', '2', '7', '0']);

      expect(dados.pontosColeta.map((p) => p.id), orderedEquals(idsPontos));
      expect(dados.leituras.map((l) => l.id), orderedEquals(idsLeituras));
    });
  });
}
