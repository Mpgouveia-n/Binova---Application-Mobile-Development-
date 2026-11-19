import 'package:test/test.dart';
import 'support/casos_modelos.dart';

void main() {
  // Executa todos os casos de teste definidos para os modelos.
  for (final caso in casosModelos().entries) {
    test(caso.key, caso.value);
  }
}
