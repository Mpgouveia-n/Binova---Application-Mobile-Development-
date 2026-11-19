
import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
import 'package:binova_mobile/models/usuario.dart';

// Representa os erros de validação ao registrar ocorrências.
class ValidacaoOcorrenciaException implements Exception {
  // Inicializa a exceção com a mensagem informada.
  const ValidacaoOcorrenciaException(this.mensagem);

  final String mensagem;

  // Retorna a mensagem de erro.
  @override
  String toString() => mensagem;
}

// Responsável por consultar, validar e registrar ocorrências.
class OcorrenciaService {
  // Inicializa os dados da sessão sem modificar as listas originais.
  OcorrenciaService({
    required Iterable<Usuario> usuarios,
    required Iterable<PontoColeta> pontosColeta,
    required Iterable<Ocorrencia> ocorrencias,
  }) : _usuarios = List.unmodifiable(usuarios),
       _pontos = List.unmodifiable(pontosColeta),
       _ocorrencias = List.of(ocorrencias);

  final List<Usuario> _usuarios;
  final List<PontoColeta> _pontos;
  final List<Ocorrencia> _ocorrencias;

  // Retorna somente os usuários com perfil de cidadão.
  List<Usuario> listarCidadaos() {
    return List.unmodifiable(
      _usuarios.where(
        (usuario) => usuario.papel == PapelUsuario.cidadao,
      ),
    );
  }

  // Valida se o usuário existe e possui perfil de cidadão.
  Usuario validarCidadao(int usuarioId) {
    for (final usuario in _usuarios) {
      if (usuario.id == usuarioId) {
        if (usuario.papel != PapelUsuario.cidadao) {
          throw const ValidacaoOcorrenciaException(
            'Selecione um cidadão. Administradores não participam deste fluxo.',
          );
        }

        return usuario;
      }
    }

    throw const ValidacaoOcorrenciaException(
      'Cidadão não encontrado.',
    );
  }

  // Verifica se o ponto de coleta existe e está ativo.
  PontoColeta validarPontoAtivo(int pontoId) {
    for (final ponto in _pontos) {
      if (ponto.id == pontoId) {
        if (!ponto.ativo) {
          throw const ValidacaoOcorrenciaException(
            'O ponto de coleta está inativo.',
          );
        }

        return ponto;
      }
    }

    throw const ValidacaoOcorrenciaException(
      'Ponto de coleta não encontrado.',
    );
  }

  // Retorna todas as ocorrências registradas na sessão.
  List<Ocorrencia> listar() {
    return List.unmodifiable(_ocorrencias);
  }

  // Consulta as ocorrências pertencentes a um cidadão.
  List<Ocorrencia> listarPorCidadao(int usuarioId) {
    validarCidadao(usuarioId);

    return List.unmodifiable(
      _ocorrencias.where(
        (item) => item.usuarioId == usuarioId,
      ),
    );
  }

  // Busca uma ocorrência pelo seu identificador.
  Ocorrencia? buscarPorId(int id) {
    for (final ocorrencia in _ocorrencias) {
      if (ocorrencia.id == id) {
        return ocorrencia;
      }
    }

    return null;
  }

  // Valida os dados e registra uma nova ocorrência.
  Ocorrencia registrar({
    required int usuarioId,
    required int pontoColetaId,
    required TipoOcorrencia tipo,
    required String descricao,
    required DateTime referencia,
  }) {
    validarCidadao(usuarioId);
    validarPontoAtivo(pontoColetaId);

    final texto = descricao.trim();

    if (texto.isEmpty) {
      throw const ValidacaoOcorrenciaException(
        'A descrição não pode ficar vazia.',
      );
    }

    // Identifica o maior ID para gerar o próximo registro.
    int maiorId = 0;

    for (final item in _ocorrencias) {
      if (item.id > maiorId) {
        maiorId = item.id;
      }
    }

    // Cria a ocorrência com o status inicial aberto.
    final nova = Ocorrencia(
      id: maiorId + 1,
      pontoColetaId: pontoColetaId,
      usuarioId: usuarioId,
      tipo: tipo,
      descricao: texto,
      status: StatusOcorrencia.aberta,
      criadoEm: referencia,
      atualizadoEm: referencia,
    );

    // Adiciona o registro à sessão atual.
    _ocorrencias.add(nova);

    return nova;
  }
}
