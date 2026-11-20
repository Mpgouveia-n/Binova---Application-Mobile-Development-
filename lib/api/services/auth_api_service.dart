
import '../api_client.dart';

// Gerencia a autenticação do Binova Mobile pela API Java.
// Permite cadastrar cidadãos, realizar login, consultar o perfil
// autenticado e encerrar a sessão.
class AuthApiService {
  final ApiClient _apiClient;

  // Recebe o cliente HTTP compartilhado com os demais serviços.
  AuthApiService(this._apiClient);

  // Armazena as informações do usuário autenticado durante a sessão.
  int? _usuarioId;
  String? _papel;

  // Informa se existe um usuário autenticado.
  bool get autenticado => _apiClient.autenticado;

  // Retorna o ID do usuário autenticado.
  int? get usuarioId => _usuarioId;

  // Retorna o papel do usuário autenticado.
  String? get papel => _papel;

  // Realiza o login utilizando email e senha.
  // A API retorna um JWT, que será utilizado nas próximas requisições.
  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final resposta = await _apiClient.post(
      '/api/auth/login',
      {
        'email': email.trim(),
        'senha': senha,
      },
    );

    if (resposta is! Map<String, dynamic>) {
      throw FormatException('Resposta de login inválida.');
    }

    final token = resposta['token'];

    if (token is! String || token.isEmpty) {
      throw FormatException('A API não retornou um token JWT válido.');
    }

    final id = resposta['usuarioId'];

    if (id is! int) {
      throw FormatException('A API não retornou um ID de usuário válido.');
    }

    _apiClient.definirToken(token);
    _usuarioId = id;
    _papel = resposta['papel']?.toString();

    return resposta;
  }

  // Cadastra um novo cidadão na API Java.
  // A senha precisa ter entre 8 e 72 caracteres.
  // O cadastro não realiza login automaticamente.
  Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    if (nome.trim().isEmpty) {
      throw ArgumentError('Informe o nome do cidadão.');
    }

    if (senha.length < 8 || senha.length > 72) {
      throw ArgumentError(
        'A senha deve conter entre 8 e 72 caracteres.',
      );
    }

    final resposta = await _apiClient.post(
      '/api/auth/cadastro',
      {
        'nome': nome.trim(),
        'email': email.trim(),
        'senha': senha,
      },
    );

    if (resposta is! Map<String, dynamic>) {
      throw FormatException('Resposta de cadastro inválida.');
    }

    return resposta;
  }

  // Consulta os dados do cidadão autenticado.
  // O ApiClient envia automaticamente o token JWT armazenado.
  Future<Map<String, dynamic>> consultarPerfil() async {
    if (!autenticado) {
      throw StateError('É necessário realizar o login.');
    }

    final resposta = await _apiClient.get('/api/usuarios/me');

    if (resposta is! Map<String, dynamic>) {
      throw FormatException('Resposta do perfil inválida.');
    }

    return resposta;
  }

  // Encerra a sessão local, removendo o token e os dados do usuário.
  // Não exclui o cadastro nem altera informações no servidor.
  void logout() {
    _apiClient.limparToken();
    _usuarioId = null;
    _papel = null;
  }
}
