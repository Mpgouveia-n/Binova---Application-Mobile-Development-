import '../api_client.dart';
// Consulta os pontos de coleta e suas situações na API Java Spring Boot.
// Os endpoints de leitura são públicos, conforme SegurancaConfig.java.
class PontoColetaApiService {
  final ApiClient _apiClient;

  PontoColetaApiService(this._apiClient);

  // Lista pontos em uma página, com filtros e ordenação opcionais.
  // O Spring Data devolve um objeto Page com a propriedade content.
  Future<Map<String, dynamic>> listar({
    String? termo,
    bool? ativo = true,
    int pagina = 0,
    int tamanho = 10,
    String ordenacao = 'id,asc',
  }) async {
    final parametros = <String, String>{
      'page': '$pagina',
      'size': '$tamanho',
      'sort': ordenacao,
      if (termo != null && termo.trim().isNotEmpty) 'termo': termo.trim(),
      if (ativo != null) 'ativo': '$ativo',
    };
    final uri = Uri(path: '/api/pontos-coleta', queryParameters: parametros);
    return _pagina(await _apiClient.get(uri.toString()));
  }

  // Pesquisa pontos pelo nome utilizando a rota de busca do Java.
  Future<Map<String, dynamic>> buscarPorNome(
    String nome, {
    int pagina = 0,
    int tamanho = 10,
  }) async {
    final uri = Uri(
      path: '/api/pontos-coleta/busca-nome',
      queryParameters: {
        'nome': nome.trim(),
        'page': '$pagina',
        'size': '$tamanho',
      },
    );
    return _pagina(await _apiClient.get(uri.toString()));
  }

  // Consulta um ponto específico. O retorno inclui links HATEOAS.
  Future<Map<String, dynamic>> consultar(int id) async {
    return _objeto(await _apiClient.get('/api/pontos-coleta/$id'));
  }

  // Consulta a situação atual calculada pela API Java.
  // Campos: pontoColetaId, situacao, nivelPercentual, ultimaLeitura e limiteMinutos.
  Future<Map<String, dynamic>> consultarSituacao(int id) async {
    return _objeto(await _apiClient.get('/api/pontos-coleta/$id/situacao'));
  }

  // Confere se a resposta tem o formato de página do Spring Data.
  Map<String, dynamic> _pagina(dynamic resposta) {
    final pagina = _objeto(resposta);
    if (pagina['content'] is! List) {
      throw const FormatException('A API não retornou uma página de pontos válida.');
    }
    return pagina;
  }

  // Confere se a resposta JSON contém um objeto.
  Map<String, dynamic> _objeto(dynamic resposta) {
    if (resposta is Map<String, dynamic>) return resposta;
    throw const FormatException('A API retornou dados em formato inesperado.');
  }
}
