import 'package:binova_mobile/models/enums.dart';
import 'package:binova_mobile/models/ocorrencia.dart';
import 'package:binova_mobile/models/ponto_coleta.dart';
import 'package:binova_mobile/models/usuario.dart';

class ValidacaoOcorrenciaException implements Exception {
  const ValidacaoOcorrenciaException(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

// Mantém os registros isolados na sessão, incluindo novos cadastros.
class OcorrenciaService {
  OcorrenciaService({
    required Iterable<Usuario> usuarios,
    required Iterable<PontoColeta> pontosColeta,
    required Iterable<Ocorrencia> ocorrencias,
  }) : _usuarios = List.of(usuarios),
       _pontos = List.unmodifiable(pontosColeta),
       _ocorrencias = List.of(ocorrencias);

  final List<Usuario> _usuarios;
  final List<PontoColeta> _pontos;
  final List<Ocorrencia> _ocorrencias;

  // Pesquisa cidadãos por ID, nome ou e-mail (sem diferenciar maiúsculas).
  List<Usuario> pesquisarCidadaos(String termo) {
    final busca = termo.trim().toLowerCase();
    if (busca.isEmpty) return List.unmodifiable(<Usuario>[]);
    return List.unmodifiable(
      listarCidadaos().where((usuario) =>
          usuario.id.toString() == busca ||
          usuario.nome.toLowerCase().contains(busca) ||
          usuario.email.toLowerCase().contains(busca)),
    );
  }

  // Cadastra um cidadão fictício apenas na sessão atual.
  Usuario cadastrarCidadao({
    required String nome,
    required String email,
    required DateTime referencia,
  }) {
    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();
    if (nomeLimpo.length < 3) {
      throw const ValidacaoOcorrenciaException(
        'Informe um nome com pelo menos 3 caracteres.',
      );
    }
    final emailValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailValido.hasMatch(emailLimpo)) {
      throw const ValidacaoOcorrenciaException('Informe um e-mail válido.');
    }
    if (_usuarios.any((usuario) => usuario.email.toLowerCase() == emailLimpo)) {
      throw const ValidacaoOcorrenciaException('Este e-mail já está cadastrado.');
    }
    var maiorId = 0;
    for (final usuario in _usuarios) {
      if (usuario.id > maiorId) maiorId = usuario.id;
    }
    final novo = Usuario(
      id: maiorId + 1,
      nome: nomeLimpo,
      email: emailLimpo,
      senhaHash: 'cadastro-simulado-${maiorId + 1}',
      papel: PapelUsuario.cidadao,
      criadoEm: referencia,
    );
    _usuarios.add(novo);
    return novo;
  }

  List<Usuario> listarCidadaos() => List.unmodifiable(
    _usuarios.where((Usuario usuario) => usuario.papel == PapelUsuario.cidadao),
  );

  Usuario validarCidadao(int usuarioId) {
    for (final Usuario usuario in _usuarios) {
      if (usuario.id == usuarioId) {
        if (usuario.papel != PapelUsuario.cidadao) {
          throw const ValidacaoOcorrenciaException(
            'Selecione um cidadão. Administradores não participam deste fluxo.',
          );
        }
        return usuario;
      }
    }
    throw const ValidacaoOcorrenciaException('Cidadão não encontrado.');
  }

  PontoColeta validarPontoAtivo(int pontoId) {
    for (final PontoColeta ponto in _pontos) {
      if (ponto.id == pontoId) {
        if (!ponto.ativo) {
          throw const ValidacaoOcorrenciaException(
            'O ponto de coleta está inativo.',
          );
        }
        return ponto;
      }
    }
    throw const ValidacaoOcorrenciaException('Ponto de coleta não encontrado.');
  }

  List<Ocorrencia> listar() => List.unmodifiable(_ocorrencias);

  List<Ocorrencia> listarPorCidadao(int usuarioId) {
    validarCidadao(usuarioId);
    return List.unmodifiable(
      _ocorrencias.where((Ocorrencia item) => item.usuarioId == usuarioId),
    );
  }

  Ocorrencia? buscarPorId(int id) {
    for (final Ocorrencia ocorrencia in _ocorrencias) {
      if (ocorrencia.id == id) return ocorrencia;
    }
    return null;
  }

  Ocorrencia registrar({
    required int usuarioId,
    required int pontoColetaId,
    required TipoOcorrencia tipo,
    required String descricao,
    required DateTime referencia,
  }) {
    validarCidadao(usuarioId);
    validarPontoAtivo(pontoColetaId);
    final String texto = descricao.trim();
    if (texto.isEmpty) {
      throw const ValidacaoOcorrenciaException(
        'A descrição não pode ficar vazia.',
      );
    }
    int maiorId = 0;
    for (final Ocorrencia item in _ocorrencias) {
      if (item.id > maiorId) maiorId = item.id;
    }
    final Ocorrencia nova = Ocorrencia(
      id: maiorId + 1,
      pontoColetaId: pontoColetaId,
      usuarioId: usuarioId,
      tipo: tipo,
      descricao: texto,
      status: StatusOcorrencia.aberta,
      criadoEm: referencia,
      atualizadoEm: referencia,
    );
    _ocorrencias.add(nova);
    return nova;
  }
}
