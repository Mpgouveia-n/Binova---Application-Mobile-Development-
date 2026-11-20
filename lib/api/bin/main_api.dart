
import 'package:binova_mobile/api/api_client.dart';
import 'package:binova_mobile/api/services/auth_api_service.dart';
import 'package:binova_mobile/api/services/ponto_coleta_api_service.dart';
import 'package:binova_mobile/api/services/ocorrencia_api_service.dart';
import 'package:binova_mobile/api/console/binova_console_api.dart';

// Inicializa a versão do Binova Mobile conectada à API Java.
// Mantém a aplicação integrada separada da versão original em Dart Console.
Future<void> main() async {
  // Cria o cliente HTTP compartilhado por todos os serviços.
  final apiClient = ApiClient();

  // Inicializa os serviços responsáveis pelas requisições ao Java.
  final authService = AuthApiService(apiClient);
  final pontoColetaService = PontoColetaApiService(apiClient);
  final ocorrenciaService = OcorrenciaApiService(apiClient);

  try {
    // Inicializa o console integrado à API Spring Boot.
    final console = BinovaApiConsole(
      authService: authService,
      pontoColetaService: pontoColetaService,
      ocorrenciaService: ocorrenciaService,
    );

    await console.iniciar();
  } finally {
    // Encerra as conexões HTTP quando a aplicação termina.
    apiClient.fechar();
  }
}
