
import 'enums.dart';

// Representa os dados de um usuário do sistema.
class Usuario {
  // Inicializa o usuário com seus atributos.
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.senhaHash,
    required this.papel,
    required this.criadoEm,
  });

  final int id;
  final String nome;
  final String email;
  final String senhaHash;
  final PapelUsuario papel;
  final DateTime criadoEm;
}
