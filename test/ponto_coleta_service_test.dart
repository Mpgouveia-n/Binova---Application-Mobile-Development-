import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/models/classificacao_ponto_coleta.dart';
import 'package:binova_mobile/models/leitura_sensor.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
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

  LeituraSensor leitura({
    int id = 1,
    int pontoId = 1,
    double nivel = 25,
    DateTime? registradoEm,
  }) => LeituraSensor(
    id: id,
    pontoColetaId: pontoId,
    distanciaCm: 100 - nivel,
    nivelPercentual: nivel,
    registradoEm: registradoEm ?? referencia,
  );

  PontoColetaService comLeituras(List<LeituraSensor> leituras) =>
      PontoColetaService(pontosColeta: dados.pontosColeta, leituras: leituras);

  test('lista somente pontos ativos e mantém a ordem original', () {
    expect(service.listarAtivos().map((e) => e.id), [1, 2, 3, 4, 5, 6, 7]);
    expect(service.listarAtivos().every((e) => e.ativo), isTrue);
  });

  test('busca ponto existente, inclusive inativo', () {
    expect(service.buscarPorId(1), same(dados.pontosColeta.first));
    expect(service.buscarPorId(8)?.ativo, isFalse);
  });

  test('IDs inexistentes retornam null ou histórico vazio', () {
    for (final int id in [-1, 0, 999]) {
      expect(service.buscarPorId(id), isNull);
      expect(service.consultarLeituras(id), isEmpty);
      expect(service.obterLeituraMaisRecente(id), isNull);
      expect(service.classificarPonto(id, referencia: referencia), isNull);
      expect(service.consultarDetalhes(id, referencia: referencia), isNull);
    }
  });

  test('recupera somente leituras associadas ao ponto solicitado', () {
    expect(service.consultarLeituras(7).map((e) => e.id), [6, 7]);
    expect(service.consultarLeituras(6), isEmpty);
  });

  test('seleciona a maior data em diferentes ordens sem ordenar a origem', () {
    final LeituraSensor antiga = leitura(
      id: 1,
      registradoEm: referencia.subtract(const Duration(minutes: 20)),
    );
    final LeituraSensor intermediaria = leitura(
      id: 2,
      registradoEm: referencia.subtract(const Duration(minutes: 5)),
    );
    final LeituraSensor recente = leitura(id: 3, nivel: 85);
    for (final List<LeituraSensor> ordem in [
      [recente, antiga, intermediaria],
      [intermediaria, recente, antiga],
      [antiga, intermediaria, recente],
    ]) {
      final List<LeituraSensor> copia = List.of(ordem);
      final PontoColetaService consulta = comLeituras(ordem);
      expect(consulta.obterLeituraMaisRecente(1), same(recente));
      expect(
        consulta.classificarPonto(1, referencia: referencia),
        ClassificacaoPontoColeta.proximaDoLimite,
      );
      expect(ordem, orderedEquals(copia));
    }
  });

  test('empate de data mantém a primeira leitura, conforme contrato', () {
    final LeituraSensor primeira = leitura(id: 2);
    expect(
      comLeituras([primeira, leitura(id: 1)]).obterLeituraMaisRecente(1),
      same(primeira),
    );
  });

  for (final (double percentual, ClassificacaoPontoColeta classificacao) in [
    (0.0, ClassificacaoPontoColeta.disponivel),
    (49.0, ClassificacaoPontoColeta.disponivel),
    (49.99, ClassificacaoPontoColeta.disponivel),
    (50.0, ClassificacaoPontoColeta.atencao),
    (79.0, ClassificacaoPontoColeta.atencao),
    (79.99, ClassificacaoPontoColeta.atencao),
    (80.0, ClassificacaoPontoColeta.proximaDoLimite),
    (100.0, ClassificacaoPontoColeta.proximaDoLimite),
  ]) {
    test('classifica $percentual% com leitura no instante de referência', () {
      final PontoColetaService consulta = comLeituras([
        leitura(nivel: percentual),
      ]);
      expect(
        consulta.classificarPonto(1, referencia: referencia),
        classificacao,
      );
    });
  }

  test('ausência de leitura resulta em sem dados atualizados', () {
    expect(
      service.classificarPonto(6, referencia: referencia),
      ClassificacaoPontoColeta.semDadosAtualizados,
    );
    expect(service.obterLeituraMaisRecente(6), isNull);
  });

  test('histórico obsoleto não determina a classificação atual', () {
    expect(
      service.classificarPonto(5, referencia: referencia),
      ClassificacaoPontoColeta.semDadosAtualizados,
    );
    expect(service.obterLeituraMaisRecente(5), isNotNull);
  });

  test('leitura com exatamente 15 minutos é válida', () {
    expect(
      service.classificarPonto(4, referencia: referencia),
      ClassificacaoPontoColeta.proximaDoLimite,
    );
  });

  test('um microssegundo além de 15 minutos é obsoleto', () {
    final PontoColetaService consulta = comLeituras([
      leitura(
        registradoEm: referencia.subtract(
          const Duration(minutes: 15, microseconds: 1),
        ),
      ),
    ]);
    expect(
      consulta.classificarPonto(1, referencia: referencia),
      ClassificacaoPontoColeta.semDadosAtualizados,
    );
  });

  test('leitura futura é inválida mesmo por um microssegundo', () {
    final PontoColetaService consulta = comLeituras([
      leitura(registradoEm: referencia.add(const Duration(microseconds: 1))),
    ]);
    expect(
      consulta.classificarPonto(1, referencia: referencia),
      ClassificacaoPontoColeta.semDadosAtualizados,
    );
  });

  test('mais recente futura não é substituída por leitura passada recente', () {
    final LeituraSensor futura = leitura(
      id: 2,
      registradoEm: referencia.add(const Duration(minutes: 1)),
    );
    final PontoColetaService consulta = comLeituras([leitura(), futura]);
    expect(consulta.obterLeituraMaisRecente(1), same(futura));
    expect(
      consulta.classificarPonto(1, referencia: referencia),
      ClassificacaoPontoColeta.semDadosAtualizados,
    );
  });

  test('mais recente obsoleta não é substituída por histórico mais antigo', () {
    final LeituraSensor obsoleta = leitura(
      id: 2,
      nivel: 90,
      registradoEm: referencia.subtract(const Duration(minutes: 16)),
    );
    final PontoColetaService consulta = comLeituras([
      obsoleta,
      leitura(registradoEm: referencia.subtract(const Duration(hours: 1))),
    ]);
    expect(consulta.obterLeituraMaisRecente(1), same(obsoleta));
    expect(
      consulta.classificarPonto(1, referencia: referencia),
      ClassificacaoPontoColeta.semDadosAtualizados,
    );
  });

  test('tempo avança por parâmetro e leitura deixa de ser recente', () {
    final PontoColetaService consulta = comLeituras([leitura(nivel: 65)]);
    expect(
      consulta.classificarPonto(1, referencia: referencia),
      ClassificacaoPontoColeta.atencao,
    );
    expect(
      consulta.classificarPonto(
        1,
        referencia: referencia.add(const Duration(minutes: 16)),
      ),
      ClassificacaoPontoColeta.semDadosAtualizados,
    );
  });

  test('detalhes reúnem ponto, histórico, última leitura e classificação', () {
    final DetalhesPontoColeta detalhes = service.consultarDetalhes(
      7,
      referencia: referencia,
    )!;
    expect(detalhes.ponto.id, 7);
    expect(detalhes.leituras.map((e) => e.id), [6, 7]);
    expect(detalhes.leituraMaisRecente?.id, 6);
    expect(detalhes.classificacao, ClassificacaoPontoColeta.proximaDoLimite);
    expect(
      service.consultarDetalhes(6, referencia: referencia)?.leituraMaisRecente,
      isNull,
    );
  });

  test('mocks produzem todos os estados e inativo não aparece na listagem', () {
    expect(
      dados.pontosColeta.map(
        (p) => service.classificarPonto(p.id, referencia: referencia),
      ),
      [
        ClassificacaoPontoColeta.disponivel,
        ClassificacaoPontoColeta.atencao,
        ClassificacaoPontoColeta.proximaDoLimite,
        ClassificacaoPontoColeta.proximaDoLimite,
        ClassificacaoPontoColeta.semDadosAtualizados,
        ClassificacaoPontoColeta.semDadosAtualizados,
        ClassificacaoPontoColeta.proximaDoLimite,
        ClassificacaoPontoColeta.disponivel,
      ],
    );
    expect(service.listarAtivos().any((p) => p.id == 8), isFalse);
  });

  test('consultas não alteram entradas e resultados são protegidos', () {
    final List<PontoColeta> pontos = List.of(dados.pontosColeta);
    final List<LeituraSensor> leituras = List.of(dados.leituras);
    final PontoColetaService consulta = PontoColetaService(
      pontosColeta: pontos,
      leituras: leituras,
    );
    consulta.obterLeituraMaisRecente(7);
    consulta.consultarDetalhes(7, referencia: referencia);
    expect(pontos, orderedEquals(dados.pontosColeta));
    expect(leituras, orderedEquals(dados.leituras));
    expect(() => consulta.listarAtivos().clear(), throwsUnsupportedError);
    expect(() => consulta.consultarLeituras(7).clear(), throwsUnsupportedError);
    expect(
      () => consulta
          .consultarDetalhes(7, referencia: referencia)!
          .leituras
          .clear(),
      throwsUnsupportedError,
    );
    pontos.clear();
    leituras.clear();
    expect(consulta.listarAtivos(), hasLength(7));
    expect(consulta.consultarLeituras(7), hasLength(2));
  });

  test('fonte vazia funciona e não gera resultados inexistentes', () {
    final PontoColetaService vazio = PontoColetaService(
      pontosColeta: [],
      leituras: [],
    );
    expect(vazio.listarAtivos(), isEmpty);
    expect(vazio.buscarPorId(1), isNull);
    expect(vazio.consultarDetalhes(1, referencia: referencia), isNull);
  });

  test('enum mapeia o contrato sem modificar enums existentes', () {
    expect(ClassificacaoPontoColeta.values.map((e) => e.valorContrato), [
      'DISPONIVEL',
      'ATENCAO',
      'PROXIMA_DO_LIMITE',
      'SEM_DADOS_ATUALIZADOS',
    ]);
  });
}
