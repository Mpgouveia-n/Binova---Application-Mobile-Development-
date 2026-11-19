import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
import 'package:binova_mobile/models/usuario.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:test/test.dart';

void main() {
  final referencia = DateTime.utc(2026, 11, 19, 12);
  late DadosMockados dados;
  late OcorrenciaService service;

  // Prepara os dados e o serviço antes de cada teste.
  setUp(() {
    dados = DadosMockados.criar(referencia: referencia);

    service = OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: dados.ocorrencias,
    );
  });

  // Registra uma ocorrência utilizando os parâmetros informados.
  Ocorrencia registrar({
    OcorrenciaService? consulta,
    int usuarioId = 1,
    int pontoId = 1,
    String descricao = 'Recipiente cheio',
    TipoOcorrencia tipo = TipoOcorrencia.lixeiraCheia,
  }) {
    return (consulta ?? service).registrar(
      usuarioId: usuarioId,
      pontoColetaId: pontoId,
      tipo: tipo,
      descricao: descricao,
      referencia: referencia,
    );
  }

  group('Consulta de ocorrências', () {
    // Verifica a listagem e a preservação das ocorrências iniciais.
    test('lista as cinco ocorrências iniciais', () {
      expect(service.listar(), orderedEquals(dados.ocorrencias));
      expect(service.listar(), hasLength(5));
    });

    // Busca uma ocorrência pelo ID e verifica IDs inexistentes.
    test('busca ocorrência existente e retorna null para IDs ausentes', () {
      expect(service.buscarPorId(3), same(dados.ocorrencias[2]));

      for (final id in [-1, 0, 999]) {
        expect(service.buscarPorId(id), isNull);
      }
    });

    // Confirma que cada cidadão consulta apenas seus registros.
    test('consulta somente os registros do cidadão', () {
      expect(service.listarPorCidadao(1).map((e) => e.id), [1, 5]);
      expect(service.listarPorCidadao(2).map((e) => e.id), [2]);
    });

    // Verifica o retorno quando não existem ocorrências cadastradas.
    test('cidadão sem registros recebe uma lista vazia', () {
      final vazio = OcorrenciaService(
        usuarios: dados.usuarios,
        pontosColeta: dados.pontosColeta,
        ocorrencias: [],
      );

      expect(vazio.listarPorCidadao(1), isEmpty);
    });
  });

  group('Cadastro de ocorrências', () {
    // Confere os dados, o status e as datas de uma ocorrência válida.
    test('cadastro válido normaliza os dados e inicia o status aberto', () {
      final nova = registrar(
        descricao: '  Tampa quebrada \n',
        tipo: TipoOcorrencia.estruturaDanificada,
      );

      expect(nova.id, 6);
      expect(nova.usuarioId, 1);
      expect(nova.pontoColetaId, 1);
      expect(nova.tipo, TipoOcorrencia.estruturaDanificada);
      expect(nova.descricao, 'Tampa quebrada');
      expect(nova.status, StatusOcorrencia.aberta);
      expect(nova.criadoEm, referencia);
      expect(nova.atualizadoEm, referencia);
      expect(service.buscarPorId(nova.id), same(nova));
      expect(service.listarPorCidadao(1), contains(nova));
      expect(service.listar(), hasLength(6));
    });

    // Valida IDs únicos e preservação dos registros anteriores.
    test('cadastros consecutivos possuem IDs únicos', () {
      expect(registrar().id, 6);
      expect(registrar(usuarioId: 2).id, 7);
      expect(service.listar().map((e) => e.id).toSet(), hasLength(7));
      expect(service.listar().take(5), orderedEquals(dados.ocorrencias));
      expect(dados.ocorrencias, hasLength(5));
    });

    // Verifica o cadastro com todos os tipos de ocorrência disponíveis.
    for (final tipo in TipoOcorrencia.values) {
      test('aceita o tipo ${tipo.valorContrato}', () {
        expect(registrar(tipo: tipo).tipo, tipo);
      });
    }
  });

  group('Geração de identificadores', () {
    // Confirma que o próximo ID considera o maior valor existente.
    test('utiliza o maior ID em uma coleção fora de ordem', () {
      // Cria uma ocorrência inicial com o ID informado.
      Ocorrencia inicial(int id) {
        return Ocorrencia(
          id: id,
          pontoColetaId: 1,
          usuarioId: 1,
          tipo: TipoOcorrencia.outro,
          descricao: 'Inicial',
          status: StatusOcorrencia.aberta,
          criadoEm: referencia,
          atualizadoEm: referencia,
        );
      }

      final esparso = OcorrenciaService(
        usuarios: dados.usuarios,
        pontosColeta: dados.pontosColeta,
        ocorrencias: [inicial(8), inicial(1), inicial(3)],
      );

      expect(registrar(consulta: esparso).id, 9);
      expect(registrar(consulta: esparso).id, 10);
    });

    // Verifica se a primeira ocorrência recebe o ID 1.
    test('base vazia inicia a numeração em 1', () {
      final vazio = OcorrenciaService(
        usuarios: dados.usuarios,
        pontosColeta: dados.pontosColeta,
        ocorrencias: [],
      );

      expect(registrar(consulta: vazio).id, 1);
    });
  });

  group('Validação de usuários', () {
    // Rejeita cadastros de usuários inexistentes ou administradores.
    for (final id in [0, -1, 999, 5]) {
      test('usuário $id inválido ou administrador não registra', () {
        expect(
          () => registrar(usuarioId: id),
          throwsA(isA<ValidacaoOcorrenciaException>()),
        );

        expect(service.listar(), orderedEquals(dados.ocorrencias));
        expect(registrar().id, 6);
      });

      // Impede consultas de usuários inválidos ou administradores.
      test('consulta de usuário $id inválido é rejeitada', () {
        expect(
          () => service.listarPorCidadao(id),
          throwsA(isA<ValidacaoOcorrenciaException>()),
        );

        expect(service.listar(), hasLength(5));
      });
    }

    // Verifica a listagem de cidadãos e as referências válidas.
    test('lista somente cidadãos e valida referências', () {
      expect(service.listarCidadaos().map((u) => u.id), [1, 2, 3, 4]);
      expect(service.validarCidadao(1), same(dados.usuarios.first));
      expect(service.validarPontoAtivo(1), same(dados.pontosColeta.first));
    });
  });

  group('Validação de pontos de coleta', () {
    // Impede registros em pontos inexistentes ou inativos.
    for (final id in [0, -1, 999, 8]) {
      test('ponto $id inválido ou inativo não altera a base', () {
        expect(
          () => registrar(pontoId: id),
          throwsA(isA<ValidacaoOcorrenciaException>()),
        );

        expect(service.listar(), orderedEquals(dados.ocorrencias));
        expect(registrar().id, 6);
      });
    }
  });

  group('Validação de descrições', () {
    // Rejeita descrições vazias ou compostas apenas por espaços.
    for (final texto in ['', '   ', '\n\t']) {
      test('descrição vazia "$texto" não gera registro parcial', () {
        expect(
          () => registrar(descricao: texto),
          throwsA(isA<ValidacaoOcorrenciaException>()),
        );

        expect(service.listar(), orderedEquals(dados.ocorrencias));
        expect(registrar().id, 6);
      });
    }
  });

  group('Integridade dos dados', () {
    // Verifica se as consultas retornam listas protegidas e independentes.
    test('consultas retornam listas protegidas e independentes', () {
      final todas = service.listar();
      final minhas = service.listarPorCidadao(1);

      expect(() => todas.clear(), throwsUnsupportedError);
      expect(() => minhas.clear(), throwsUnsupportedError);
      expect(() => service.listarCidadaos().clear(), throwsUnsupportedError);

      registrar();

      expect(todas, hasLength(5));
      expect(minhas, hasLength(2));
      expect(service.listar(), hasLength(6));
    });

    // Confirma que alterações nas listas externas não afetam o serviço.
    test('serviço copia as coleções recebidas', () {
      final usuarios = List<Usuario>.of(dados.usuarios);
      final pontos = List<PontoColeta>.of(dados.pontosColeta);
      final ocorrencias = List<Ocorrencia>.of(dados.ocorrencias);

      final copia = OcorrenciaService(
        usuarios: usuarios,
        pontosColeta: pontos,
        ocorrencias: ocorrencias,
      );

      usuarios.clear();
      pontos.clear();
      ocorrencias.clear();

      expect(registrar(consulta: copia).id, 6);
      expect(service.listar(), hasLength(5));
      expect(copia.listar(), hasLength(6));
    });
  });
}
