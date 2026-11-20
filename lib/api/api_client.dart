
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_config.dart';

// Centraliza as requisições HTTP entre o Binova Mobile e a API Java.
// Gerencia o token JWT, os métodos HTTP e o tratamento de erros.
class ApiClient {
  final HttpClient _httpClient = HttpClient();

  static const Duration _timeout = Duration(seconds: 10);

  String? _token;

  // Informa se existe um token JWT armazenado na sessão.
  bool get autenticado => _token != null && _token!.isNotEmpty;

  // Armazena o token JWT recebido após o login.
  void definirToken(String token) {
    _token = token;
  }

  // Remove o token JWT ao encerrar a sessão do usuário.
  void limparToken() {
    _token = null;
  }

  // Consulta informações da API utilizando o método GET.
  Future<dynamic> get(String endpoint, {String? token}) {
    return _enviar(
      'GET',
      endpoint,
      token: token,
    );
  }

  // Envia informações para a API utilizando o método POST.
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> dados, {
    String? token,
  }) {
    return _enviar(
      'POST',
      endpoint,
      dados: dados,
      token: token,
    );
  }

  // Atualiza integralmente um recurso utilizando PUT.
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> dados, {
    String? token,
  }) {
    return _enviar(
      'PUT',
      endpoint,
      dados: dados,
      token: token,
    );
  }

  // Atualiza parcialmente um recurso utilizando PATCH.
  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> dados, {
    String? token,
  }) {
    return _enviar(
      'PATCH',
      endpoint,
      dados: dados,
      token: token,
    );
  }

  // Exclui um recurso utilizando DELETE.
  Future<dynamic> delete(String endpoint, {String? token}) {
    return _enviar(
      'DELETE',
      endpoint,
      token: token,
    );
  }

  // Executa as requisições, envia JSON e interpreta a resposta da API.
  Future<dynamic> _enviar(
    String metodo,
    String endpoint, {
    Map<String, dynamic>? dados,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final request = await _httpClient
          .openUrl(metodo, uri)
          .timeout(_timeout);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );

      // Envia o token JWT quando a requisição exige autenticação.
      final tokenAtual = token ?? _token;

      if (tokenAtual != null && tokenAtual.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $tokenAtual',
        );
      }

      // Converte os dados informados para JSON.
      if (dados != null) {
        request.add(utf8.encode(jsonEncode(dados)));
      }

      final response = await request.close().timeout(_timeout);

      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_timeout);

      // Trata as respostas HTTP que indicam falha.
      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw HttpException(
          'Erro HTTP ${response.statusCode}: $body',
          uri: uri,
        );
      }

      // Alguns endpoints retornam sucesso sem conteúdo.
      if (body.trim().isEmpty) {
        return null;
      }

      return jsonDecode(body);
    } on SocketException {
      throw Exception(
        'Não foi possível conectar à API Java. '
        'Verifique se o Spring Boot está em execução '
        'em ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw Exception(
        'A API Java demorou muito para responder.',
      );
    } on FormatException {
      throw Exception(
        'A API retornou um JSON inválido.',
      );
    } on HttpException {
      rethrow;
    }
  }

  // Encerra o cliente HTTP e libera suas conexões.
  void fechar() {
    _httpClient.close();
  }
}
