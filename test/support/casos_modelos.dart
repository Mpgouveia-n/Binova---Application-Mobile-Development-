import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/leitura_sensor.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
import 'package:binova_mobile/models/usuario.dart';

// Casos independentes do executor, reutilizados pelo package:test e pelo
// verificador temporário quando as dependências não estão disponíveis.
Map<String, void Function()> casosModelos() {
  final data = DateTime.utc(2026, 11, 18, 12);
  final atualizacao = data.add(const Duration(hours: 1));

  PontoColeta ponto({double capacidade = 120, bool ativo = true}) =>
      PontoColeta(
        id: 10,
        nome: 'Ponto A',
        descricaoLocalizacao: 'Entrada principal',
        capacidadeLitros: capacidade,
        ativo: ativo,
        criadoEm: data,
      );

  LeituraSensor leitura({double distancia = 25, double nivel = 75}) =>
      LeituraSensor(
        id: 20,
        pontoColetaId: 10,
        distanciaCm: distancia,
        nivelPercentual: nivel,
        registradoEm: data,
      );

  Ocorrencia ocorrencia({DateTime? atualizada}) => Ocorrencia(
    id: 30,
    pontoColetaId: 10,
    usuarioId: 1,
    tipo: TipoOcorrencia.lixeiraCheia,
    descricao: 'Recipiente cheio',
    status: StatusOcorrencia.aberta,
    criadoEm: data,
    atualizadoEm: atualizada ?? atualizacao,
  );

  return {
    'Usuario preserva todos os atributos': () {
      final usuario = Usuario(
        id: 1,
        nome: 'Ana',
        email: 'ana@example.com',
        senhaHash: 'hash-ficticio-nao-criptografico',
        papel: PapelUsuario.cidadao,
        criadoEm: data,
      );
      igual(usuario.id, 1);
      igual(usuario.nome, 'Ana');
      igual(usuario.email, 'ana@example.com');
      igual(usuario.senhaHash, 'hash-ficticio-nao-criptografico');
      igual(usuario.papel, PapelUsuario.cidadao);
      igual(usuario.criadoEm, data);
    },
    'PontoColeta preserva todos os atributos e permite inativo': () {
      final entidade = ponto(ativo: false);
      igual(entidade.id, 10);
      igual(entidade.nome, 'Ponto A');
      igual(entidade.descricaoLocalizacao, 'Entrada principal');
      igual(entidade.capacidadeLitros, 120.0);
      igual(entidade.ativo, false);
      igual(entidade.criadoEm, data);
    },
    'LeituraSensor preserva atributos e referencia ponto por ID': () {
      final entidade = leitura();
      igual(entidade.id, 20);
      igual(entidade.pontoColetaId, ponto().id);
      igual(entidade.distanciaCm, 25.0);
      igual(entidade.nivelPercentual, 75.0);
      igual(entidade.registradoEm, data);
    },
    'Ocorrencia preserva atributos e referencias por IDs': () {
      final entidade = ocorrencia();
      igual(entidade.id, 30);
      igual(entidade.pontoColetaId, ponto().id);
      igual(entidade.usuarioId, 1);
      igual(entidade.tipo, TipoOcorrencia.lixeiraCheia);
      igual(entidade.descricao, 'Recipiente cheio');
      igual(entidade.status, StatusOcorrencia.aberta);
      igual(entidade.criadoEm, data);
      igual(entidade.atualizadoEm, atualizacao);
    },
    'PapelUsuario mapeia exatamente os valores do contrato': () {
      igual(
        PapelUsuario.values.map((e) => e.valorContrato).join(','),
        'CIDADAO,ADMIN',
      );
    },
    'TipoOcorrencia mapeia exatamente os valores do contrato': () {
      igual(
        TipoOcorrencia.values.map((e) => e.valorContrato).join(','),
        'LIXEIRA_CHEIA,DESCARTE_IRREGULAR,ESTRUTURA_DANIFICADA,OUTRO',
      );
    },
    'StatusOcorrencia mapeia exatamente os valores do contrato': () {
      igual(
        StatusOcorrencia.values.map((e) => e.valorContrato).join(','),
        'ABERTA,EM_ATENDIMENTO,RESOLVIDA',
      );
    },
    'Capacidade aceita valor positivo fracionario': () {
      igual(ponto(capacidade: 0.5).capacidadeLitros, 0.5);
    },
    'Leitura aceita os limites 0 e 100 e distancia zero': () {
      igual(leitura(nivel: 0, distancia: 0).nivelPercentual, 0.0);
      igual(leitura(nivel: 100).nivelPercentual, 100.0);
    },
    'Ocorrencia aceita atualizacao igual a criacao': () {
      igual(ocorrencia(atualizada: data).atualizadoEm, data);
    },
    'Ocorrencia rejeita atualizacao anterior a criacao': () {
      rejeitaArgumento(
        () => ocorrencia(atualizada: data.subtract(const Duration(seconds: 1))),
        'atualizadoEm',
      );
    },
    for (final valor in [
      0.0,
      -1.0,
      double.nan,
      double.infinity,
      -double.infinity,
    ])
      'Capacidade rejeita $valor': () {
        rejeitaArgumento(() => ponto(capacidade: valor), 'capacidadeLitros');
      },
    for (final valor in [
      -1.0,
      100.1,
      double.nan,
      double.infinity,
      -double.infinity,
    ])
      'Percentual rejeita $valor': () {
        rejeitaArgumento(() => leitura(nivel: valor), 'nivelPercentual');
      },
    for (final valor in [-0.1, double.nan, double.infinity, -double.infinity])
      'Distancia rejeita $valor': () {
        rejeitaArgumento(() => leitura(distancia: valor), 'distanciaCm');
      },
  };
}

void igual(Object? recebido, Object? esperado) {
  if (recebido != esperado) {
    throw StateError('Esperado: $esperado; recebido: $recebido');
  }
}

void rejeitaArgumento(void Function() acao, String campo) {
  try {
    acao();
  } on ArgumentError catch (erro) {
    igual(erro.name, campo);
    return;
  }
  throw StateError('Era esperado ArgumentError para $campo.');
}
