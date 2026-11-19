import 'package:test/test.dart';

import 'support/casos_modelos.dart';

void main() {
  for (final caso in casosModelos().entries) {
    test(caso.key, caso.value);
  }
}
