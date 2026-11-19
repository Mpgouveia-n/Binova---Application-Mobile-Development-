
import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/leitura_sensor.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
import 'package:binova_mobile/models/usuario.dart';

// Armazena os dados fictícios utilizados na simulação do Binova.
class DadosMockados {
  // Inicializa as coleções sem permitir alterações externas.
  DadosMockados._({
    required List<Usuario> usuarios,
    required List<PontoColeta> pontosColeta,
    required List<LeituraSensor> leituras,
    required List<Ocorrencia> ocorrencias,
  }) : usuarios = List.unmodifiable(usuarios),
       pontosColeta = List.unmodifiable(pontosColeta),
       leituras = List.unmodifiable(leituras),
       ocorrencias = List.unmodifiable(ocorrencias);

  // Cria uma base independente com dados simulados.
  factory DadosMockados.criar({required DateTime referencia}) {
    final criacao = referencia.subtract(const Duration(days: 30));

    // Cria quatro cidadãos e um administrador.
    final List<Usuario> usuarios = [
      for (final (indice, nome) in [
        'Ana Lima',
        'Bruno Reis',
        'Clara Souza',
        'Diego Alves',
        'Elisa Rocha',
      ].indexed)
        Usuario(
          id: indice + 1,
          nome: nome,
          email: 'usuario${indice + 1}@example.com',
          senhaHash: 'hash-simulado-${indice + 1}',
          papel: indice == 4 ? PapelUsuario.admin : PapelUsuario.cidadao,
          criadoEm: criacao,
        ),
    ];

    // Define os locais fictícios dos pontos de coleta.
    final List<(String, String)> locais = [
      ('Praça das Acácias', 'Ao lado do coreto da praça fictícia'),
      ('Parque do Ipê', 'Entrada leste, junto à ciclovia'),
      ('Mercado Vila Aurora', 'Área externa próxima ao bicicletário'),
      ('Escola Horizonte', 'Calçada da entrada principal'),
      ('Centro Cultural Girassol', 'Pátio lateral junto ao jardim'),
      ('Terminal Nova Esperança', 'Passarela de acesso à plataforma A'),
      ('Ginásio das Palmeiras', 'Estacionamento, próximo ao portão B'),
      ('Biblioteca Sabiá', 'Área externa em manutenção'),
    ];

    // Cria oito pontos de coleta, sendo um inativo.
    final List<PontoColeta> pontos = [
      for (final (indice, (nome, local)) in locais.indexed)
        PontoColeta(
          id: indice + 1,
          nome: nome,
          descricaoLocalizacao: local,
          capacidadeLitros: indice.isEven ? 120.0 : 240.0,
          ativo: indice != 7,
          criadoEm: criacao,
        ),
    ];

    // Cria uma leitura simulada para um ponto de coleta.
    LeituraSensor leitura(int id, int pontoId, double nivel, int minutos) {
      return LeituraSensor(
        id: id,
        pontoColetaId: pontoId,
        distanciaCm: 100 - nivel,
        nivelPercentual: nivel,
        registradoEm: referencia.subtract(Duration(minutes: minutos)),
      );
    }

    // Simula níveis, históricos antigos e pontos sem leituras.
    final List<LeituraSensor> leituras = [
      leitura(1, 1, 25, 3),
      leitura(2, 2, 65, 5),
      leitura(3, 3, 92, 1),
      leitura(4, 4, 100, 15),
      leitura(5, 5, 40, 45),
      // O ponto 6 não possui leitura registrada.
      leitura(6, 7, 85, 2),
      leitura(7, 7, 20, 20),
      leitura(8, 8, 10, 4),
    ];

    // Cria cinco ocorrências com tipos e estados diferentes.
    final List<Ocorrencia> ocorrencias = [
      for (final (indice, descricao) in [
        'Recipiente cheio próximo ao mercado.',
        'Resíduos descartados fora do recipiente da escola.',
        'Tampa danificada no centro cultural.',
        'Solicitação de identificação no terminal.',
        'Recipiente do ginásio próximo da capacidade máxima.',
      ].indexed)
        Ocorrencia(
          id: indice + 1,
          pontoColetaId: indice + 3,
          usuarioId: (indice % 4) + 1,
          tipo: TipoOcorrencia.values[indice % TipoOcorrencia.values.length],
          descricao: descricao,
          status:
              StatusOcorrencia.values[indice % StatusOcorrencia.values.length],
          criadoEm: referencia.subtract(Duration(hours: indice + 2)),
          atualizadoEm: referencia.subtract(const Duration(hours: 1)),
        ),
    ];

    // Retorna os dados utilizados na simulação.
    return DadosMockados._(
      usuarios: usuarios,
      pontosColeta: pontos,
      leituras: leituras,
      ocorrencias: ocorrencias,
    );
  }

  final List<Usuario> usuarios;
  final List<PontoColeta> pontosColeta;
  final List<LeituraSensor> leituras;
  final List<Ocorrencia> ocorrencias;
}
