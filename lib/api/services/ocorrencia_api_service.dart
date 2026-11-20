import '../api_client.dart';

// Gerencia ocorrências pela API Java Spring Boot.
// O Java identifica o cidadão autenticado pelo token JWT.
class OcorrenciaApiService {
  final ApiClient _apiClient;

  OcorrenciaApiService(this._apiClient);

  // Lista ocorrências visíveis ao usuário autenticado.
  // Para um cidadão, o Java restringe os resultados às suas ocorrências.
  Future<Map<String, dynamic>> listar({
    String? status,
    int pagina = 0,
    int tamanho = 10,
  }) async {
    final uri = Uri(
      path: '/api/ocorrencias',
      queryParameters: {
        'page': '$pagina',
        'size': '$tamanho',
        'sort': 'id,desc',
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
    final resposta = _objeto(await _apiClient.get(uri.toString()));
    if (resposta['content'] is! List) {
      throw const FormatException('A API não retornou uma página de ocorrências válida.');
    }
    return resposta;
  }

  // Consulta uma ocorrência pelo identificador.
  Future<Map<String, dynamic>> consultar(int id) async {
    return _objeto(await _apiClient.get('/api/ocorrencias/$id'));
  }

  // Registra uma ocorrência vinculada ao cidadão autenticado.
  // O DTO Java aceita apenas pontoColetaId, tipo e descricao.
  Future<Map<String, dynamic>> registrar({
    required int pontoColetaId,
    required String tipo,
    required String descricao,
  }) async {
    if (pontoColetaId <= 0) {
      throw ArgumentError('Selecione um ponto de coleta válido.');
    }

    const tiposPermitidos = {
      'LIXEIRA_CHEIA',
      'DESCARTE_IRREGULAR',
      'ESTRUTURA_DANIFICADA',
      'OUTRO',
    };
    if (!tiposPermitidos.contains(tipo)) {
      throw ArgumentError('Tipo de ocorrência inválido.');
    }
    if (descricao.trim().isEmpty || descricao.trim().length > 1000) {
      throw ArgumentError('A descrição deve ter entre 1 e 1000 caracteres.');
    }

    return _objeto(await _apiClient.post('/api/ocorrencias', {
      'pontoColetaId': pontoColetaId,
      'tipo': tipo,
      'descricao': descricao.trim(),
    }));
  }

  // Atualiza o tipo e a descrição de uma ocorrência, se o Java permitir.
  Future<Map<String, dynamic>> atualizar({
    required int id,
    required String tipo,
    required String descricao,
  }) async {
    return _objeto(await _apiClient.put('/api/ocorrencias/$id', {
      'tipo': tipo,
      'descricao': descricao.trim(),
    }));
  }

  // Exclui uma ocorrência conforme as permissões da API Java.
  Future<void> excluir(int id) async {
    await _apiClient.delete('/api/ocorrencias/$id');
  }

  // Confere se a resposta contém um objeto JSON.
  Map<String, dynamic> _objeto(dynamic resposta) {
    if (resposta is Map<String, dynamic>) return resposta;
    throw const FormatException('A API retornou dados em formato inesperado.');
  }
}
