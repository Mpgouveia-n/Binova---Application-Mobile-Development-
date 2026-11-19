import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
import 'package:binova_mobile/models/usuario.dart';
import 'package:binova_mobile/services/ocorrencia_service.dart';
import 'package:test/test.dart';

void main() {
  final DateTime referencia = DateTime.utc(2026, 11, 19, 12);
  late DadosMockados dados;
  late OcorrenciaService service;

  setUp(() {
    dados = DadosMockados.criar(referencia: referencia);
    service = OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: dados.ocorrencias,
    );
  });

  Ocorrencia registrar({
    OcorrenciaService? consulta,
    int usuarioId = 1,
    int pontoId = 1,
    String descricao = 'Recipiente cheio',
    TipoOcorrencia tipo = TipoOcorrencia.lixeiraCheia,
  }) => (consulta ?? service).registrar(
    usuarioId: usuarioId,
    pontoColetaId: pontoId,
    tipo: tipo,
    descricao: descricao,
    referencia: referencia,
  );

  test('lista as cinco ocorrências iniciais e preserva seus atributos', () {
    expect(service.listar(), orderedEquals(dados.ocorrencias));
    expect(service.listar(), hasLength(5));
  });

  test('busca ocorrência existente e retorna null para IDs ausentes', () {
    expect(service.buscarPorId(3), same(dados.ocorrencias[2]));
    for (final int id in [-1, 0, 999]) {
      expect(service.buscarPorId(id), isNull);
    }
  });

  test('consulta do cidadão contém somente seus registros', () {
    expect(service.listarPorCidadao(1).map((e) => e.id), [1, 5]);
    expect(service.listarPorCidadao(2).map((e) => e.id), [2]);
  });

  test('cidadão sem registros recebe lista vazia', () {
    final OcorrenciaService vazio = OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: [],
    );
    expect(vazio.listarPorCidadao(1), isEmpty);
  });

  test(
    'cadastro válido normaliza texto, associa IDs, abre status e iguala datas',
    () {
      final Ocorrencia nova = registrar(
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
    },
  );

  test('ID usa maior valor, mesmo em coleção esparsa e fora de ordem', () {
    Ocorrencia inicial(int id) => Ocorrencia(
      id: id,
      pontoColetaId: 1,
      usuarioId: 1,
      tipo: TipoOcorrencia.outro,
      descricao: 'Inicial',
      status: StatusOcorrencia.aberta,
      criadoEm: referencia,
      atualizadoEm: referencia,
    );
    final OcorrenciaService esparso = OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: [inicial(8), inicial(1), inicial(3)],
    );
    expect(registrar(consulta: esparso).id, 9);
    expect(registrar(consulta: esparso).id, 10);
  });

  test('base vazia inicia IDs em 1', () {
    final OcorrenciaService vazio = OcorrenciaService(
      usuarios: dados.usuarios,
      pontosColeta: dados.pontosColeta,
      ocorrencias: [],
    );
    expect(registrar(consulta: vazio).id, 1);
  });

  test(
    'cadastros consecutivos têm IDs únicos e preservam registros iniciais',
    () {
      expect(registrar().id, 6);
      expect(registrar(usuarioId: 2).id, 7);
      expect(service.listar().map((e) => e.id).toSet(), hasLength(7));
      expect(service.listar().take(5), orderedEquals(dados.ocorrencias));
      expect(dados.ocorrencias, hasLength(5));
    },
  );

  for (final int id in [0, -1, 999, 5]) {
    test(
      'usuário $id inválido ou administrador não registra nem consome ID',
      () {
        expect(
          () => registrar(usuarioId: id),
          throwsA(isA<ValidacaoOcorrenciaException>()),
        );
        expect(service.listar(), orderedEquals(dados.ocorrencias));
        expect(registrar().id, 6);
      },
    );
    test('consulta de usuário $id inválido ou administrador é rejeitada', () {
      expect(
        () => service.listarPorCidadao(id),
        throwsA(isA<ValidacaoOcorrenciaException>()),
      );
      expect(service.listar(), hasLength(5));
    });
  }

  for (final int id in [0, -1, 999, 8]) {
    test('ponto $id inválido ou inativo não registra nem altera a base', () {
      expect(
        () => registrar(pontoId: id),
        throwsA(isA<ValidacaoOcorrenciaException>()),
      );
      expect(service.listar(), orderedEquals(dados.ocorrencias));
      expect(registrar().id, 6);
    });
  }

  for (final String texto in ['', '   ', '\n\t']) {
    test('descrição vazia "$texto" é rejeitada sem registro parcial', () {
      expect(
        () => registrar(descricao: texto),
        throwsA(isA<ValidacaoOcorrenciaException>()),
      );
      expect(service.listar(), orderedEquals(dados.ocorrencias));
      expect(registrar().id, 6);
    });
  }

  for (final TipoOcorrencia tipo in TipoOcorrencia.values) {
    test('registro aceita tipo tipado ${tipo.valorContrato}', () {
      expect(registrar(tipo: tipo).tipo, tipo);
    });
  }

  test('coleções consultadas não permitem modificações e são fotografias', () {
    final List<Ocorrencia> todas = service.listar();
    final List<Ocorrencia> minhas = service.listarPorCidadao(1);
    expect(() => todas.clear(), throwsUnsupportedError);
    expect(() => minhas.clear(), throwsUnsupportedError);
    expect(() => service.listarCidadaos().clear(), throwsUnsupportedError);
    registrar();
    expect(todas, hasLength(5));
    expect(minhas, hasLength(2));
    expect(service.listar(), hasLength(6));
  });

  test('serviço copia coleções de entrada e isola instâncias', () {
    final List<Usuario> usuarios = List.of(dados.usuarios);
    final List<PontoColeta> pontos = List.of(dados.pontosColeta);
    final List<Ocorrencia> ocorrencias = List.of(dados.ocorrencias);
    final OcorrenciaService copia = OcorrenciaService(
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

  test('seleção lista somente cidadãos e valida suas referências', () {
    expect(service.listarCidadaos().map((u) => u.id), [1, 2, 3, 4]);
    expect(service.validarCidadao(1), same(dados.usuarios.first));
    expect(service.validarPontoAtivo(1), same(dados.pontosColeta.first));
  });
}
