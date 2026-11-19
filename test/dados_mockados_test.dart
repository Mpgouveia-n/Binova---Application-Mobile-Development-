import 'package:binova_mobile/data/dados_mockados.dart';
import 'package:binova_mobile/models/enums.dart';
import 'package:test/test.dart';

void main() {
  final referencia = DateTime.utc(2026, 11, 19, 12);
  late DadosMockados dados;

  // Prepara os dados simulados antes de cada teste.
  setUp(() {
    dados = DadosMockados.criar(referencia: referencia);
  });

  // Confere as quantidades e a unicidade dos identificadores.
  test('quantidades de registros e IDs positivos e únicos por entidade', () {
    expect(dados.usuarios, hasLength(5));
    expect(dados.pontosColeta, hasLength(8));
    expect(dados.leituras, hasLength(8));
    expect(dados.ocorrencias, hasLength(5));

    for (final ids in [
      dados.usuarios.map((e) => e.id),
      dados.pontosColeta.map((e) => e.id),
      dados.leituras.map((e) => e.id),
      dados.ocorrencias.map((e) => e.id),
    ]) {
      expect(ids, everyElement(isPositive));
      expect(ids.toSet(), hasLength(ids.length));
    }
  });

  // Valida os relacionamentos entre usuários, pontos e ocorrências.
  test('relacionamentos referenciam pontos e cidadãos existentes', () {
    final pontos = dados.pontosColeta.map((e) => e.id).toSet();

    final cidadaos = dados.usuarios
        .where((e) => e.papel == PapelUsuario.cidadao)
        .map((e) => e.id)
        .toSet();

    for (final leitura in dados.leituras) {
      expect(pontos, contains(leitura.pontoColetaId));
    }

    for (final ocorrencia in dados.ocorrencias) {
      expect(pontos, contains(ocorrencia.pontoColetaId));
      expect(cidadaos, contains(ocorrencia.usuarioId));
    }
  });

  // Verifica campos obrigatórios, medidas e consistência das datas.
  test('campos obrigatórios, medidas e datas são coerentes', () {
    for (final usuario in dados.usuarios) {
      expect(usuario.nome.trim(), isNotEmpty);
      expect(usuario.email, endsWith('@example.com'));
      expect(usuario.senhaHash, startsWith('hash-simulado-'));
      expect(usuario.criadoEm.isAfter(referencia), isFalse);
    }

    for (final ponto in dados.pontosColeta) {
      expect(ponto.nome.trim(), isNotEmpty);
      expect(ponto.descricaoLocalizacao.trim(), isNotEmpty);
      expect(ponto.capacidadeLitros.isFinite, isTrue);
      expect(ponto.capacidadeLitros, isPositive);
      expect(ponto.criadoEm.isAfter(referencia), isFalse);
    }

    for (final leitura in dados.leituras) {
      expect(leitura.distanciaCm.isFinite, isTrue);
      expect(leitura.distanciaCm, greaterThanOrEqualTo(0));
      expect(leitura.nivelPercentual.isFinite, isTrue);
      expect(leitura.nivelPercentual, inInclusiveRange(0, 100));
      expect(leitura.registradoEm.isAfter(referencia), isFalse);

      final ponto = dados.pontosColeta.singleWhere(
        (e) => e.id == leitura.pontoColetaId,
      );

      expect(leitura.registradoEm.isBefore(ponto.criadoEm), isFalse);
    }

    for (final ocorrencia in dados.ocorrencias) {
      expect(ocorrencia.descricao.trim(), isNotEmpty);
      expect(ocorrencia.atualizadoEm.isBefore(ocorrencia.criadoEm), isFalse);
      expect(ocorrencia.atualizadoEm.isAfter(referencia), isFalse);

      final usuario = dados.usuarios.singleWhere(
        (e) => e.id == ocorrencia.usuarioId,
      );

      final ponto = dados.pontosColeta.singleWhere(
        (e) => e.id == ocorrencia.pontoColetaId,
      );

      expect(ocorrencia.criadoEm.isBefore(usuario.criadoEm), isFalse);
      expect(ocorrencia.criadoEm.isBefore(ponto.criadoEm), isFalse);
    }
  });

  // Confirma os diferentes cenários de coleta presentes nos mocks.
  test(
    'cenário oferece ativos, inativo, histórico, ausência e múltiplas leituras',
    () {
      expect(dados.pontosColeta.where((e) => e.ativo), hasLength(7));
      expect(dados.pontosColeta.where((e) => !e.ativo), hasLength(1));
      expect(dados.leituras.where((e) => e.pontoColetaId == 6), isEmpty);
      expect(dados.leituras.where((e) => e.pontoColetaId == 7), hasLength(2));

      final historica = dados.leituras.singleWhere((e) => e.pontoColetaId == 5);

      expect(referencia.difference(historica.registradoEm).inMinutes, 45);
      expect(dados.leituras.any((e) => e.nivelPercentual < 50), isTrue);

      expect(
        dados.leituras.any(
          (e) => e.nivelPercentual >= 50 && e.nivelPercentual < 80,
        ),
        isTrue,
      );

      expect(dados.leituras.any((e) => e.nivelPercentual >= 80), isTrue);
    },
  );

  // Garante resultados independentes e datas relativas à referência.
  test('fábrica usa datas relativas e é determinística e independente', () {
    final repeticao = DadosMockados.criar(referencia: referencia);
    const deslocamento = Duration(days: 400);

    final futuro = DadosMockados.criar(
      referencia: referencia.add(deslocamento),
    );

    expect(identical(dados.leituras, repeticao.leituras), isFalse);

    for (var i = 0; i < dados.leituras.length; i++) {
      expect(
        dados.leituras[i].registradoEm,
        repeticao.leituras[i].registradoEm,
      );

      expect(
        dados.leituras[i].nivelPercentual,
        repeticao.leituras[i].nivelPercentual,
      );

      expect(
        futuro.leituras[i].registradoEm.difference(
          dados.leituras[i].registradoEm,
        ),
        deslocamento,
      );
    }

    expect(
      futuro.usuarios.first.criadoEm.difference(dados.usuarios.first.criadoEm),
      deslocamento,
    );

    expect(
      futuro.pontosColeta.first.criadoEm.difference(
        dados.pontosColeta.first.criadoEm,
      ),
      deslocamento,
    );

    expect(
      futuro.ocorrencias.first.criadoEm.difference(
        dados.ocorrencias.first.criadoEm,
      ),
      deslocamento,
    );

    expect(
      futuro.ocorrencias.first.atualizadoEm.difference(
        dados.ocorrencias.first.atualizadoEm,
      ),
      deslocamento,
    );
  });

  // Impede alterações diretas nas coleções de dados simulados.
  test('coleções dos mocks não permitem alteração acidental', () {
    expect(() => dados.usuarios.clear(), throwsUnsupportedError);
    expect(() => dados.pontosColeta.clear(), throwsUnsupportedError);
    expect(() => dados.leituras.clear(), throwsUnsupportedError);
    expect(() => dados.ocorrencias.clear(), throwsUnsupportedError);
  });
}
