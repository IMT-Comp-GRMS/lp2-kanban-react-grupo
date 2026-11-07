/// Classe base de todas as falhas previsíveis da aplicação.
///
/// O serviço lança estas exceções sem saber que existe HTTP do outro lado.
/// Só o middleware de erros (web/middlewares.dart) as traduz em códigos de
/// status. Por ser `sealed`, o compilador exige que todos os tipos sejam
/// tratados no switch desse middleware.
sealed class ErroApp implements Exception {
  const ErroApp(this.mensagem);
  final String mensagem;

  @override
  String toString() => '$runtimeType: $mensagem';
}

/// A requisição foi entendida, mas viola uma regra de negócio. Vira 422.
/// O mapa [campos] associa cada campo inválido à sua explicação.
class ErroValidacao extends ErroApp {
  const ErroValidacao(super.mensagem, [this.campos = const {}]);
  final Map<String, String> campos;
}

/// O corpo enviado não pôde ser interpretado. Vira 400.
class RequisicaoInvalida extends ErroApp {
  const RequisicaoInvalida(super.mensagem);
}

/// O recurso pedido não existe (ex.: produto com id inexistente). Vira 404.
class NaoEncontrado extends ErroApp {
  const NaoEncontrado(super.mensagem);
}
